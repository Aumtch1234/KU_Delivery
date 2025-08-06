import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:delivery/middleware/authService.dart';
import 'package:path/path.dart';

Future<Map<String, dynamic>> UpdateProfileAPI({
  required String displayName,
  required String phone,
  required String gender,
  required String birthdate,
  required String email,
  required String photoUrl, // หากไม่อัปโหลดใหม่ จะใช้ตัวนี้แทน
  File? imageFile, // ถ้ามีไฟล์ จะอัปโหลดใหม่
}) async {
  final token = await AuthService().getToken();

  final uri = Uri.parse('http://192.168.99.44:4000/api/update-profile');
  final request = http.MultipartRequest('PUT', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['display_name'] = displayName
    ..fields['phone'] = phone
    ..fields['gender'] = gender
    ..fields['birthdate'] = birthdate
    ..fields['email'] = email
    ..fields['photoUrl'] = photoUrl; // ส่งไว้เผื่อไม่ได้อัปโหลดใหม่

  if (imageFile != null) {
    final fileName = basename(imageFile.path);
    request.files.add(await http.MultipartFile.fromPath('Profile', imageFile.path, filename: fileName));
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('อัปเดตข้อมูลไม่สำเร็จ: ${response.statusCode} - ${response.body}');
  }
}
