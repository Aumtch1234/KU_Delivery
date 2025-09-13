import 'dart:convert';
import 'dart:io';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> AddMarketApiMultipart({
  required int ownerId, // 👈 เพิ่มกลับมา
  required String shopName,
  required String shopDesc,
  required File imageFile,
  String? openTime,      
  String? closeTime,     
  required String address,
  required String phone,
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/market/add');

  final token = await AuthService().getToken(); // ✅ ดึง token มาใช้

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token' // ✅ ใส่ token
     ..fields['shop_name'] = shopName
    ..fields['shop_description'] = shopDesc
    ..fields['open_time'] = openTime ?? ''
    ..fields['close_time'] = closeTime ?? ''
    ..fields['address'] = address
    ..fields['phone'] = phone
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
