import 'dart:io';
import 'package:delivery/APIs/Users/RegisterAPI.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
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

  File? _image; // เก็บไฟล์รูปที่อัปโหลด

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
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
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
    if (_image == null) {
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'กรอกข้อมูลเพื่อสมัครสมาชิก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'โปรดกรอกข้อมูลให้ครบถ้วน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Profile Image Upload Section
                _buildProfileImageSection(),
                
                const SizedBox(height: 24),
                
                _buildLabel("ชื่อ - นามสกุล *"),
                _buildTextField(_nameController, 'กรอกชื่อ - นามสกุล'),
                
                _buildLabel("อีเมล *"),
                _buildTextField(
                  _emailController,
                  'กรอกอีเมลของคุณ',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                
                _buildLabel("รหัสผ่าน *"),
                _buildTextField(
                  _passwordController,
                  'กรอกรหัสผ่าน',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                
                _buildLabel("ยืนยันรหัสผ่าน *"),
                _buildTextField(
                  _confirmPasswordController,
                  'กรอกรหัสผ่านอีกครั้ง',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                
                _buildLabel('วันเกิด *'),
                _buildDateSelector(),
                
                _buildLabel('เพศ *'),
                _buildGenderSelector(),
                
                _buildLabel("เบอร์โทรศัพท์ *"),
                _buildTextField(
                  _phoneController,
                  'กรอกเบอร์โทรศัพท์',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                
                const SizedBox(height: 8),
                
                // Agreement Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agree,
                      activeColor: const Color(0xFF34C759),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) => setState(() => _agree = val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'ยินยอมให้เข้าถึงข้อมูลและเข้าใช้บริการบางส่วน',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(52),
                    elevation: 2,
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
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'รูปโปรไฟล์',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Image Preview or Placeholder
          _image != null
              ? Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF34C759),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34C759).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
          
          const SizedBox(height: 16),
          
          // Upload Button
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: Icon(_image != null ? Icons.edit : Icons.upload_file),
            label: Text(_image != null ? 'เปลี่ยนรูป' : 'อัปโหลดรูป'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5EA)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDate == null ? Colors.grey : const Color(0xFF34C759),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'เลือกวันเกิด'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildGenderOption(0, 'ชาย', Icons.male)),
          Expanded(child: _buildGenderOption(1, 'หญิง', Icons.female)),
          Expanded(child: _buildGenderOption(2, 'ไม่ระบุ', Icons.person)),
        ],
      ),
    );
  }

  Widget _buildGenderOption(int value, String label, IconData icon) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF34C759) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey[600], size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'กรุณากรอกข้อมูล';
          return null;
        },
      ),
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