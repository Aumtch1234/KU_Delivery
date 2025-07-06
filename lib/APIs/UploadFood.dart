import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> uploadFood({
  required String foodName,
  required double price,
  required File image,
  required List<Map<String, dynamic>> options,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    print('ไม่พบ Token');
    return;
  }

  var uri = Uri.parse('http://10.0.2.2:4000/api/food/add');

  var request = http.MultipartRequest('POST', uri);

  request.fields['food_name'] = foodName;
  request.fields['price'] = price.toString();
  request.fields['options'] = jsonEncode(options);

  request.files.add(await http.MultipartFile.fromPath('image', image.path));

  request.headers['Authorization'] = 'Bearer $token';

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
