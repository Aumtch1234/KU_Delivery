import 'dart:io';
import 'package:delivery/APIs/RegisterAPI.dart';
import 'package:delivery/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedImage; // สำหรับเก็บ URL หรือ Path ของรูป preset
  File? _image;           // สำหรับเก็บไฟล์รูปที่อัปโหลดจากเครื่อง

  final List<String> _imageOptions = [
    'assets/avatars/avatar-1.png',
    'assets/avatars/avatar-2.png',
    'assets/avatars/avatar-3.png',
    'assets/avatars/avatar-4.png',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF34C759),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: const Color(0xFFF7F7F7),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF34C759),
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
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _selectedImage = null; // ถ้าเลือกจากเครื่อง ให้ล้าง selected preset
      });
    }
  }

  Future<void> _handleRegisterUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      showAwesomeDialog(context, 'ข้อผิดพลาด', 'รหัสผ่านไม่ตรงกัน', DialogType.warning);
      return;
    }
    if (_gender == null) {
      showAwesomeDialog(context, 'ข้อผิดพลาด', 'กรุณาเลือกเพศ', DialogType.warning);
      return;
    }
    if (_selectedDate == null) {
      showAwesomeDialog(context, 'ข้อผิดพลาด', 'กรุณาเลือกวันเกิด', DialogType.warning);
      return;
    }
    if (_selectedImage == null && _image == null) {
      showAwesomeDialog(context, 'ข้อผิดพลาด', 'กรุณาเลือกรูปโปรไฟล์', DialogType.warning);
      return;
    }
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณายินยอมเงื่อนไข')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ถ้ามีรูปจากไฟล์ ให้ส่งไฟล์ _image
      // ถ้าเลือกรูป preset ให้ส่งชื่อไฟล์ (_selectedImage)
      final result = await registerUserAPI(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        gender: _gender!,
        birthdate: _selectedDate!.toIso8601String(),
        imageFile: _image,
      );

      setState(() => _isLoading = false);

      if (result['statusCode'] == 200) {
        showAwesomeDialog(
          context,
          'สำเร็จ',
          'สมัครสมาชิกสำเร็จ',
          DialogType.success,
          onOk: () => Navigator.pushReplacementNamed(context, '/login'),
        );
      } else {
        showAwesomeDialog(
          context,
          'ไม่สำเร็จ',
          result['body']['message'] ?? 'เกิดข้อผิดพลาด',
          DialogType.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(0xFF34C759),
          elevation: 0,
          title: const Text(
            'สมัครสมาชิก',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'โปรดกรอกข้อมูลส่วนตัว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildAvatarSelector(),
                _buildLabel("ชื่อ - นามสกุล *"),
                _buildTextField(_nameController, 'ชื่อ - นามสกุล'),
                _buildLabel("อีเมลของคุณ *"),
                _buildTextField(_emailController, 'อีเมลของคุณ',
                    keyboardType: TextInputType.emailAddress),
                _buildLabel("รหัสผ่านของคุณ"),
                _buildTextField(
                  _passwordController,
                  'รหัสผ่าน',
                  obscureText: true,
                ),
                _buildLabel("ยืนยันรหัสผ่านของคุณ"),
                _buildTextField(
                  _confirmPasswordController,
                  'ยืนยันรหัสผ่าน',
                  obscureText: true,
                ),
                _buildLabel('วัน เดือน ปีเกิด'),
                _buildDateSelector(),
                _buildLabel('เพศ'),
                Row(
                  children: [
                    _buildGenderRadio(0, 'ชาย'),
                    _buildGenderRadio(1, 'หญิง'),
                    _buildGenderRadio(2, 'ไม่ระบุ'),
                  ],
                ),
                _buildLabel("เบอร์โทรศัพท์มือถือ *"),
                _buildTextField(
                  _phoneController,
                  '** ใส่เบอร์ติดต่อจริง **',
                  keyboardType: TextInputType.phone,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agree,
                      activeColor: const Color(0xFF34C759),
                      onChanged: (val) => setState(() => _agree = val ?? false),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _handleRegisterUser,
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
  // ตรวจสอบว่ารูปที่เลือกเป็น URL หรือ preset asset
  final isUrlSelected = _selectedImage != null && _selectedImage!.startsWith('http');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel("เลือกรูปโปรไฟล์ของคุณ"),
      SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // รูปจาก URL (รูปเก่าที่โหลดมา)
            if (isUrlSelected)
              GestureDetector(
                onTap: () => setState(() {
                  _selectedImage = _selectedImage; // เลือก URL รูปนี้
                  _image = null; // ล้างไฟล์รูปถ้าเคยอัปโหลด
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUrlSelected ? Color(0xFF34C759) : Colors.grey.shade300,
                      width: isUrlSelected ? 4 : 2,
                    ),
                    boxShadow: isUrlSelected
                        ? [
                            BoxShadow(
                              color: Color(0xFF34C759).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(_selectedImage!),
                        radius: 40,
                      ),
                      if (isUrlSelected)
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
              ),

            // รูป preset asset
            ..._imageOptions.map((imagePath) {
              final isSelected = _selectedImage == imagePath;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedImage = imagePath;
                  _image = null; // ล้างไฟล์รูปถ้าเลือก preset
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFF34C759) : Colors.grey.shade300,
                      width: isSelected ? 4 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(0xFF34C759).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
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
            }).toList(),
          ],
        ),
      ),

      const SizedBox(height: 12),

      // ปุ่มอัปโหลดรูปจากเครื่อง
      Center(
        child: OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file),
          label: const Text("อัปโหลดรูปจากเครื่อง"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF34C759),
            side: BorderSide(color: Color(0xFF34C759)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // แสดงรูปที่เลือกจากเครื่อง (ถ้ามี)
      if (_image != null)
        Center(
          child: Column(
            children: [
              const Text("รูปที่เลือก"),
              const SizedBox(height: 8),
              CircleAvatar(radius: 50, backgroundImage: FileImage(_image!)),
            ],
          ),
        ),
    ],
  );
}


  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                color: _selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Align(
          alignment: const Alignment(-0.95, 0.0),
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
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
          if (value == null || value.isEmpty) return 'กรุณากรอก $label';
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
          onChanged: (val) => setState(() => _gender = val),
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
      btnOkColor: const Color(0xFF34C759),
    ).show();
  }
}
