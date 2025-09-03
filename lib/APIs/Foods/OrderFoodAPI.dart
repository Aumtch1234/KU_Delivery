import 'dart:convert';
import 'package:delivery/pages/store/models/food_detail_model.dart';
import 'package:http/http.dart' as http;

class FoodOrderController {
  final String baseUrl =
      "http://10.0.2.2:4000/client"; // 🔧 เปลี่ยนเป็น API ของคุณ

  Future<FoodDetail?> getFoodDetail(int foodId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/foods/order/$foodId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'].isNotEmpty) {
          final first = data['data'][0];

          // ดึง options จาก JSON array
          final optionsJson = first['options'] as List<dynamic>? ?? [];
          final options = optionsJson
              .map(
                (e) => FoodOption(
                  label: e['label'] ?? '',
                  extraPrice: (e['extraPrice'] ?? 0).toDouble(),
                ),
              )
              .toList();

          final food = FoodDetail.fromJson(first);

          return FoodDetail(
            foodId: food.foodId,
            foodName: food.foodName,
            price: food.price,
            imageUrl: food.imageUrl,
            foodRating: food.foodRating,
            marketId: food.marketId,
            shopName: food.shopName,
            shopLogoUrl: food.shopLogoUrl,
            latitude: food.latitude,
            longitude: food.longitude,
            isOpen: food.isOpen,
            marketRating: food.marketRating,
            address: food.address,
            phone: food.phone,
            options: options,
          );
        }
      }

      return null;
    } catch (e) {
      print("❌ Error fetching food detail: $e");
      return null;
    }
  }
}
