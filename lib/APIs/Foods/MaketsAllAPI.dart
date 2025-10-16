import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';

class MarketsApiService {
  Future<List<dynamic>> getAllMarkets() async {
    final token = await AuthService().getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/markets'); // ✅ มี /client อยู่แล้ว

    print('🌍 [MarketsApiService] Fetching markets from: $url');
    print('🪙 Token: $token');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📩 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load Markets');
    }
  }

  Future<List<dynamic>> getAllADMINMarkets() async {
    final token = await AuthService().getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/markets-admin');
    print('🌍 Fetching admin markets from: $url');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    print('📡 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load ADMIN Markets');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final token = await AuthService().getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/categories');
    print('🌍 Fetching categories from: $url');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    print('📡 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load Categories');
    }
  }
}