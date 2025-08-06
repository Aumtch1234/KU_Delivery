import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> updateFood({
  required int foodId,
  required String foodName,
  required double price,
  String? options,
  File? imageFile,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri = Uri.parse('http://192.168.99.44:4000/api/food/update/$foodId');
  final request = http.MultipartRequest('PUT', uri);

  // ✅ แนบ Authorization header
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  request.fields['food_name'] = foodName;
  request.fields['price'] = price.toString();
  if (options != null) {
    request.fields['options'] = options;
  }

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

  final response = await request.send();

  if (response.statusCode == 200) {
    return true;
  } else {
    print('❌ Failed to update food. Status code: ${response.statusCode}');
    final responseBody = await response.stream.bytesToString();
    print('❌ Response body: $responseBody');
    return false;
  }
}
