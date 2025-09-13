import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapSelectionPage extends StatefulWidget {
  final LatLng? initialPosition;

  const MapSelectionPage({
    Key? key,
    this.initialPosition,
  }) : super(key: key);

  @override
  _MapSelectionPageState createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage>
    with TickerProviderStateMixin {
  late GoogleMapController mapController;
  late AnimationController _animationController;
  late AnimationController _markerController;
  late AnimationController _searchController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _markerAnimation;
  late Animation<double> _searchAnimation;

  // Controllers
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map Variables
  LatLng _currentPosition = LatLng(17.1614, 104.1475); // เชียงเครือ สกลนคร
  Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  String _selectedSubDistrict = '';
  String _selectedDistrict = '';
  String _selectedProvince = '';
  String _selectedPostalCode = '';
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _markerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerController,
        curve: Curves.elasticOut,
      ),
    );
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition!;
    }
    
    _getCurrentLocation();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _markerController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
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
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _isLoading = true;
      _selectedPosition = position;
      _markers.clear();
    });

    final customIcon = await _createCustomMarkerIcon();
    _markers.add(
      Marker(
        markerId: MarkerId('selected_location'),
        position: position,
        icon: customIcon,
        infoWindow: InfoWindow(
          title: '📍 ตำแหน่งที่เลือก',
          snippet: 'กำลังโหลดข้อมูลที่อยู่...',
        ),
      ),
    );
    
    setState(() {});
    _markerController.forward();

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        
        String fullAddress = _buildFullAddress(place);
        
        setState(() {
          _selectedAddress = fullAddress;
          _selectedSubDistrict = place.subLocality ?? place.locality ?? '';
          _selectedDistrict = place.subAdministrativeArea ?? '';
          _selectedProvince = place.administrativeArea ?? '';
          _selectedPostalCode = place.postalCode ?? '';
          
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId('selected_location'),
              position: position,
              icon: customIcon,
              infoWindow: InfoWindow(
                title: '📍 ${_selectedSubDistrict}',
                snippet: '${_selectedDistrict}, ${_selectedProvince} ${_selectedPostalCode}',
              ),
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'ไม่สามารถดึงข้อมูลที่อยู่ได้';
          _isLoading = false;
        });
      }
      print('Error getting address: $e');
    }
  }

  String _buildFullAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.name != null && place.name!.isNotEmpty) {
      addressParts.add(place.name!);
    }
    if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add('ต.${place.subLocality!}');
    }
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      addressParts.add('อ.${place.subAdministrativeArea!}');
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add('จ.${place.administrativeArea!}');
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    
    return addressParts.join(' ');
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty && mounted) {
        List<Map<String, dynamic>> results = [];
        
        for (Location loc in locations.take(5)) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              loc.latitude,
              loc.longitude,
            );
            
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              results.add({
                'position': LatLng(loc.latitude, loc.longitude),
                'address': _buildFullAddress(place),
                'subDistrict': place.subLocality ?? place.locality ?? '',
                'district': place.subAdministrativeArea ?? '',
                'province': place.administrativeArea ?? '',
                'postalCode': place.postalCode ?? '',
              });
            }
          } catch (e) {
            print('Error processing location: $e');
          }
        }
        
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        _searchController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      print('Error searching location: $e');
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    LatLng position = result['position'];
    
    setState(() {
      _selectedPosition = position;
      _selectedAddress = result['address'];
      _selectedSubDistrict = result['subDistrict'];
      _selectedDistrict = result['district'];
      _selectedProvince = result['province'];
      _selectedPostalCode = result['postalCode'];
      _searchResults.clear();
      _searchTextController.clear();
    });
    
    _searchFocusNode.unfocus();
    _searchController.reverse();
    
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16.0),
    );
    
    _onMapTapped(position);
  }

  void _confirmLocation() {
    if (_selectedPosition != null) {
      // บันทึกข้อมูลตำแหน่งที่เลือก (สามารถทำการบันทึกลง Database หรือ SharedPreferences ได้)
      print('Selected Location:');
      print('Address: $_selectedAddress');
      print('Coordinates: ${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}');
      
      // แสดงข้อความยืนยัน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('บันทึกตำแหน่งเรียบร้อยแล้ว'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // กลับไปหน้าก่อนหน้าโดยไม่ส่งค่า
      Navigator.pop(context);
    }
  }

  void _useCurrentLocation() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();
    
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 16.0),
    );
    
    _onMapTapped(_currentPosition);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF34C759),
              Color(0xFF30D158),
              Color(0xFF32D74B),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, screenHeight * _slideAnimation.value),
                          child: child,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 3,
                              blurRadius: 20,
                              offset: Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            _buildInstructions(),
                            // ขยายขนาด Map ให้เต็มพื้นที่มากขึ้น
                            Container(
                              height: screenHeight * 0.5, // เพิ่มขนาดเป็น 50% ของหน้าจอ
                              child: _buildMap(),
                            ),
                            _buildLocationInfo(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Search Results Overlay - ปรับขนาดให้กว้างขึ้น
              if (_searchResults.isNotEmpty)
                _buildSearchResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'เลือกตำแหน่งที่อยู่',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _useCurrentLocation,
                icon: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                tooltip: 'ใช้ตำแหน่งปัจจุบัน',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchTextController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'ค้นหาที่อยู่... เช่น เชียงเครือ สกลนคร',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Color(0xFF34C759),
                size: 22,
              ),
              suffixIcon: _isSearching
                  ? Container(
                      padding: EdgeInsets.all(12),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                      ),
                    )
                  : _searchTextController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchTextController.clear();
                            setState(() {
                              _searchResults.clear();
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(fontSize: 14),
            onSubmitted: _searchLocation,
            onChanged: (value) {
              if (value.length > 2) {
                Future.delayed(Duration(milliseconds: 500), () {
                  if (_searchTextController.text == value) {
                    _searchLocation(value);
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: 120, // ปรับตำแหน่งให้เหมาะสม
      left: 12, // ลดระยะขอบ
      right: 12, // ลดระยะขอบ
      child: ScaleTransition(
        scale: _searchAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4, // เพิ่มความสูงสูงสุด
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.all(8),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // เพิ่ม padding
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.place_rounded,
                    color: Color(0xFF34C759),
                    size: 20,
                  ),
                ),
                title: Text(
                  result['address'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${result['district']}, ${result['province']} ${result['postalCode']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: () => _selectSearchResult(result),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF34C759).withOpacity(0.05),
                Color(0xFF30D158).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF34C759).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF34C759).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.touch_app_rounded, color: Color(0xFF34C759), size: 16),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'แตะบนแผนที่หรือค้นหาเพื่อเลือกตำแหน่งที่ต้องการ',
                  style: TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12), // ลด margin
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 15,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            style: '''[
              {
                "featureType": "poi",
                "stylers": [{"visibility": "simplified"}]
              }
            ]''',
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          children: [
            if (_selectedPosition != null) ...[
              ScaleTransition(
                scale: _markerAnimation,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF34C759).withOpacity(0.05),
                        Color(0xFF30D158).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF34C759).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF34C759),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ตำแหน่งที่เลือก',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF34C759),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12),
                      
                      if (_selectedAddress.isNotEmpty) ...[
                        _buildAddressRow(Icons.home_rounded, _selectedAddress),
                        SizedBox(height: 8),
                      ],
                      
                      if (_selectedSubDistrict.isNotEmpty || _selectedDistrict.isNotEmpty) ...[
                        Row(
                          children: [
                            if (_selectedSubDistrict.isNotEmpty) ...[
                              _buildInfoChip('ต. ${_selectedSubDistrict}', Color(0xFF34C759)),
                              SizedBox(width: 6),
                            ],
                            if (_selectedDistrict.isNotEmpty) ...[
                              _buildInfoChip('อ. ${_selectedDistrict}', Color(0xFF30D158)),
                              SizedBox(width: 6),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                      
                      if (_selectedProvince.isNotEmpty || _selectedPostalCode.isNotEmpty) ...[
                        Row(
                          children: [
                            if (_selectedProvince.isNotEmpty) ...[
                              _buildInfoChip('จ. ${_selectedProvince}', Color(0xFF32D74B)),
                              SizedBox(width: 6),
                            ],
                            if (_selectedPostalCode.isNotEmpty) ...[
                              _buildInfoChip(_selectedPostalCode, Color(0xFF007AFF)),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                      
                      _buildAddressRow(
                        Icons.my_location_rounded,
                        'พิกัด: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                        isCoordinate: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, size: 18),
                    label: Text('ยกเลิก'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedPosition != null && !_isLoading ? _confirmLocation : null,
                    icon: Icon(Icons.check_circle_rounded, size: 18),
                    label: Text('ยืนยันตำแหน่ง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String text, {bool isCoordinate = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 16,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isCoordinate ? 11 : 13,
              color: isCoordinate ? Colors.grey.shade600 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}