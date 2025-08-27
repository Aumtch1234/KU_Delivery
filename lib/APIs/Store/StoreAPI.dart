import 'dart:convert';
import 'package:http/http.dart' as http;

class StoreController {
  final String baseUrl = "http://10.0.2.2:4000/client";

  /// ดึงเมนูของร้านตาม marketId
  Future<List<Map<String, dynamic>>> fetchFoods(int marketId) async {
    final url = Uri.parse('$baseUrl/foods?marketId=$marketId'); // ปรับ URL API ให้รองรับ query param
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to fetch foods');
    }
  }
}
