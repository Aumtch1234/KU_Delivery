import 'dart:io';
import 'package:delivery/APIs/UpdateInfoUser.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:image_picker/image_picker.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({Key? key}) : super(key: key);

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _formKey = GlobalKey<FormState>();
  int? _gender;
  DateTime? _selectedDate;
  String?
  _selectedImage; // URL string (for prebuilt avatars or existing user photo)
  File? _image; // File object (for new selected image)
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

  Future<void> _loadUser() async {
    await AuthService().loadUser();
    final user = AuthService().currentUser;

    if (user != null) {
      setState(() {
        _nameController.text = user['display_name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
        _provider = user['providers']; // <- เพิ่มบรรทัดนี้
        _gender = user['gender'];
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    print("📦 sending imageFile = ${_image?.path}");

    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) return _showDialog('กรุณาเลือกเพศ');
    if (_selectedDate == null) return _showDialog('กรุณาเลือกวันเกิด');
    if (_selectedImage == null && _image == null)
      return _showDialog('กรุณาเลือกรูปโปรไฟล์');

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
          String? imageUrl = _selectedImage;

          // final token = AuthService().getToken();
          final result = await UpdateInfoUser.updateVerify(
            displayName: _nameController.text,
            phone: _phoneController.text,
            gender: _gender!,
            birthdate: _selectedDate!.toIso8601String(),
            imageFile: _image, // ✅ เพิ่มบรรทัดนี้
            photoUrl: imageUrl ?? '',
          );

          if (result['success'] == true) {
            _showDialog('อัปเดตข้อมูลสำเร็จ', DialogType.success, () {
              Navigator.pop(context);
            });
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
      btnOkColor: Colors.green,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ยืนยันข้อมูลส่วนตัว"),
        backgroundColor: const Color(0xFF34C759),
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
                            const Text(
                              "โปรดตรวจสอบหรือกรอกข้อมูลให้ครบ",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                                  _provider !=
                                  'google', // ✅ ถ้าไม่ใช่ google แก้ไขได้
                            ),

                            _buildLabel("เบอร์โทรศัพท์"),
                            _buildTextField(
                              _phoneController,
                              'เบอร์โทรศัพท์',
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
                        backgroundColor: const Color(0xFF34C759),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'ยืนยันข้อมูล',
                        style: TextStyle(color: Colors.white),
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
    child: Text(text),
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
          enabled: enabled, // ✅ เพิ่มตรงนี้

      validator: (val) =>
          val == null || val.isEmpty ? 'กรุณากรอก $label' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGenderRadio(int value, String label) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: _gender,
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
          border: Border.all(color: const Color(0xFFE5E5EA)),
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
            const Icon(Icons.calendar_today, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 🟢 รูปจาก _imageOptions (avatar ที่เลือกไว้)
          ..._imageOptions.map((img) {
            final isSelected = _selectedImage == img;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = img;
                  _image = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF34C759) : Colors.grey,
                    width: isSelected ? 4 : 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(img),
                  radius: 40,
                ),
              ),
            );
          }).toList(),

          // 🟢 รูปจาก gallery (_image)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _image != null ? const Color(0xFF34C759) : Colors.grey,
                  width: _image != null ? 4 : 2,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null ? FileImage(_image!) : null,
                radius: 40,
                child: _image == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
          ),
        ],
      ),
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
