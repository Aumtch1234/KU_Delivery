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
  String? _currentPhotoUrl;
  File? _newImage;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _provider;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

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
        _currentPhotoUrl = user['photo_url'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: const Color(0xFFF7F7F7),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: const Color(0xFFF7F7F7),
            headerBackgroundColor: primaryGreen,
            headerForegroundColor: Colors.white,
            dayBackgroundColor: const MaterialStatePropertyAll(Colors.white),
            dayForegroundColor: const MaterialStatePropertyAll(Colors.black),
            todayBackgroundColor: MaterialStatePropertyAll(
              primaryGreen.withOpacity(0.2),
            ),
            todayForegroundColor: MaterialStatePropertyAll(primaryGreen),
            shape: const RoundedRectangleBorder(
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

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'ยืนยันข้อมูล',
      desc: 'คุณต้องการบันทึกข้อมูลส่วนตัวนี้ใช่หรือไม่?',
      btnCancelText: 'ยกเลิก',
      btnOkText: 'ยืนยัน',
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
            photoUrl: _currentPhotoUrl ?? '',
            imageFile: _newImage,
          );

          if (result['success'] == true) {
            if (!_isVerified) {
              final otpResult = await UpdateInfoUser.sendOtp(
                _emailController.text,
              );

              if (otpResult['success'] == true) {
                _showDialog(
                  'อัปเดตข้อมูลสำเร็จ\nกรุณายืนยัน OTP ที่อีเมลของคุณ',
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
              _showDialog(
                'อัปเดตข้อมูลสำเร็จ',
                DialogType.success,
                () => Navigator.pop(context),
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
      title: type == DialogType.success ? 'สำเร็จ' : 'แจ้งเตือน',
      desc: msg,
      btnOkOnPress: onOk ?? () {},
      btnOkColor: primaryGreen,
      btnOkText: 'ตรวจสอบ',
    ).show();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'เลือกรูปโปรไฟล์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'กล้อง',
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        _newImage = File(picked.path);
                      });
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'แกลเลอรี่',
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        _newImage = File(picked.path);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryGreen.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: primaryGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "แก้ไขข้อมูลส่วนตัว",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังบันทึกข้อมูล...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ✅ Profile Picture Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ✅ รูปโปรไฟล์ (แสดงรูปปัจจุบัน หรือรูปใหม่ที่เลือก)
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryGreen.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: _newImage != null
                                          ? FileImage(_newImage!)
                                                as ImageProvider
                                          : (_currentPhotoUrl != null &&
                                                _currentPhotoUrl!.isNotEmpty)
                                          ? NetworkImage(_currentPhotoUrl!)
                                          : null,
                                      child:
                                          (_newImage == null &&
                                              (_currentPhotoUrl == null ||
                                                  _currentPhotoUrl!.isEmpty))
                                          ? Icon(
                                              Icons.person,
                                              size: 70,
                                              color: Colors.grey[400],
                                            )
                                          : null,
                                    ),
                                  ),

                                  // ✅ ปุ่มลบรูปใหม่ (เฉพาะตอนมีรูปใหม่)
                                  if (_newImage != null)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _newImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // ✅ ปุ่มกล้อง (อัปโหลดใหม่)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _newImage != null
                                    ? 'รูปใหม่ที่เลือก (แตะกากบาทเพื่อลบ)'
                                    : 'แตะที่ไอคอนกล้องเพื่อเปลี่ยนรูป',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Form Section
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('ข้อมูลส่วนตัว'),
                                const SizedBox(height: 16),

                                _buildLabel("ชื่อ - นามสกุล"),
                                _buildTextField(
                                  _nameController,
                                  'กรอกชื่อ - นามสกุล',
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("อีเมล"),
                                _buildTextField(
                                  _emailController,
                                  'กรอกอีเมล',
                                  Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled:
                                      !_isVerified && _provider == 'manual',
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("เบอร์โทรศัพท์"),
                                _buildTextField(
                                  _phoneController,
                                  'กรอกเบอร์โทรศัพท์',
                                  Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("วันเกิด"),
                                _buildDateSelector(),
                                const SizedBox(height: 16),

                                _buildLabel("เพศ"),
                                _buildGenderSelector(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Bottom Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        validator: (val) =>
            val == null || val.isEmpty ? 'กรุณากรอก$hint' : null,
        style: TextStyle(color: enabled ? Colors.black : Colors.grey[600]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: primaryGreen),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: primaryGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'เลือกวันเกิด'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}',
                style: TextStyle(
                  color: _selectedDate == null
                      ? Colors.grey[400]
                      : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildGenderOption(0, "ชาย", Icons.male),
          _buildGenderOption(1, "หญิง", Icons.female),
          _buildGenderOption(2, "ไม่ระบุ", Icons.transgender),
        ],
      ),
    );
  }

  Widget _buildGenderOption(int value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
