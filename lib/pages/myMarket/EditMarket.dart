import 'dart:io';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:delivery/APIs/Markets/UpdateMarketApi.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery/pages/myMarket/SelectLocationPage.dart';

class EditShopPage extends StatefulWidget {
  @override
  _EditShopPageState createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
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
  String? _imageUrl;

  // Location variables
  double? latitude;
  double? longitude;

  // UI state
  bool _isLoading = false;
  int? _marketId;
  GoogleMapController? _previewMapController;

  // Colors & Theme
  static const primaryColor = Color(0xFF2E7D32); // Darker green
  static const secondaryColor = Color(0xFF4CAF50);
  static const accentColor = Color(0xFFE8F5E8);

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
          _addressController.text = market['address'] ?? '';
          _phoneController.text = market['phone'] ?? '';
          openTime = _parseTime(market['open_time']);
          closeTime = _parseTime(market['close_time']);
          _marketId = market['market_id'];
          _imageUrl = market['shop_logo_url'];
          latitude = market['latitude'];
          longitude = market['longitude'];
        });
      } else {
        _showErrorDialog('ไม่พบข้อมูลร้านค้า กรุณาสมัครร้านค้าก่อน');
      }
    } catch (e) {
      print('Error loading market: $e');
      _showErrorDialog('ไม่สามารถโหลดข้อมูลร้านค้าได้: ${e.toString()}');
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
  String _formatTime(TimeOfDay? time) =>
      time == null ? 'เลือกเวลา' : time.format(context);

  /// Validation function
  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showWarningDialog('กรุณาระบุชื่อร้านค้า');
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
    if (_marketId == null) {
      _showErrorDialog('ไม่พบข้อมูลร้านค้า โปรดลองใหม่อีกครั้ง');
      return false;
    }
    return true;
  }

  /// ส่งข้อมูลเพื่ออัปเดต
  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final result = await UpdateMarketApiMultipart(
        marketId: _marketId!,
        shopName: _nameController.text.trim(),
        shopDesc: _descController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),     // ✅ ส่ง phone
        openTime:
            '${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}',
        closeTime:
            '${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}',
        latitude: latitude!,
        longitude: longitude!,
        imageFile: _image,
      );

      if (result['statusCode'] == 200) {
        await AuthService().refreshUserToken();
        _showSuccessDialog();
      } else {
        _showErrorDialog(
          result['body']['message'] ?? 'ไม่สามารถอัปเดตข้อมูลร้านค้าได้',
        );
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการอัปเดตข้อมูล');
    }

    setState(() => _isLoading = false);
  }

  /// Dialog helper functions
  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'อัปเดตข้อมูลสำเร็จ',
      desc: 'ข้อมูลร้านค้าของคุณได้รับการอัปเดตแล้ว',
      btnOkColor: primaryColor,
      btnOkOnPress: () => Navigator.pop(context, true),
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
            'แก้ไขข้อมูลร้านค้า',
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
              : (_imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null),
        ),
        child: (_image == null && _imageUrl == null)
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
      'ข้อมูลร้านค้าของคุณ',
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
                  _formatTime(time),
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

  /// ปุ่มบันทึก
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
                Icon(Icons.save, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'บันทึกการเปลี่ยนแปลง',
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
