import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/basket/models/basket_item.dart';
import 'package:delivery/pages/store/models/Food_model.dart';
import 'package:http/http.dart' as http;

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
    // ดึง token ที่เก็บไว้ใน SharedPreferences
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      print("❌ Token not found, user not logged in");
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
      print("✅ Add to cart success: ${response.body}");
      return true;
    } else {
      print("❌ AddToCart Error: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

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
          cartId: item['cart_id'] ?? 0, // ✅ เพิ่ม
          storeName:
              'ร้าน ${item['shop_name'] ?? ''}', // ถ้ามี market_name ใช้อันนั้น
          foodName: item['food_name'] ?? 'ไม่ระบุ',
          imagePath: item['image_url'] ?? '',
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
      print("❌ Token not found");
      return false;
    }

    print("➡️ Deleting cartId: $cartId with token: $token");

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cart/$cartId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Delete response: ${response.statusCode} ${response.body}");

    return response.statusCode == 200;
  }
}
