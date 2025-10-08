
import 'dart:convert';

import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;

class ReviewApi {
  static const String baseUrl = "${ApiConfig.reviewURL}";

  static Future<Map<String, dynamic>> getAllReviewMaket(int marketId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/markets/$marketId/reviews'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get market status: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getAllReviewFoods(int foodId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/food/$foodId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get foodId status: ${response.body}");
    }
  }
}