import 'package:delivery/APIs/Users/AddAddressAPI.dart';
import 'package:delivery/APIs/Users/models/address.dart';
import 'package:delivery/pages/my_Address/MapSelectPage.dart';
import 'package:delivery/pages/my_Address/models.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryAddressForm extends StatefulWidget {
  final ShippingAddress? address; // ถ้าไม่ส่ง => เพิ่มใหม่

  DeliveryAddressForm({this.address});

  @override
  _DeliveryAddressFormState createState() => _DeliveryAddressFormState();
}

class _DeliveryAddressFormState extends State<DeliveryAddressForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Location Variables
  LatLng _currentPosition = LatLng(13.7563, 100.5018); // Bangkok default
  double? _selectedLat;
  double? _selectedLng;
  String _selectedLocationText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _getCurrentLocation();

    // ถ้ามี address ส่งมา => เติมลง controller
    if (widget.address != null) {
      _nameController.text = widget.address!.name;
      _phoneController.text = widget.address!.phone;
      _addressController.text = widget.address!.address;
      _districtController.text = widget.address!.district;
      _cityController.text = widget.address!.province;
      _postalCodeController.text = widget.address!.postalCode;
      _notesController.text = widget.address!.notes ?? '';
      _selectedLat = widget.address!.latitude;
      _selectedLng = widget.address!.longitude;
      _selectedLocationText = widget.address!.address;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _openMapSelection() async {
    // In real implementation, you would navigate to MapSelectionPage
    // For this demo, we'll simulate the map selection
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapSelectionPage(initialPosition: _currentPosition),
      ),
    );

    if (result != null) {
      _handleLocationSelection(result);
    }
  }

  void _handleLocationSelection(Map<String, dynamic> locationData) {
    setState(() {
      _selectedLat = locationData['latitude'];
      _selectedLng = locationData['longitude'];
      _selectedLocationText = locationData['address'] ?? '';
      _addressController.text = locationData['address'] ?? '';
      _districtController.text = locationData['district'] ?? '';
      _cityController.text = locationData['province'] ?? '';
      _postalCodeController.text = locationData['postalCode'] ?? '';
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLat == null || _selectedLng == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("กรุณาเลือกตำแหน่งบนแผนที่")));
        return;
      }

      DeliveryAddress address = DeliveryAddress(
        id: widget.address?.id,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        district: _districtController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        notes: _notesController.text,
        latitude: _selectedLat!,
        longitude: _selectedLng!,
      );

      print("📦 ส่งข้อมูล Address -> ${address.toJson()}");

      Map<String, dynamic> result;

      if (widget.address != null) {
        result = await DeliveryAddressAPI.updateAddress(
          widget.address!.id,
          address,
        );
      } else {
        result = await DeliveryAddressAPI.addAddress(address);
      }

      print("✅ API Result -> $result");

      if (result["success"] == true) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF34C759), size: 24),
                SizedBox(width: 8),
                Text('บันทึกสำเร็จ!', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text("ข้อมูลที่อยู่ถูกบันทึกเรียบร้อยแล้ว"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, "/myaddress");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF34C759),
                ),
                child: Text("ตกลง", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("บันทึกไม่สำเร็จ: ${result['message']}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF34C759), Color(0xFF30D158)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.white, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'ข้อมูลที่อยู่จัดส่ง',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form Container
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 3,
                        blurRadius: 15,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAnimatedFormField(
                                    controller: _nameController,
                                    label: 'ชื่อผู้รับ',
                                    icon: Icons.person,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'กรุณาระบุชื่อผู้รับ'
                                        : null,
                                    delay: 200,
                                  ),
                                  SizedBox(height: 16),
                                  _buildAnimatedFormField(
                                    controller: _phoneController,
                                    label: 'เบอร์โทรศัพท์',
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'กรุณาระบุเบอร์โทรศัพท์'
                                        : null,
                                    delay: 300,
                                  ),
                                  SizedBox(height: 16),
                                  _buildAnimatedFormField(
                                    controller: _addressController,
                                    label: 'ที่อยู่',
                                    icon: Icons.home,
                                    maxLines: 2,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'กรุณาระบุที่อยู่'
                                        : null,
                                    delay: 400,
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAnimatedFormField(
                                          controller: _districtController,
                                          label: 'เขต/อำเภอ',
                                          icon: Icons.location_city,
                                          validator: (value) =>
                                              value?.isEmpty ?? true
                                              ? 'กรุณาระบุเขต/อำเภอ'
                                              : null,
                                          delay: 500,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: _buildAnimatedFormField(
                                          controller: _cityController,
                                          label: 'จังหวัด',
                                          icon: Icons.business,
                                          validator: (value) =>
                                              value?.isEmpty ?? true
                                              ? 'กรุณาระบุจังหวัด'
                                              : null,
                                          delay: 600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  _buildAnimatedFormField(
                                    controller: _postalCodeController,
                                    label: 'รหัสไปรษณีย์',
                                    icon: Icons.markunread_mailbox,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'กรุณาระบุรหัสไปรษณีย์'
                                        : null,
                                    delay: 700,
                                  ),
                                  SizedBox(height: 16),
                                  _buildAnimatedFormField(
                                    controller: _notesController,
                                    label: 'หมายเหตุเพิ่มเติม (ไม่จำเป็น)',
                                    icon: Icons.note_add,
                                    maxLines: 3,
                                    delay: 800,
                                  ),
                                  SizedBox(height: 24),

                                  // Map Selection Button
                                  _buildMapSelectionButton(),

                                  // Location Info
                                  if (_selectedLat != null &&
                                      _selectedLng != null)
                                    _buildLocationInfo(),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Submit Button
                        Container(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF34C759),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'บันทึกข้อมูล',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required int delay,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 13),
                prefixIcon: Icon(icon, color: Color(0xFF34C759), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF34C759), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          );
        }
        return Container(height: maxLines == 1 ? 50 : 70);
      },
    );
  }

  Widget _buildMapSelectionButton() {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: 900)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 400),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF30D158)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF34C759).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMapSelection,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'เลือกตำแหน่งบนแผนที่',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Container(height: 48);
      },
    );
  }

  Widget _buildLocationInfo() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF34C759).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF34C759).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF34C759), size: 18),
              SizedBox(width: 6),
              Text(
                'ตำแหน่งที่เลือก',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF34C759),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          if (_selectedLocationText.isNotEmpty) ...[
            Text(
              _selectedLocationText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            SizedBox(height: 4),
          ],
          Text(
            'พิกัด: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Container(
            height: 120,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_selectedLat!, _selectedLng!),
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('selected'),
                  position: LatLng(_selectedLat!, _selectedLng!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              onMapCreated: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
