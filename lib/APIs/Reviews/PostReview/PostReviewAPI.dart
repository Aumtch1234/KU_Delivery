import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;

class PostReviewApi {
  static const String baseUrl = "${ApiConfig.reviewURL}";

  /// ส่งรีวิวทั้งหมดใน order เดียว
  static Future<Map<String, dynamic>> postAllReviewFood({
    required int orderId,
    required List<Map<String, dynamic>> reviews,
  }) async {
    final token = await AuthService().getToken();

    final body = jsonEncode({"order_id": orderId, "reviews": reviews});

    final response = await http.post(
      Uri.parse('$baseUrl/food'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to post food review: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> postMarketReview({
    required int orderId,
    required int marketId,
    required int rating,
    String? comment,
  }) async {
    final token = await AuthService().getToken();

    final body = jsonEncode({
      "order_id": orderId,
      "market_id": marketId,
      "rating": rating,
      "comment": comment ?? '',
    });

    final response = await http.post(
      Uri.parse('$baseUrl/market'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to post market review: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> postRiderReview({
    required int orderId,
    required int riderId,
    required int rating,
    String? comment,
  }) async {
    final token = await AuthService().getToken();

    final body = jsonEncode({
      "order_id": orderId,
      "rider_id": riderId,
      "rating": rating,
      "comment": comment ?? '',
    });

    final response = await http.post(
      Uri.parse('$baseUrl/rider'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to post rider review: ${response.body}");
    }
  }
}
