import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> verifyOtpApi(String email, String otp) async {
  final url = Uri.parse('http://192.168.99.44:4000/api/verify-otp');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'otp': otp}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  } else {
    throw Exception('Failed to verify OTP');
  }
}

Future<bool> resendOtpApi(String email) async {
  final url = Uri.parse('http://192.168.99.44:4000/api/send-otp');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  } else {
    throw Exception('Failed to resend OTP');
  }
}
