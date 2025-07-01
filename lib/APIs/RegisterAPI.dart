import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> registerUserAPI({
  required String name,
  required String email,
  required String password,
  required String phone,
  required int gender,
  required String birthdate,
  required String photoUrl,
}) async {
  final url = Uri.parse('http://10.0.2.2:4000/api/register');

  final body = {
    'display_name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'gender': gender,
    'birthdate': birthdate,
    'photo_url': photoUrl,
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  return {
    'statusCode': response.statusCode,
    'body': jsonDecode(response.body),
  };
}
