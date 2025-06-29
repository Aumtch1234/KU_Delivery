import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int? _gender;
  bool _agree = false;
  DateTime? _selectedDate;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34C759), // header background & selected day
              onPrimary: Colors.white, // header text & selected day text
              onSurface: Colors.black, // default text color
            ),
            dialogBackgroundColor: Color(0xFFF7F7F7),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF34C759), // button text color
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Color(0xFFF7F7F7),
              headerBackgroundColor: Color(0xFF34C759),
              headerForegroundColor: Colors.white,
              dayBackgroundColor: MaterialStatePropertyAll(Colors.white),
              dayForegroundColor: MaterialStatePropertyAll(Colors.black),
              todayBackgroundColor: MaterialStatePropertyAll(Color(0x2234C759)),
              todayForegroundColor: MaterialStatePropertyAll(Color(0xFF34C759)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      showAwesomeDialog(
        context,
        'ข้อผิดพลาด',
        'รหัสผ่านไม่ตรงกัน',
        DialogType.warning,
      );
      return;
    }
    if (_gender == null) {
      showAwesomeDialog(
        context,
        'ข้อผิดพลาด',
        'กรุณาเลือกเพศ',
        DialogType.warning,
      );
      return;
    }
    if (_selectedDate == null) {
      showAwesomeDialog(
        context,
        'ข้อผิดพลาด',
        'กรุณาเลือกวันเกิด',
        DialogType.warning,
      );
      return;
    }
    if (_selectedImage == null) {
      showAwesomeDialog(
        context,
        'ข้อผิดพลาด',
        'กรุณาเลือกรูปโปรไฟล์',
        DialogType.warning,
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:4000/api/register');

    Map<String, dynamic> body = {
      'display_name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'gender': _gender, // 0,1,2 ตามที่เลือก
      'birthdate': _selectedDate!.toIso8601String(),
      'photo_url': _selectedImage != null
          ? _selectedImage!.split('/').last
          : null,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // สมมติ response body มี success message หรือ token
        showAwesomeDialog(
          context,
          'สำเร็จ',
          'สมัครสมาชิกสำเร็จ',
          DialogType.success,
          onOk: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        );
        // นำทางไปหน้าถัดไป หรือเคลียร์ฟอร์ม
      } else {
        // แสดง error จาก server
        final resBody = jsonDecode(response.body);
        showAwesomeDialog(
          context,
          'ไม่สำเร็จ',
          resBody['message'] ?? 'เกิดข้อผิดพลาด',
          DialogType.error,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  // รูปที่ใช้ให้เลือก
  final List<String> _imageOptions = [
    'assets/avatars/kai.png',
    'assets/avatars/kai copy.png',
    'assets/avatars/kai copy 2.png',
    'assets/avatars/kai copy 3.png',
    'assets/avatars/kai copy 4.png',
    'assets/avatars/kai.png',
  ];
  String? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF34C759),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text(
                      'โปรดกรอกข้อมูลส่วนตัว',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFE5E5EA),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // แสดงรายการรูปโปรไฟล์ให้เลือก
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  "เลือกรูปโปรไฟล์ของคุณ",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageOptions.length,
                  itemBuilder: (context, index) {
                    String imagePath = _imageOptions[index];
                    bool isSelected = _selectedImage == imagePath;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = imagePath;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF34C759)
                                : Colors.grey.shade300,
                            width: isSelected ? 4 : 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(imagePath),
                              radius: 40,
                            ),
                            if (isSelected)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF34C759),
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel("ชื่อ - นามสกุล *"),
              _buildTextField(_nameController, 'ชื่อ - นามสกุล', false),
              _buildLabel("อีเมลของคุณ *"),
              _buildTextField(_emailController, 'อีเมลของคุณ', false),
              _buildLabel("รหัสผ่านของคุณ"),
              _buildTextField(_passwordController, 'รหัสผ่าน', true),
              _buildLabel("ยืนยันรหัสผ่านของคุณ"),
              _buildTextField(
                _confirmPasswordController,
                'กรุณณายืนยันรหัสผ่านของคุณอีกครั้ง',
                true,
              ),
              _buildLabel('วัน เดือน ปีเกิด'),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'วัน เดือน ปีเกิด'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              _buildLabel('เพศ'),
              Row(
                children: [
                  _buildGenderRadio(0, 'ชาย'),
                  _buildGenderRadio(1, 'หญิง'),
                  _buildGenderRadio(2, 'ไม่ระบุเพศ'),
                ],
              ),
              _buildLabel("เบอร์โทรศัพท์มือถือ  *"),
              _buildTextField(
                _phoneController,
                'เบอร์โทรศัพท์มือถือ',
                false,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agree,
                    activeColor: const Color(0xFF34C759),
                    onChanged: (bool? value) {
                      setState(() {
                        _agree = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        'ยินยอมให้เข้าถึงข้อมูลและเข้าใช้บริการบางส่วน',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _agree) {
                      _registerUser();
                    } else if (!_agree) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณายินยอมเงื่อนไข')),
                      );
                    }
                  },
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscureText, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอก $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderRadio(int value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<int>(
          value: value,
          groupValue: _gender,
          activeColor: const Color(0xFF34C759),
          onChanged: (int? val) {
            setState(() {
              _gender = val;
            });
          },
        ),
        Text(label),
        const SizedBox(width: 10),
      ],
    );
  }

  void showAwesomeDialog(
    BuildContext context,
    String title,
    String message,
    DialogType type, {
    VoidCallback? onOk,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: onOk ?? () {},
      btnOkColor: Colors.green,
    ).show();
  }
}
