import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery/pages/WellcomePage.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  AuthGuard({required this.child});

  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) return false;

    try {
      // 👇 Decode JWT payload
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return expiry != null && expiry > now; // ✅ ยังไม่หมดอายุ
    } catch (e) {
      return false; // ❌ token เสียหรือ decode ไม่ได้
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return wellcomePage(); // ไปหน้าต้อนรับหากไม่ login หรือ token หมดอายุ
        }
      },
    );
  }
}
