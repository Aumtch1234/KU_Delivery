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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery/pages/myMarket/SelectLocationPage.dart';

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
  String? _imageUrl;
  double? latitude;
  double? longitude;

  bool _isLoading = false;
  int? _marketId;
  GoogleMapController? _previewMapController;

  final primaryColor = const Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _previewMapController?.dispose();
    super.dispose();
  }

  /// ฟังก์ชันสำหรับดึงข้อมูลร้านค้าเดิมมาแสดง
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
          latitude = market['latitude'];
          longitude = market['longitude'];
        });
      } else {
        throw Exception('ไม่พบข้อมูลร้านค้า กรุณาสมัครร้านค้าก่อน');
      }
    } catch (e) {
      print('Error loading market: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'เกิดข้อผิดพลาด',
        desc: 'ไม่สามารถโหลดข้อมูลร้านค้าได้: ${e.toString()}',
        btnOkOnPress: () {},
      ).show();
    }
    setState(() => _isLoading = false);
  }

  /// แปลง String เวลาเป็น TimeOfDay
  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// เลือกรูปภาพจาก Gallery
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  /// ฟังก์ชันสำหรับเลือกเวลาเปิด/ปิดร้าน
  void _pickTime(bool isOpening) {
    picker.DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      currentTime: DateTime.now(),
      theme: picker.DatePickerTheme(
        backgroundColor: Colors.white,
        itemStyle: const TextStyle(color: Colors.black, fontSize: 18),
        doneStyle: TextStyle(
          color: primaryColor,
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

  /// จัดรูปแบบเวลาเพื่อแสดงผล
  String _formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  /// ส่งข้อมูลเพื่ออัปเดต
  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        openTime == null ||
        closeTime == null ||
        latitude == null ||
        longitude == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'กรอกข้อมูลไม่ครบ',
        desc: 'โปรดกรอกข้อมูลที่จำเป็นและเลือกตำแหน่งร้านค้าให้ครบถ้วน',
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
      latitude: latitude!,
      longitude: longitude!,
      imageFile: _image,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      await AuthService().refreshUserToken();
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'อัปเดตข้อมูลสำเร็จ',
        desc: 'ข้อมูลร้านค้าของคุณได้รับการอัปเดตแล้ว',
        btnOkOnPress: () => Navigator.pop(context, true),
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'เกิดข้อผิดพลาด',
        desc: result['body']['message'] ?? 'ไม่สามารถอัปเดตข้อมูลร้านค้าได้',
        btnOkOnPress: () {},
      ).show();
    }
  }

  /// Widget สำหรับสร้างส่วนแสดงแผนที่เล็กๆ
  Widget _buildLocationPreview() {
    LatLng currentLatLng;
    double currentZoom;

    if (latitude != null && longitude != null) {
      currentLatLng = LatLng(latitude!, longitude!);
      currentZoom = 16;
    } else {
      currentLatLng = const LatLng(13.7563, 100.5018); // พิกัดเริ่มต้นกรุงเทพฯ
      currentZoom = 12;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('แก้ไขตำแหน่งร้านบนแผนที่'),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                key: ValueKey('$latitude-$longitude'),
                initialCameraPosition: CameraPosition(
                  target: currentLatLng,
                  zoom: currentZoom,
                ),
                markers: latitude != null && longitude != null
                    ? {
                        Marker(
                          markerId: const MarkerId('selected_shop_location'),
                          position: currentLatLng,
                        ),
                      }
                    : {},
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                onMapCreated: (controller) {
                  _previewMapController = controller;
                },
              ),
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
                        _previewMapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(selected, 16),
                        );
                      }
                    },
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latitude == null ? 'เลือกตำแหน่งร้าน' : 'แก้ไขตำแหน่ง',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (latitude != null && longitude != null)
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
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'แก้ไขข้อมูลร้านค้า',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          : (_imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (_image == null && _imageUrl == null)
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
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('ข้อมูลร้านค้า'),
                      _buildTextField(_nameController, 'ชื่อร้านค้า'),
                      const SizedBox(height: 12),
                      _buildTextField(_descController, 'คำอธิบายร้าน',
                          maxLines: 3),
                    ],
                  ),
                ),
              ),

              // ส่วนเวลาทำการ
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                                const Text('เวลาเปิด',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                                _buildTimePickerButton(true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('เวลาปิด',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
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

              // ส่วนเลือกตำแหน่งร้านบนแผนที่
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLocationPreview(),
                ),
              ),

              // ปุ่มบันทึกการเปลี่ยนแปลง
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  foregroundColor: Colors.white,
                ),
                child: const Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget ช่วยสร้าง Label
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: primaryColor,
          ),
        ),
      );

  /// Widget ช่วยสร้าง TextField
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
        fillColor: Colors.grey[50],
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Widget ช่วยสร้างปุ่มเลือกเวลา
  Widget _buildTimePickerButton(bool isOpen) {
    final time = isOpen ? openTime : closeTime;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.access_time, color: primaryColor),
        label: Text(
          _formatTime(time),
          style: const TextStyle(color: Colors.black87),
        ),
        onPressed: () => _pickTime(isOpen),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}