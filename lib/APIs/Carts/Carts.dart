import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/basket/models/basket_item.dart';
import 'package:delivery/pages/store/models/Food_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class CartAPI {
  // 🍔 ดึงเมนูอาหารตาม market
  static Future<List<Food>> fetchFoods(int marketId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/foods/$marketId"),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((item) => Food.fromJson(item)).toList();
    } else {
      throw Exception("Failed to fetch foods: ${response.body}");
    }
  }

  // 🛒 เพิ่มอาหารลง cart
  static Future<bool> addToCart({
    required int foodId,
    required int quantity,
    required List<Map<String, dynamic>> selectedOptions,
    String? note,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      debugPrint("❌ Token not found, user not logged in");
      return false;
    }

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/cart/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "food_id": foodId,
        "quantity": quantity,
        "selected_options": selectedOptions,
        "note": note ?? "",
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Add to cart success: ${response.body}");
      return true;
    } else {
      debugPrint("❌ AddToCart Error: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // 🛒 ดึงรายการในตะกร้า
  static Future<List<BasketItem>> getCart() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) throw Exception("Token not found");

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];

      return data.map((item) {
        return BasketItem(
          cartId: item['cart_id'] ?? 0,
          storeName: 'ร้าน ${item['shop_name'] ?? ''}',
          foodId: item['food_id'] ?? 'ไม่ระบุ',
          foodName: item['food_name'] ?? 'ไม่ระบุ',
          imagePath: item['image_url'] ?? '',
          marketId: item['market_id'] ?? 0,
          selectedOptions: List<Map<String, dynamic>>.from(
            item['selected_options'] ?? [],
          ),
          note: item['note'] ?? '',
          sell_price: double.tryParse(item['sell_price'].toString()) ?? 0,
          total: double.tryParse(item['total'].toString()) ?? 0,
          quantity: item['quantity'] ?? 1,
          selected: true,
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch cart: ${response.body}');
    }
  }

  // ❌ ลบรายการ cart
  static Future<bool> deleteCartItem(int cartId) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      debugPrint("❌ Token not found");
      return false;
    }

    debugPrint("➡️ Deleting cartId: $cartId");

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cart/$cartId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("⬅️ Delete response: ${response.statusCode} ${response.body}");

    return response.statusCode == 200;
  }

  // ✅ ตรวจสอบสถานะร้านค้าก่อนสั่งซื้อ
  static Future<Map<String, dynamic>> checkStoresStatus(
    List<int> cartIds,
  ) async {
    try {
      final token = await AuthService().getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'กรุณาเข้าสู่ระบบใหม่',
        };
      }

      debugPrint('🔍 Checking stores with cart IDs: $cartIds');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/check-stores-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cart_ids': cartIds,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📦 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'stores': data['stores'],
        };
      } else if (response.statusCode == 400 &&
          data['error_type'] == 'STORE_CLOSED') {
        return {
          'success': false,
          'error_type': 'STORE_CLOSED',
          'message': data['message'],
          'closed_stores': data['closed_stores'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'เกิดข้อผิดพลาด',
        };
      }
    } catch (e) {
      debugPrint('❌ Check Stores Status Error: $e');
      return {
        'success': false,
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์',
      };
    }
  }

  // ✅ แสดง Awesome Dialog สำหรับร้านปิด
  static void showClosedStoresDialog(
    BuildContext context,
    List<dynamic> closedStores,
  ) {
    // สร้างข้อความแสดงร้านที่ปิด
    String storesText = '';
    for (var store in closedStores) {
      storesText += '📍 ${store['market_name']}\n';
      storesText += '   ${store['reason']}\n';
      if (store['opening_time'] != null && store['closing_time'] != null) {
        storesText +=
            '   เวลาทำการ: ${store['opening_time']} - ${store['closing_time']}\n';
      }
      storesText += '\n';
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: '⚠️ ร้านค้าปิดทำการ',
      desc: 'ไม่สามารถสั่งซื้อได้เนื่องจาก:\n\n$storesText',
      btnOkText: 'ตกลง',
      btnOkColor: Colors.orange,
      btnOkOnPress: () {},
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
    ).show();
  }

  // ✅ แสดง Success Dialog
  static void showSuccessDialog(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: '✅ พร้อมสั่งซื้อ',
      desc: message,
      btnOkText: 'ดำเนินการต่อ',
      btnOkColor: const Color(0xFF34C759),
      btnOkOnPress: onConfirm,
      btnCancelText: 'ยกเลิก',
      btnCancelOnPress: () {},
    ).show();
  }

  // ✅ แสดง Error Dialog
  static void showErrorDialog(
    BuildContext context,
    String message,
  ) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: '❌ เกิดข้อผิดพลาด',
      desc: message,
      btnOkText: 'ตกลง',
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();
  }
}