import 'dart:convert';
import 'dart:io';
import 'package:delivery/middleware/authService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> AddMarketApiMultipart({
  required int ownerId, // 👈 เพิ่มกลับมา
  required String shopName,
  required String shopDesc,
  required File imageFile,
  String? openTime,      // เพิ่มนี้
  String? closeTime,     // เพิ่มนี้
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse('http://192.168.99.44:4000/api/market/add');

  final token = await AuthService().getToken(); // ✅ ดึง token มาใช้

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token' // ✅ ใส่ token
     ..fields['shop_name'] = shopName
    ..fields['shop_description'] = shopDesc
    ..fields['open_time'] = openTime ?? ''
    ..fields['close_time'] = closeTime ?? ''
    ..fields['latitude'] = latitude.toString()
    ..fields['longitude'] = longitude.toString()
    ..files.add(await http.MultipartFile.fromPath('shop_logo', imageFile.path));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  final body = jsonDecode(response.body);

  return {
    'statusCode': response.statusCode,
    'body': body,
  };
}
