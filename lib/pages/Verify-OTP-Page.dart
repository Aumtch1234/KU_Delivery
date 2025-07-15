import 'package:flutter/material.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({Key? key}) : super(key: key);

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _enteredOtp => _otpControllers.map((e) => e.text).join();

  void _submitOtp() {
    if (_enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP ให้ครบ 6 หลัก')),
      );
      return;
    }
    // TODO: เชื่อมต่อ backend ตรวจสอบ OTP
    print('OTP submitted: $_enteredOtp');
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF34C759);

    return Scaffold(
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
              'กรุณาใส่รหัส OTP 6 หลักที่ส่งไปยังอีเมลของคุณ',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // กล่อง OTP 6 ช่อง
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
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 3),
                      ),
                    ),
                    onChanged: (value) => _onOtpChanged(index, value),
                  ),
                );
              }),
            ),

            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text(
                  'ยืนยัน OTP',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                // TODO: ส่ง OTP ใหม่
                print('Resend OTP');
              },
              child: Text(
                'ส่งรหัส OTP ใหม่',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
