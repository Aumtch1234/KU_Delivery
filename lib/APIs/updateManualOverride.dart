import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery/middleware/authService.dart';

Future<bool> updateManualOverrideAPI(String marketId, bool isManualOverride, bool isOpen) async {
  final token = await AuthService().getToken();
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.patch(
      Uri.parse('http://192.168.99.44:4000/api/my-market/override/$marketId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'is_manual_override': isManualOverride,
        'is_open': isOpen, // ส่งสถานะปัจจุบันไปด้วยเพื่อไม่ให้ reset
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ อัปเดต manual override ล้มเหลว: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ Exception in updateManualOverrideAPI: $e');
    return false;
  }
}
