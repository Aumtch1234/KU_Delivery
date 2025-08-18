import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketsApiService {
  static const String _baseUrl = 'http://10.0.2.2:4000/api';

  Future<List<dynamic>> getAllMarkets() async {
    final response = await http.get(Uri.parse('$_baseUrl/markets'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Failed to load Marketss');
    }
  }
}