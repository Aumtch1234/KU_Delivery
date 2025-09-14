import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;
class DistanceAPI {
  static Future<List<Map<String, dynamic>>> getDistanceByBasket({
    required List<Map<String, dynamic>> basket,
  }) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/distance');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'basket': basket}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to get distance');
    }
  }
}
