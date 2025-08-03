import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? currentUser;
  final String baseUrl = 'http://10.0.2.2:4000/api';
  // C75 192.168.159.44

  /// ✅ Login แบบ Manual (อีเมล + รหัสผ่าน)
  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveAuthData(data);
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: ${e.toString()}'};
    }
  }

  /// ✅ Login แบบ Google
  Future<bool> loginWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(data);
      return true;
    } else {
      print('Google login failed: ${response.body}');
      return false;
    }
  }

  /// ✅ รีเฟรช Token
  Future<void> refreshUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/refresh-token'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));
      currentUser = data['user'];
    } else {
      print('Refresh token failed: ${response.body}');
    }
  }

  /// ✅ โหลดผู้ใช้จาก local
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      currentUser = jsonDecode(userStr);
    }
  }

  /// ✅ ล็อกเอาท์
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    currentUser = null;
    // นำผู้ใช้กลับไปหน้า Login และล้างทุกหน้าก่อนหน้า
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// ✅ เก็บ token/user ลง local และ set currentUser
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data['user']));
    currentUser = data['user'];
  }

  /// ✅ ดึง token จาก local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}