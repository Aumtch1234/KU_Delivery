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
    required Map<String, double> distances,
    required Map<String, double> deliveryFees,
    required Map<String, double> totalPrices,
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
        'distances': distances, // Now sends object with marketId keys
        'deliveryFees': deliveryFees, // Now sends object with marketId keys
        'totalPrices': totalPrices, // Now sends object with marketId keys
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create order: ${response.body}");
    }
  }
}
