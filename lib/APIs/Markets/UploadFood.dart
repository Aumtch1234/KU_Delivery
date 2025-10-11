import 'dart:io';
import 'package:delivery/APIs/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> uploadFood({
  required String foodName,
  required double price,
  required File image,
  required List<Map<String, dynamic>> options,
  required int categoryId, // ✅ รับ categoryId
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    print('❌ ไม่พบ Token');
    return;
  }

  var uri = Uri.parse('${ApiConfig.baseUrl}/food/add');

  var request = http.MultipartRequest('POST', uri);

  // ✅ เพิ่มข้อมูลทั้งหมด
  request.fields['food_name'] = foodName;
  request.fields['price'] = price.toString();
  request.fields['category_id'] = categoryId.toString(); // ✅ เพิ่มบรรทัดนี้
  request.fields['options'] = jsonEncode(options);

  request.files.add(await http.MultipartFile.fromPath('image', image.path));

  request.headers['Authorization'] = 'Bearer $token';

  print('🔵 Adding food...');
  print('Food Name: $foodName');
  print('Price: $price');
  print('Category ID: $categoryId'); // ✅ เพิ่ม log
  print('Options: ${jsonEncode(options)}');

  var response = await request.send();

  if (response.statusCode == 200) {
    print('✅ เพิ่มเมนูสำเร็จ');
  } else {
    print('❌ เกิดข้อผิดพลาด: ${response.statusCode}');
    response.stream.transform(utf8.decoder).listen((value) {
      print('รายละเอียด: $value');
    });
  }
}