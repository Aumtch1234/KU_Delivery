import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:delivery/middleware/authService.dart';

class UpdateInfoUser {
  static const String baseUrl = 'http://192.168.99.44:4000/api';

  static Future<Map<String, dynamic>> updateVerify({
    required String displayName,
    required String phone,
    required int gender,
    required String birthdate,
    required String email, // ✅ เพิ่ม email
    File? imageFile,
    String? photoUrl,
  }) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl/update-verify');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['display_name'] = displayName;
    request.fields['phone'] = phone;
    request.fields['gender'] = gender.toString();
    request.fields['birthdate'] = birthdate;
    request.fields['email'] = email; // ✅ ส่ง email ไปด้วยเสมอ

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('Profile', imageFile.path),
      );
    } else if (photoUrl != null) {
      request.fields['photo_url'] = photoUrl;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'เกิดข้อผิดพลาด',
      };
    }
  }
  static Future<Map<String, dynamic>> sendOtp(String email) async {
  final response = await http.post(
    Uri.parse('$baseUrl/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {'success': false, 'message': 'ส่ง OTP ไม่สำเร็จ'};
  }
}

}


