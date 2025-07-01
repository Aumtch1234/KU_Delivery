import 'package:delivery/APIs/AddMarketAPI.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:io';

class RegisterShopPage extends StatefulWidget {
  @override
  _RegisterShopPageState createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  void _submit() async {
    if (_nameController.text.isEmpty || _image == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'กำลังอัปโหลด...',
      desc: 'กรุณารอสักครู่',
      autoHide: const Duration(seconds: 2),
    ).show();

    final user = AuthService().currentUser;
    if (user == null || user['user_id'] == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'ไม่พบข้อมูลผู้ใช้',
        desc: 'กรุณาเข้าสู่ระบบใหม่',
        btnOkOnPress: () {},
      ).show();
      return;
    }
    final result = await AddMarketApiMultipart(
      ownerId: user['user_id'], // ✅ รองรับได้ทั้งแบบ manual หรือ google
      shopName: _nameController.text,
      shopDesc: _descController.text,
      imageFile: _image!,
    );

    if (result['statusCode'] == 200) {
      // ✅ รีเฟรช token ก่อนโชว์ success
      await AuthService().refreshUserToken();

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'สมัครร้านค้าสำเร็จ',
        desc: 'ระบบจะพาคุณกลับสู่หน้าหลัก',
        btnOkOnPress: () => Navigator.pop(context),
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'เกิดข้อผิดพลาด',
        desc: result['body']['message'] ?? 'ไม่สามารถสมัครร้านค้าได้',
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครเป็นร้านค้า')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('ชื่อร้านค้า'),
            _buildTextField(_nameController, 'ระบุชื่อร้าน'),
            _buildLabel('คำอธิบายร้าน'),
            _buildTextField(_descController, 'ระบุคำอธิบาย', maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('ยืนยัน', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
