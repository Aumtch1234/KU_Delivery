import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/APIs/middleware/authService.dart'; // เอา token

class OrdersAPI {
  static const String baseUrl = "${ApiConfig.baseUrl}/orders";

  static Future<Map<String, dynamic>> getOrderStatus(int orderId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$orderId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get order status: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> basket,
    required int address_id,
    required String address,
    required String note,
    required String paymentMethod,
    required String deliveryType,
    required Map<String, double>
    distances, // กลับไปใช้ map เพื่อให้ backend อ่านได้
    required Map<String, double> deliveryFees, // กลับไปใช้ map
    required Map<String, double> totalPrices, // กลับไปใช้ map
    // required double rider_required_gp, // 🔥 เปลี่ยนเป็น double สำหรับร้านเดียว
    // required int bonus,
  }) async {
    final token = await AuthService()
        .getToken(); // เอา JWT token ที่ login เก็บไว้

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'basket': basket,
        'address': address,
        'address_id': address_id,
        'note': note,
        'paymentMethod': paymentMethod,
        'deliveryType': deliveryType,
        'distances': distances, // ส่ง map เพื่อให้ backend อ่านได้
        'deliveryFees': deliveryFees, // ส่ง map เพื่อให้ backend อ่านได้
        'totalPrices': totalPrices, // ส่ง map เพื่อให้ backend อ่านได้
        // 'rider_required_gp':
        //     rider_required_gp, // GP สำหรับร้านเดียว (เป็น number)
        // 'bonus': bonus,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create order: ${response.body}");
    }
  }

  // 🔥 เมธอดใหม่: สร้างหลายออเดอร์พร้อมกัน (แยกตามร้าน)
  static Future<Map<String, dynamic>> createMultipleOrders({
    required Map<int, List<Map<String, dynamic>>>
    basketsByMarket, // แยกตาม marketId
    required int address_id,
    required String address,
    required String note,
    required String paymentMethod,
    required String deliveryType,
    required Map<int, double> distancesByMarket,
    required Map<int, double> deliveryFeesByMarket,
    required Map<int, double> totalPricesByMarket,
    // required Map<int, double> riderGpByMarket, // GP แยกตาม marketId
    // required int bonus,
  }) async {
    final List<Map<String, dynamic>> allOrderResults = [];
    final List<String> errors = [];

    // สร้างออเดอร์แยกตามแต่ละร้าน
    for (final marketId in basketsByMarket.keys) {
      try {
        final marketBasket = basketsByMarket[marketId]!;
        final distance = distancesByMarket[marketId] ?? 0.0;
        final deliveryFee = deliveryFeesByMarket[marketId] ?? 0.0;
        final totalPrice = totalPricesByMarket[marketId] ?? 0.0;
        // final riderGp = riderGpByMarket[marketId] ?? 0.0;

        // print("🏪 Creating order for market $marketId with GP: $riderGp");

        final result = await createOrder(
          basket: marketBasket,
          address_id: address_id,
          address: address,
          note: note,
          paymentMethod: paymentMethod,
          deliveryType: deliveryType,
          distances: {
            marketId.toString(): distance,
          }, // ส่ง map ที่มีแค่ร้านเดียว
          deliveryFees: {
            marketId.toString(): deliveryFee,
          }, // ส่ง map ที่มีแค่ร้านเดียว
          totalPrices: {
            marketId.toString(): totalPrice,
          }, // ส่ง map ที่มีแค่ร้านเดียว
          // rider_required_gp: riderGp,
          // bonus: bonus,
        );

        if (result['success'] == true) {
          allOrderResults.add({'market_id': marketId, 'order_data': result});
          print("✅ Order created for market $marketId");
        } else {
          errors.add("Market $marketId: ${result['error'] ?? 'Unknown error'}");
        }
      } catch (e) {
        errors.add("Market $marketId: $e");
        print("❌ Error creating order for market $marketId: $e");
      }
    }

    if (errors.isNotEmpty && allOrderResults.isEmpty) {
      // ทุกออเดอร์ล้มเหลว
      return {
        'success': false,
        'error': 'Failed to create all orders',
        'details': errors,
      };
    } else if (errors.isNotEmpty) {
      // บางออเดอร์สำเร็จ บางล้มเหลว
      return {
        'success': true,
        'partial_success': true,
        'orders': allOrderResults,
        'errors': errors,
        'message': 'Some orders created successfully, some failed',
      };
    } else {
      // ทุกออเดอร์สำเร็จ
      return {
        'success': true,
        'orders': allOrderResults,
        'message': 'All orders created successfully',
      };
    }
  }

  // 🔥 API ใหม่: เช็คว่าร้านไหนเป็นร้านแอดมิน (owner_id = null)
  static Future<Map<String, dynamic>> getMarketsInfo(
    List<int> marketIds,
  ) async {
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/markets/info'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({'market_ids': marketIds}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get markets info: ${response.body}");
    }
  }
}
