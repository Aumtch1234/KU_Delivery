import 'dart:convert';
import 'dart:io';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> UpdateMarketApiMultipart({
  required int marketId,
  required String shopName,
  required String shopDesc,
  required String openTime,
  required String closeTime,
  required double latitude, // เพิ่ม parameter สำหรับ latitude
  required double longitude, // เพิ่ม parameter สำหรับ longitude
  File? imageFile,
}) async {
  const String baseUrl = "http://10.0.2.2:4000/api";
  final uri = Uri.parse('$baseUrl/markets/$marketId');
  print('🔵 Sending request to $uri');

  final request = http.MultipartRequest('PUT', uri);

  print(
      '🔵 Adding fields: shop_name=$shopName, shop_description=$shopDesc, open_time=$openTime, close_time=$closeTime, latitude=$latitude, longitude=$longitude');
  request.fields['shop_name'] = shopName;
  request.fields['shop_description'] = shopDesc;
  request.fields['open_time'] = openTime;
  request.fields['close_time'] = closeTime;
  request.fields['latitude'] = latitude.toString(); // ส่งค่า latitude
  request.fields['longitude'] = longitude.toString(); // ส่งค่า longitude

  if (imageFile != null) {
    print('🔵 Adding image file: ${imageFile.path}');
    request.files.add(await http.MultipartFile.fromPath('shop_logo', imageFile.path));
  } else {
    print('🔵 No image file to upload');
  }

  final token = await AuthService().getToken();
  print('🔵 Token: $token');
  if (token == null) {
    print('⚠️ No token found, aborting request');
    throw Exception('Token is null');
  }
  request.headers['Authorization'] = 'Bearer $token';

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('🔵 Response status: ${response.statusCode}');
    print('🔵 Response body: ${response.body}');

    return {
      'statusCode': response.statusCode,
      'body': json.decode(response.body),
    };
  } catch (e) {
    print('❌ Error sending request: $e');
    return {
      'statusCode': 500,
      'body': {'message': 'Request failed: $e'},
    };
  }
}