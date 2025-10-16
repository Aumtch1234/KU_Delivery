import 'dart:io';
import 'package:delivery/APIs/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> updateFood({
  required int foodId,
  required String foodName,
  required double price,
  required int categoryId,
  String? options,
  File? imageFile,
  bool? isVisible, // ✅ เพิ่ม
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri = Uri.parse('${ApiConfig.baseUrl}/food/update/$foodId');
  final request = http.MultipartRequest('PUT', uri);

  // ✅ แนบ Authorization header
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  // ✅ ข้อมูลหลัก
  request.fields['food_name'] = foodName;
  request.fields['price'] = price.toString();
  request.fields['category_id'] = categoryId.toString();

  // ✅ แนบ options (ถ้ามี)
  if (options != null) {
    request.fields['options'] = options;
  }

  // ✅ แนบสถานะพร้อมขาย (ถ้ามี)
  if (isVisible != null) {
    request.fields['is_visible'] = isVisible.toString();
  }

  // ✅ แนบรูปภาพ (ถ้ามี)
  if (imageFile != null) {
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );
  }

  print('🔵 Updating food...');
  print('Food ID: $foodId');
  print('Food Name: $foodName');
  print('Price: $price');
  print('Category ID: $categoryId');
  print('Is Visible: $isVisible'); // ✅ log ใหม่
  print('Has Image: ${imageFile != null}');

  // ✅ ส่งคำขอ
  final response = await request.send();

  if (response.statusCode == 200) {
    print('✅ อัปเดตเมนูสำเร็จ');
    return true;
  } else {
    print('❌ Failed to update food. Status code: ${response.statusCode}');
    final responseBody = await response.stream.bytesToString();
    print('❌ Response body: $responseBody');
    return false;
  }
}
