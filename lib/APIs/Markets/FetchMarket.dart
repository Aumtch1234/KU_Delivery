import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery/APIs/middleware/authService.dart';

Future<Map<String, dynamic>?> fetchMyMarket() async {
  final token = await AuthService().getToken(); // ได้จาก SharedPreferences
  final response = await http.get(
    Uri.parse('http://10.0.2.2:4000/api/my-market'), // สมมุติ endpoint
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final market = data['market'];

    print("🔄 รีโหลดตลาด: is_open = ${market['is_open']}");
    return market;
  } else {
    print('ไม่สามารถโหลดร้านได้: ${response.body}');
    return null;
  }
}
