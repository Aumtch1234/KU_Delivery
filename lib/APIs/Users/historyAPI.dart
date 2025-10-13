import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';

class HistoryAPI {
  /// 🧾 ดึงประวัติการสั่งซื้อ (เฉพาะ completed / cancelled)
  static Future<List<dynamic>> getOrderHistory() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception("❌ Token not found");
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? [];
    } else {
      throw Exception("❌ Failed to load history (${response.statusCode})");
    }
  }
}
