import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>?> FetchFoodsForMarket() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('http://192.168.99.44:4000/api/my-foods'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return json['foods'];
  } else {
    print('⚠️ ดึงเมนูไม่สำเร็จ: ${response.statusCode}');
    return null;
  }
}
