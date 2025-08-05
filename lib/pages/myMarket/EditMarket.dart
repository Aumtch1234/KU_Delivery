import 'dart:io';
import 'package:delivery/APIs/FetchMarket.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:delivery/LoadingOverlay/LoadingOverlay.dart';
import 'package:delivery/APIs/UpdateMarketApi.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;

class EditShopPage extends StatefulWidget {
  @override
  _EditShopPageState createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  File? _image;
  String? _imageUrl; // สำหรับเก็บ URL รูปเก่า
  bool _isLoading = false;
  int? _marketId;

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  Future<void> _loadShopInfo() async {
    setState(() => _isLoading = true);

    try {
      final market = await fetchMyMarket();
      if (market != null) {
        setState(() {
          _nameController.text = market['shop_name'] ?? '';
          _descController.text = market['shop_description'] ?? '';
          openTime = _parseTime(market['open_time']);
          closeTime = _parseTime(market['close_time']);
          _marketId = market['market_id'];
          _imageUrl = market['shop_logo_url'];
        });
      } else {
        throw Exception('โหลดข้อมูลร้านค้าไม่สำเร็จ');
      }
    } catch (e) {
      print('Error loading market: $e');
      // จัดการ error ตามต้องการ เช่น show dialog
    }

    setState(() => _isLoading = false);
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _pickTime(bool isOpening) {
    picker.DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      currentTime: DateTime.now(),
      theme: picker.DatePickerTheme(
        backgroundColor: Colors.white,
        itemStyle: const TextStyle(color: Colors.black, fontSize: 18),
        doneStyle: const TextStyle(
          color: Color(0xFF34C759),
          fontWeight: FontWeight.bold,
        ),
        cancelStyle: const TextStyle(color: Colors.grey),
      ),
      onConfirm: (DateTime time) {
        setState(() {
          if (isOpening) {
            openTime = TimeOfDay(hour: time.hour, minute: time.minute);
          } else {
            closeTime = TimeOfDay(hour: time.hour, minute: time.minute);
          }
        });
      },
    );
  }

  String _formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || openTime == null || closeTime == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'กรอกข้อมูลไม่ครบ',
        desc: 'โปรดกรอกข้อมูลให้ครบถ้วน',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (_marketId == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'ไม่พบข้อมูลร้านค้า',
        desc: 'โปรดลองใหม่อีกครั้งหรือเข้าสู่ระบบใหม่',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _isLoading = true);

    final result = await UpdateMarketApiMultipart(
      marketId: _marketId!,
      shopName: _nameController.text.trim(),
      shopDesc: _descController.text.trim(),
      openTime:
          '${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}',
      closeTime:
          '${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}',
      imageFile: _image,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      await AuthService().refreshUserToken();

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'อัปเดตร้านค้าสำเร็จ',
        desc: 'ระบบจะพาคุณกลับหน้าหลัก',
        btnOkOnPress: () {
          Navigator.pop(context, true); // ส่ง true กลับไปหน้าก่อน
        },
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'เกิดข้อผิดพลาด',
        desc: result['body']['message'] ?? 'ไม่สามารถอัปเดตร้านค้าได้',
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
          title: const Text('แก้ไขข้อมูลร้านค้า'),
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
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_imageUrl != null ? NetworkImage(_imageUrl!) : null)
                            as ImageProvider<Object>?,
                  child: (_image == null && _imageUrl == null)
                      ? const Icon(Icons.camera_alt)
                      : null,
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
                child: const Text(
                  'บันทึกการเปลี่ยนแปลง',
                  style: TextStyle(fontSize: 16),
                ),
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
      label: Text(_formatTime(time)),
      onPressed: () => _pickTime(isOpen),
    );
  }
}
