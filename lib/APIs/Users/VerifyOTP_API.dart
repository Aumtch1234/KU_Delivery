import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> verifyOtpApi(String email, String otp) async {
  final url = Uri.parse('http://10.90.92.44:4000/client/verify-otp');
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
  final url = Uri.parse('http://10.90.92.44:4000/client/send-otp');
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
