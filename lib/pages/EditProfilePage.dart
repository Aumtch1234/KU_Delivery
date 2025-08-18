import 'dart:io';
import 'package:delivery/APIs/Users/UpdateInfoUser.dart';
import 'package:delivery/APIs/Users/UpdateProfileAPI.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryGreen = const Color(0xFF34C759);

  int? _gender;
  DateTime? _selectedDate;
  String? _selectedImage;
  File? _image;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _provider;

  final List<String> _imageOptions = [
    'assets/avatars/avatar-1.png',
    'assets/avatars/avatar-2.png',
    'assets/avatars/avatar-3.png',
    'assets/avatars/avatar-4.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  bool _isVerified = false;

  Future<void> _loadUser() async {
    await AuthService().loadUser();
    final user = AuthService().currentUser;

    if (user != null) {
      setState(() {
        _nameController.text = user['display_name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
        _provider = user['providers'];
        _gender = user['gender'];
        _isVerified = user['is_verified'] ?? false;
        _selectedDate = user['birthdate'] != null
            ? DateTime.tryParse(user['birthdate'])
            : null;
        if (user['photo_url'] != null && user['photo_url'].startsWith('http')) {
          _selectedImage = user['photo_url'];
        }
      });
    }
  }

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
          dialogBackgroundColor: Color(0xFFF7F7F7),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF34C759),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) return _showDialog('กรุณาเลือกเพศ');
    if (_selectedDate == null) return _showDialog('กรุณาเลือกวันเกิด');
    if (_selectedImage == null && _image == null) {
      return _showDialog('กรุณาเลือกรูปโปรไฟล์');
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'ยืนยันข้อมูล',
      desc: 'คุณต้องการยืนยันข้อมูลส่วนตัวนี้ใช่หรือไม่?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() => _isLoading = true);
        try {
          final result = await UpdateProfileAPI(
            displayName: _nameController.text,
            phone: _phoneController.text,
            gender: _gender!.toString(),
            birthdate: _selectedDate!.toIso8601String(),
            email: _emailController.text,
            photoUrl: _selectedImage ?? '',
            imageFile: _image, // ถ้าไม่มีรูปใหม่จะเป็น null
          );

          if (result['success'] == true) {
            if (!_isVerified) {
              // ส่ง OTP ก็ต่อเมื่อยังไม่ยืนยันตัวตน
              final otpResult = await UpdateInfoUser.sendOtp(
                _emailController.text,
              );

              if (otpResult['success'] == true) {
                _showDialog(
                  'อัปเดตข้อมูลสำเร็จ กรุณายืนยัน OTP ที่อีเมลของคุณ',
                  DialogType.success,
                  () => Navigator.pushReplacementNamed(context, '/verify-otp'),
                );
              } else {
                _showDialog(
                  otpResult['message'] ?? 'ส่ง OTP ไม่สำเร็จ',
                  DialogType.error,
                );
              }
            } else {
              // ถ้า verified แล้ว ไม่ต้องส่ง OTP แสดงข้อความสำเร็จเฉย ๆ
              _showDialog(
                'อัปเดตข้อมูลสำเร็จ',
                DialogType.success,
                () => Navigator.pop(context), // ปิดหน้านี้กลับไปหน้าก่อนหน้า
              );
            }
          } else {
            _showDialog(
              result['message'] ?? 'เกิดข้อผิดพลาด',
              DialogType.error,
            );
          }
        } catch (e) {
          _showDialog('เกิดข้อผิดพลาด: $e', DialogType.error);
        } finally {
          setState(() => _isLoading = false);
        }
      },
    ).show();
  }

  void _showDialog(
    String msg, [
    DialogType type = DialogType.warning,
    VoidCallback? onOk,
  ]) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: 'แจ้งเตือน',
      desc: msg,
      btnOkOnPress: onOk ?? () {},
      btnOkColor: primaryGreen,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขข้อมูลส่วนตัว"),
        backgroundColor: primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "โปรดตรวจสอบหรือกรอกข้อมูลให้ครบ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAvatarSelector(),
                            _buildLabel("ชื่อ - นามสกุล"),
                            _buildTextField(_nameController, 'ชื่อ - นามสกุล'),
                            _buildLabel("อีเมล"),
                            _buildTextField(
                              _emailController,
                              'อีเมล',
                              keyboardType: TextInputType.emailAddress,
                              enabled:
                                  !_isVerified &&
                                  _provider == 'manual', // ✅ แก้ตรงนี้
                            ),

                            _buildLabel("เบอร์โทรศัพท์มือถือ *"),
                            _buildTextField(
                              _phoneController,
                              '** ใส่เบอร์ติดต่อจริง **',
                              keyboardType: TextInputType.phone,
                            ),
                            _buildLabel("วันเกิด"),
                            _buildDateSelector(),
                            _buildLabel("เพศ"),
                            Row(
                              children: [
                                _buildGenderRadio(0, "ชาย"),
                                _buildGenderRadio(1, "หญิง"),
                                _buildGenderRadio(2, "ไม่ระบุ"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'ยืนยันข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: (val) =>
          val == null || val.isEmpty ? 'กรุณากรอก $label' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderRadio(int value, String label) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: _gender,
          activeColor: primaryGreen,
          onChanged: (val) => setState(() => _gender = val),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'เลือกวันเกิด'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
            Icon(Icons.calendar_today, color: primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    // ตรวจสอบว่ารูปที่เลือกเป็น URL หรือ preset asset
    final bool isUrlSelected =
        _selectedImage != null && _selectedImage!.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("เลือกรูปโปรไฟล์ของคุณ"),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // รูป URL รูปเก่า
              if (_selectedImage != null && _selectedImage!.startsWith('http'))
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // เลือกรูป URL นี้
                      _selectedImage = _selectedImage;
                      _image = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUrlSelected
                            ? primaryGreen
                            : Colors.grey.shade300,
                        width: isUrlSelected ? 4 : 2,
                      ),
                      boxShadow: isUrlSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            _selectedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, size: 40),
                          ),
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

              // รูป preset avatar
              ..._imageOptions.map((imagePath) {
                final isSelected = _selectedImage == imagePath;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = imagePath;
                      _image = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryGreen : Colors.grey.shade300,
                        width: isSelected ? 4 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
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
              foregroundColor: primaryGreen,
              side: BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // แสดงรูปที่อัปโหลดจากเครื่อง ถ้ามี
        if (_image != null)
          Center(
            child: Column(
              children: [
                const Text("รูปที่เลือก"),
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 50,
                  child: ClipOval(
                    child: Image.file(
                      _image!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _selectedImage = null;
      });
    }
  }
}
