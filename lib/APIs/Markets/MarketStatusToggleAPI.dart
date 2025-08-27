import 'dart:convert';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;

Future<bool> toggleMarketStatus(bool newStatus, String marketId) async {
  final token = await AuthService().getToken();

  if (token == null || token.isEmpty) {
    print('❌ ไม่พบ Token');
    return false;
  }

  print('🟢 toggleMarketStatus called: newStatus=$newStatus, marketId=$marketId');

  try {
    final response = await http.patch(
      Uri.parse('http://10.0.2.2:4000/client/my-market/status/$marketId'), // ✅ ระวัง path prefix
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'is_open': newStatus}),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ อัปเดตสถานะร้านสำเร็จ');
      return true;
    } else {
      print('❌ อัปเดตสถานะร้านล้มเหลว:  ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ Exception in toggleMarketStatus: $e');
    return false;
  }
}
