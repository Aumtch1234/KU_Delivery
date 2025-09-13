import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/pages/store/models/food_detail_model.dart';
import 'package:http/http.dart' as http;

class FoodOrderController {
  Future<FoodDetail?> getFoodDetail(int foodId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/foods/order/$foodId"),
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
            sell_price: food.sell_price,
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
