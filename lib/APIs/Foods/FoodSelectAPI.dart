import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/pages/store/models/Food_model.dart';
import 'package:http/http.dart' as http;

class FoodService {
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
}
