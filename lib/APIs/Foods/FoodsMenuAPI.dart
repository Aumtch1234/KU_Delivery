import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:http/http.dart' as http;

class FoodApiService {

  Future<List<dynamic>> getAllFoods() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/foods'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Failed to load foods');
    }
  }
}