import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/APIs/middleware/authService.dart';

Future<bool> updateManualOverrideAPI(String marketId, bool isManualOverride, bool isOpen) async {
  final token = await AuthService().getToken();
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/my-market/override/$marketId'),
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
