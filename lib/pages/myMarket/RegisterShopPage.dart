import 'dart:io';
import 'package:delivery/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:delivery/APIs/AddMarketAPI.dart';
import 'package:delivery/middleware/authService.dart';

class RegisterShopPage extends StatefulWidget {
  @override
  _RegisterShopPageState createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpening)
          openTime = picked;
        else
          closeTime = picked;
      });
    }
  }

  String formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  void _submit() async {
    if (_nameController.text.isEmpty ||
        _image == null ||
        openTime == null ||
        closeTime == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'กรอกข้อมูลไม่ครบ',
        desc: 'โปรดกรอกข้อมูลให้ครบถ้วน',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    final user = AuthService().currentUser;
    if (user == null || user['user_id'] == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'ไม่พบผู้ใช้',
        desc: 'กรุณาเข้าสู่ระบบใหม่',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _isLoading = true); // ✅ เริ่มโหลด

    final result = await AddMarketApiMultipart(
      ownerId: user['user_id'],
      shopName: _nameController.text,
      shopDesc: _descController.text,
      imageFile: _image!,
      openTime: openTime!.format(context),
      closeTime: closeTime!.format(context),
    );

    setState(() => _isLoading = false); // ✅ หยุดโหลด

    if (result['statusCode'] == 200) {
      await AuthService().refreshUserToken();
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'สมัครร้านค้าสำเร็จ',
        desc: 'ระบบจะพาคุณกลับหน้าหลัก',
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
    const primaryColor = Color(0xFF34C759);

    return LoadingOverlay(
      isLoading: _isLoading,

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text('สมัครเป็นร้านค้า'),
        ),
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
                  child: _image == null ? const Icon(Icons.camera_alt) : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('ชื่อร้านค้า'),
              _buildTextField(_nameController, 'ระบุชื่อร้าน'),
              _buildLabel('คำอธิบายร้าน'),
              _buildTextField(_descController, 'ระบุคำอธิบาย', maxLines: 3),
              const SizedBox(height: 12),
              _buildLabel('เวลาเปิดร้าน'),
              _buildTimePickerButton(true),
              const SizedBox(height: 8),
              _buildLabel('เวลาปิดร้าน'),
              _buildTimePickerButton(false),
              const SizedBox(height: 12),
              _buildLabel('เลือกตำแหน่งร้านบนแผนที่'),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
        fillColor: Colors.grey[100],
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTimePickerButton(bool isOpen) {
    final time = isOpen ? openTime : closeTime;
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time),
      label: Text(formatTime(time)),
      onPressed: () => _pickTime(isOpen),
    );
  }
}
