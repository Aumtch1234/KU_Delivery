import 'dart:io';
import 'package:delivery/APIs/Markets/AddMarketAPI.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:delivery/pages/myMarket/SelectLocationPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RegisterShopPage extends StatefulWidget {
  @override
  _RegisterShopPageState createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Time variables
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  // Image variables
  File? _image;

  // Location variables
  double? latitude;
  double? longitude;

  // UI state
  bool _isLoading = false;
  GoogleMapController? _previewMapController;

  // Colors & Theme
  static const primaryColor = Color(0xFF2E7D32); // Darker green
  static const secondaryColor = Color(0xFF4CAF50);
  static const accentColor = Color(0xFFE8F5E8);

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _previewMapController?.dispose();
    super.dispose();
  }

  /// เลือกรูปภาพจาก Gallery
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      _showErrorDialog('ไม่สามารถเลือกรูปภาพได้');
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
        doneStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        cancelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        headerColor: accentColor,
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
  String formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  /// Validation function
  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showWarningDialog('กรุณาระบุชื่อร้านค้า');
      return false;
    }
    if (_image == null) {
      _showWarningDialog('กรุณาเลือกรูปภาพร้าน');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showWarningDialog('กรุณาระบุที่อยู่ร้านค้า');
      return false;
    }
    if (openTime == null || closeTime == null) {
      _showWarningDialog('กรุณาเลือกเวลาเปิด-ปิดร้าน');
      return false;
    }
    if (latitude == null || longitude == null) {
      _showWarningDialog('กรุณาเลือกตำแหน่งร้านค้าบนแผนที่');
      return false;
    }
    return true;
  }

  /// ส่งข้อมูลเพื่อสมัครร้าน
  Future<void> _submit() async {
    if (!_validateForm()) return;

    final user = AuthService().currentUser;
    if (user == null || user['user_id'] == null) {
      _showErrorDialog('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AddMarketApiMultipart(
        ownerId: user['user_id'],
        shopName: _nameController.text.trim(),
        shopDesc: _descController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        imageFile: _image!,
        latitude: latitude!,
        longitude: longitude!,
        openTime:
            '${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}',
        closeTime:
            '${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}',
      );

      if (result['statusCode'] == 200) {
        await AuthService().refreshUserToken();
        _showSuccessDialog();
      } else {
        _showErrorDialog(
          result['body']['message'] ?? 'ไม่สามารถสมัครร้านค้าได้',
        );
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการส่งข้อมูล: ${e.toString()}');
    }

    setState(() => _isLoading = false);
  }

  /// Dialog helper functions
  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'สมัครร้านค้าสำเร็จ',
      desc: 'ระบบจะพาคุณกลับหน้าหลัก',
      btnOkColor: primaryColor,
      btnOkOnPress: () => Navigator.pop(context),
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'เกิดข้อผิดพลาด',
      desc: message,
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();
  }

  void _showWarningDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'กรอกข้อมูลไม่ครบ',
      desc: message,
      btnOkColor: Colors.orange,
      btnOkOnPress: () {},
    ).show();
  }

  /// Widget สำหรับสร้างส่วนแสดงแผนที่เล็กๆ
  Widget _buildLocationPreview() {
    LatLng currentLatLng;
    double currentZoom;

    if (latitude != null && longitude != null) {
      currentLatLng = LatLng(latitude!, longitude!);
      currentZoom = 16;
    } else {
      currentLatLng = const LatLng(13.7563, 100.5018);
      currentZoom = 12;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          '📍 ตำแหน่งร้านค้า',
          'เลือกตำแหน่งที่ตั้งร้านค้าบนแผนที่',
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                          infoWindow: InfoWindow(
                            title: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'ร้านค้าของคุณ',
                            snippet: 'ตำแหน่งที่เลือก',
                          ),
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                latitude == null
                                    ? 'เลือกตำแหน่งร้าน'
                                    : 'แก้ไขตำแหน่ง',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
        if (latitude != null && longitude != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.place, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'พิกัด: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          title: const Text(
            'สมัครเป็นร้านค้า',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header gradient
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: Center(child: _buildImagePicker()),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 20),
                    _buildContactInfoSection(),
                    const SizedBox(height: 20),
                    _buildOperatingHoursSection(),
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget สำหรับเลือกรูปภาพ
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: _image != null
              ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
              : null,
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(
                    'เพิ่มรูปร้าน',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.edit, color: Colors.white, size: 24),
                ),
              ),
      ),
    );
  }

  /// ส่วนข้อมูลพื้นฐาน
  Widget _buildBasicInfoSection() {
    return _buildSection(
      '🏪 ข้อมูลพื้นฐาน',
      'รายละเอียดทั่วไปเกี่ยวกับร้านค้าของคุณ',
      [
        _buildTextField(
          _nameController,
          'ชื่อร้านค้า',
          Icons.store,
          'กรอกชื่อร้านค้าของคุณ',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _descController,
          'คำอธิบายร้าน',
          Icons.description,
          '',
          maxLines: 3,
        ),
      ],
    );
  }

  /// ส่วนข้อมูลติดต่อ
  Widget _buildContactInfoSection() {
    return _buildSection(
      '📞 ข้อมูลติดต่อ',
      'ข้อมูลสำหรับติดต่อและที่อยู่ร้านค้า',
      [
        _buildTextField(
          _addressController,
          'ที่อยู่ร้านค้า',
          Icons.home,
          'บ้านเลขที่ ซอย ถนน แขวง เขต จังหวัด',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _phoneController,
          'เบอร์โทรศัพท์',
          Icons.phone,
          'หมายเลขโทรศัพท์สำหรับติดต่อ',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  /// ส่วนเวลาทำการ
  Widget _buildOperatingHoursSection() {
    return _buildSection('⏰ เวลาทำการ', 'กำหนดเวลาเปิด-ปิดร้านค้าของคุณ', [
      Row(
        children: [
          Expanded(child: _buildTimePickerCard('เวลาเปิด', openTime, true)),
          const SizedBox(width: 16),
          Expanded(child: _buildTimePickerCard('เวลาปิด', closeTime, false)),
        ],
      ),
    ]);
  }

  /// ส่วนตำแหน่งที่ตั้ง
  Widget _buildLocationSection() {
    return _buildSection('', '', [
      _buildLocationPreview(),
    ], padding: EdgeInsets.zero);
  }

  /// Widget สำหรับสร้าง Section
  Widget _buildSection(
    String title,
    String subtitle,
    List<Widget> children, {
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              _buildSectionHeader(title, subtitle),
              const SizedBox(height: 20),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  /// Widget สำหรับ Section Header
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  /// Widget สำหรับ TextField ที่สวยงาม
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget สำหรับ Time Picker Card
  Widget _buildTimePickerCard(String label, TimeOfDay? time, bool isOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickTime(isOpen),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  formatTime(time),
                  style: TextStyle(
                    fontSize: 16,
                    color: time != null ? Colors.black87 : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ปุ่มสมัคร
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submit,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'ยืนยันสมัครร้านค้า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
