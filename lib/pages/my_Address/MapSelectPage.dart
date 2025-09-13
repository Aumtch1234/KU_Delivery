import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();

  // TODO: อย่าลืมเปลี่ยนเป็น API Key ของคุณ
  final String apiKey = "";

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
  bool _showLocationInfo = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
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
    _searchController.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar("กรุณาเปิด Location Service เพื่อใช้งาน");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar("ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackbar("กรุณาอนุญาต Location ใน Settings ของเครื่อง");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      _showSnackbar("ไม่สามารถหาตำแหน่งปัจจุบันได้");
    }
  }

  // ฟังก์ชันค้นหาสถานที่ใช้ Google Places API
  Future<List<String>> fetchPlaceSuggestions(String input) async {
    if (input.isEmpty || apiKey.isEmpty) {
      return [];
    }

    try {
      Uri url = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": input,
          "language": "th",
          "key": apiKey,
          "components": "country:th",
        },
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['status'] == 'OK') {
          final predictions = result['predictions'] as List;
          return predictions.map((p) => p['description'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  // ฟังก์ชันแปลงชื่อสถานที่ให้เป็นพิกัด LatLng
  Future<LatLng?> fetchLatLngFromPlaceName(String description) async {
    if (apiKey.isEmpty) return null;
    
    try {
      final url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$description&inputtype=textquery&fields=geometry&key=$apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK' && result['candidates'].isNotEmpty) {
          final location = result['candidates'][0]['geometry']['location'] as Map<String, dynamic>;
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching location: $e');
      return null;
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
      _showLocationInfo = true;
      _markers.clear();
    });

    // ขยาย bottom sheet เมื่อเลือกตำแหน่งใหม่
    _bottomSheetController.animateTo(
      0.35,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    final customIcon = await _createCustomMarkerIcon();
    _markers.add(
      Marker(
        markerId: MarkerId('selected_location'),
        position: position,
        icon: customIcon,
      ),
    );
    
    setState(() {});

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

  void _confirmLocation() {
    if (_selectedPosition != null) {
      print('Selected Location:');
      print('Address: $_selectedAddress');
      print('Coordinates: ${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}');
      
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
          margin: EdgeInsets.all(16),
        ),
      );
      
      Navigator.pop(context, _selectedPosition);
    } else {
      _showSnackbar("กรุณาเลือกตำแหน่งบนแผนที่ก่อน");
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          GoogleMap(
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
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top controls
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header with back button and search
                  Container(
                    margin: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back_ios_new, size: 20),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildSearchBar(),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _useCurrentLocation,
                            icon: Icon(Icons.my_location_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Instructions (แสดงเฉพาะตอนยังไม่เลือกตำแหน่ง)
                  if (!_showLocationInfo)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_rounded, color: Color(0xFF34C759), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'แตะบนแผนที่เพื่อเลือกตำแหน่ง',
                              style: TextStyle(
                                color: Color(0xFF34C759),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Draggable Bottom Sheet สำหรับแสดงข้อมูลตำแหน่ง
          if (_showLocationInfo)
            DraggableScrollableSheet(
              controller: _bottomSheetController,
              initialChildSize: 0.35,
              minChildSize: 0.1,
              maxChildSize: 0.6,
              snap: true,
              snapSizes: [0.1, 0.35, 0.6],
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location info header
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: Color(0xFF34C759), size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ตำแหน่งที่เลือก',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  ),
                                  if (_isLoading)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                                      ),
                                    ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Address information
                              if (_selectedAddress.isNotEmpty) ...[
                                Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 12),
                              ],

                              // District info
                              if (_selectedSubDistrict.isNotEmpty || _selectedDistrict.isNotEmpty || _selectedProvince.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (_selectedSubDistrict.isNotEmpty)
                                      _buildInfoChip('ต. ${_selectedSubDistrict}'),
                                    if (_selectedDistrict.isNotEmpty)
                                      _buildInfoChip('อ. ${_selectedDistrict}'),
                                    if (_selectedProvince.isNotEmpty)
                                      _buildInfoChip('จ. ${_selectedProvince}'),
                                    if (_selectedPostalCode.isNotEmpty)
                                      _buildInfoChip(_selectedPostalCode),
                                  ],
                                ),
                                SizedBox(height: 12),
                              ],

                              // Coordinates
                              if (_selectedPosition != null) ...[
                                Text(
                                  'พิกัด: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey.shade600,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('ยกเลิก'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _selectedPosition != null && !_isLoading ? _confirmLocation : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF34C759),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text('ยืนยันตำแหน่ง'),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TypeAheadField<String>(
        controller: _searchController,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'ค้นหาสถานที่...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF34C759), size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        controller.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(fontSize: 14),
          );
        },
        suggestionsCallback: (pattern) => fetchPlaceSuggestions(pattern),
        itemBuilder: (context, suggestion) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(Icons.location_on_rounded, color: Color(0xFF34C759), size: 20),
              title: Text(
                suggestion,
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
        emptyBuilder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                _useCurrentLocation();
                FocusScope.of(context).unfocus();
              },
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(Icons.my_location, color: Color(0xFF34C759), size: 20),
                title: Text("ใช้ตำแหน่งปัจจุบันของคุณ", style: TextStyle(fontSize: 14)),
              ),
            ),
          );
        },
        onSelected: (suggestion) async {
          final location = await fetchLatLngFromPlaceName(suggestion);
          if (location != null) {
            mapController.animateCamera(
              CameraUpdate.newLatLngZoom(location, 16.0),
            );
            _onMapTapped(location);
            _searchController.text = suggestion;
            FocusScope.of(context).unfocus();
          }
        },
        decorationBuilder: (context, child) {
          return Material(
            type: MaterialType.card,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF34C759).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF34C759).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF34C759),
        ),
      ),
    );
  }
}