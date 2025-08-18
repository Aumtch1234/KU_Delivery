import 'dart:io';
import 'package:delivery/APIs/Markets/AddMarketAPI.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:delivery/pages/myMarket/SelectLocationPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:delivery/APIs/middleware/authService.dart'; // ตรวจสอบว่าไฟล์นี้มีอยู่จริง
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  double? latitude;
  double? longitude;

  bool _isLoading = false;

  // เพิ่ม GoogleMapController สำหรับแผนที่แสดงตัวอย่าง
  GoogleMapController? _previewMapController;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _previewMapController?.dispose(); // ต้อง dispose controller ด้วย
    super.dispose();
  }

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // ฟังก์ชันสำหรับเลือกเวลาเปิด/ปิดร้าน
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

  // ฟังก์ชันจัดรูปแบบเวลา
  String formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  // ฟังก์ชันสำหรับส่งข้อมูล
  void _submit() async {
    if (latitude == null || longitude == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'ตำแหน่งยังไม่ถูกเลือก',
        desc: 'โปรดเลือกตำแหน่งร้านค้าบนแผนที่',
        btnOkOnPress: () {},
      ).show();
      return;
    }

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

    // ตรวจสอบว่า AuthService และ AddMarketApiMultipart มีอยู่จริงและใช้งานได้
    // เนื่องจากโค้ดนี้ไม่ได้รวมไฟล์เหล่านั้นมาด้วย
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

    try {
      final result = await AddMarketApiMultipart(
        ownerId: user['user_id'],
        shopName: _nameController.text,
        shopDesc: _descController.text,
        imageFile: _image!,
        latitude: latitude!,
        longitude: longitude!,
        openTime:
            '${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}',
        closeTime:
            '${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}',
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
    } catch (e) {
      setState(() => _isLoading = false); // ✅ หยุดโหลดหากเกิดข้อผิดพลาด
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'เกิดข้อผิดพลาดในการส่งข้อมูล',
        desc: e.toString(),
        btnOkOnPress: () {},
      ).show();
    }
  }

  // Widget สำหรับสร้างส่วนแสดงแผนที่เล็กๆ
  Widget _buildLocationPreview() {
    LatLng currentLatLng;
    double currentZoom;

    if (latitude != null && longitude != null) {
      currentLatLng = LatLng(latitude!, longitude!);
      currentZoom = 16; // ซูมมากขึ้นถ้ามีพิกัดแล้ว
    } else {
      currentLatLng = const LatLng(13.7563, 100.5018); // พิกัดเริ่มต้นกรุงเทพฯ
      currentZoom = 12;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('เลือกตำแหน่งร้านบนแผนที่'),
        const SizedBox(height: 8),
        Container(
          height: 200, // กำหนดความสูงของแผนที่
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          clipBehavior: Clip.antiAlias, // ทำให้แผนที่โค้งมนตามขอบ Container
          child: Stack(
            children: [
              GoogleMap(
                // ใช้ key เพื่อบังคับ rebuild เมื่อพิกัดเปลี่ยน (สำรอง)
                key: ValueKey('$latitude-$longitude'),
                initialCameraPosition: CameraPosition(
                  target: currentLatLng,
                  zoom: currentZoom,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_shop_location'),
                    position: currentLatLng,
                  ),
                },

                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                scrollGesturesEnabled: false, // ปิดการเลื่อนบนแผนที่เล็กๆ
                zoomGesturesEnabled: false, // ปิดการซูมบนแผนที่เล็กๆ
                onMapCreated: (controller) {
                  _previewMapController =
                      controller; // เก็บ controller ของแผนที่แสดงตัวอย่าง
                },
              ),
              // ปุ่มกดเพื่อไปหน้าเลือกตำแหน่ง
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final LatLng? selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectLocationPage(),
                        ),
                      );
                      if (selected != null) {
                        setState(() {
                          latitude = selected.latitude;
                          longitude = selected.longitude;
                        });
                        // เมื่อเลือกพิกัดแล้ว ให้แผนที่แสดงตัวอย่างเคลื่อนที่ไปที่พิกัดใหม่
                        _previewMapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(selected, 16),
                        );
                      }
                    },
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latitude == null
                              ? 'เลือกตำแหน่งร้าน'
                              : 'แก้ไขตำแหน่ง',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (latitude != null && longitude != null) // แสดงพิกัดใต้แผนที่
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'พิกัดที่เลือก: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF34C759);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'สมัครเป็นร้านค้า',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // ทำให้ Column ยืดเต็มความกว้าง
            children: [
              // ส่วนอัปโหลดรูปภาพ
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: primaryColor, width: 2),
                      image: _image != null
                          ? DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _image == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ส่วนข้อมูลร้านค้า
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('ข้อมูลร้านค้า'),
                      _buildTextField(_nameController, 'ชื่อร้านค้า'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _descController,
                        'คำอธิบายร้าน',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // ส่วนเวลาทำการ
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('เวลาทำการ'),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'เวลาเปิด',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                _buildTimePickerButton(true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'เวลาปิด',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                _buildTimePickerButton(false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ส่วนเลือกตำแหน่งร้านบนแผนที่ (แผนที่เล็กๆ)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLocationPreview(),
                ),
              ),

              // ปุ่มยืนยัน
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // ปรับให้โค้งมนขึ้น
                  ),
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  foregroundColor: Colors.white, // สีข้อความปุ่ม
                ),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง Label
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Color(0xFF34C759), // สีเขียว
      ),
    ),
  );

  // Widget ช่วยสร้าง TextField
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
        fillColor: Colors.grey[50], // สีพื้นหลังอ่อนลง
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // ปรับให้โค้งมนขึ้น
          borderSide: BorderSide.none, // ไม่มีเส้นขอบ
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!), // เส้นขอบสีเทาอ่อน
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF34C759),
            width: 2,
          ), // เส้นขอบสีเขียวเมื่อโฟกัส
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // Widget ช่วยสร้างปุ่มเลือกเวลา
  Widget _buildTimePickerButton(bool isOpen) {
    final time = isOpen ? openTime : closeTime;
    return Container(
      width: double.infinity, // ให้ปุ่มยืดเต็มความกว้าง
      child: OutlinedButton.icon(
        icon: const Icon(Icons.access_time, color: Color(0xFF34C759)),
        label: Text(
          formatTime(time),
          style: const TextStyle(color: Colors.black87),
        ),
        onPressed: () => _pickTime(isOpen),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!), // เส้นขอบสีเทาอ่อน
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: Colors.black, // สี icon และ text
        ),
      ),
    );
  }
}
