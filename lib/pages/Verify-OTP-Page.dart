import 'dart:async';
import 'dart:convert';
import 'package:delivery/APIs/VerifyOTP_API.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({Key? key}) : super(key: key);

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  // กำหนด email จริงที่ส่ง OTP ไป หรือรับมาจาก widget constructor
  String get _userEmail => user?['email'] ?? '';

  Timer? _timer;
  int _secondsRemaining = 60;

  final Color primaryColor = const Color(0xFF34C759);
  Map<String, dynamic>? user;
  @override
  void initState() {
    super.initState();
    _refreshAndLoadUser();
  }

  Future<void> _refreshAndLoadUser() async {
    await AuthService().refreshUserToken();
    print('เรียก refresh token สำเร็จ');
    await _loadUser();
    print('โหลด user ใหม่: $user');
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      setState(() {
        user = jsonDecode(userStr);
      });
    }
  }

  @override
  void dispose() {
    for (var ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _enteredOtp => _otpControllers.map((e) => e.text).join();

  void _submitOtp() async {
    if (_enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP ให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool verified = await verifyOtpApi(_userEmail, _enteredOtp);
      if (verified) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ยืนยัน OTP สำเร็จ')));
        // ตัวอย่างนำทางไปหน้า Dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP ไม่ถูกต้อง')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      bool sent = await resendOtpApi(_userEmail);
      if (sent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ส่ง OTP ใหม่แล้ว')));
        _refreshAndLoadUser();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ส่ง OTP ใหม่ล้มเหลว')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('ยืนยัน OTP'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          children: [
            const Text(
              'กรุณาใส่รหัส OTP 6 หลัก\nที่ส่งไปยังอีเมลของคุณ',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    autofocus: index == 0,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    cursorColor: primaryColor,
                    cursorWidth: 2.5,
                    cursorRadius: const Radius.circular(4),
                    style: const TextStyle(
                      fontSize: 24, // ✅ ปรับให้พอดีกับความสูง
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ), // ✅ จัดให้ตรงกลาง
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 3),
                      ),
                    ),
                    onChanged: (value) => _onOtpChanged(index, value),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ยืนยัน OTP',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            _secondsRemaining > 0
                ? Text(
                    'สามารถขอรหัสใหม่ได้ใน $_secondsRemaining วินาที',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                : TextButton(
                    onPressed: _resendOtp,
                    child: Text(
                      'ส่งรหัส OTP ใหม่',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
