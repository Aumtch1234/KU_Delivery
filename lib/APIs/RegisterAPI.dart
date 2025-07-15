import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:convert';

Future<Map<String, dynamic>> registerUserAPI({
  required String name,
  required String email,
  required String password,
  required String phone,
  required int gender,
  required String birthdate,
  File? imageFile, // รูปภาพที่ผู้ใช้เลือก (File)
}) async {
  final uri = Uri.parse('http://10.0.2.2:4000/api/register');

  var request = http.MultipartRequest('POST', uri);

  // เพิ่ม fields
  request.fields['display_name'] = name;
  request.fields['email'] = email;
  request.fields['password'] = password;
  request.fields['phone'] = phone;
  request.fields['gender'] = gender.toString();
  request.fields['birthdate'] = birthdate;

  // เพิ่มไฟล์ถ้ามี
  if (imageFile != null) {
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();
    var multipartFile = http.MultipartFile('Profile', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
  }

  // ส่งคำขอ
  var response = await request.send();

  var respStr = await response.stream.bytesToString();

  return {
    'statusCode': response.statusCode,
    'body': respStr.isNotEmpty ? jsonDecode(respStr) : null,
  };
}
