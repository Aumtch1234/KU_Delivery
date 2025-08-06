import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({Key? key}) : super(key: key);

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? _selectedLocation;
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  // ให้พิกัดเริ่มต้นเป็นกรุงเทพฯ เพื่อการแสดงผลที่เหมาะสม
  static const LatLng _defaultInitialPosition = LatLng(13.7563, 100.5018);

  // TODO: อย่าลืมเปลี่ยนเป็น API Key ของคุณ
  final String apiKey = "AIzaSyC80ckycu48M9WQ8Lb8Fk0wtIhkHFN-Nb4";

  // ใช้เพื่อแสดง Marker ของตำแหน่งปัจจุบัน
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ฟังก์ชันหาพิกัดปัจจุบันของผู้ใช้
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar("กรุณาเปิด Location Service เพื่อใช้งาน");
      return;
    }

    permission = await Geolocator.checkPermission();
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

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentPosition = LatLng(position.latitude, position.longitude);
      _updateMapAndMarker(currentPosition);
    } catch (e) {
      _showSnackbar("ไม่สามารถหาตำแหน่งปัจจุบันได้");
    }
  }

  // ฟังก์ชันค้นหาสถานที่
  Future<List<String>> fetchPlaceSuggestions(String input) async {
    print('fetchPlaceSuggestions called with input: $input'); // เพิ่มบรรทัดนี้

    if (input.isEmpty) {
      return [];
    }

    // ใช้ try-catch เพื่อจับทุกอย่าง
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

      print('Calling API URL: $url');
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('API Response Body: $result');

        if (result['status'] == 'OK') {
          final predictions = result['predictions'] as List;
          return predictions.map((p) => p['description'] as String).toList();
        } else {
          print('API status is not OK. Status: ${result['status']}');
          return [];
        }
      } else {
        print('HTTP request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  // ฟังก์ชันแปลงชื่อสถานที่ให้เป็นพิกัด LatLng
  Future<LatLng?> fetchLatLngFromPlaceName(String description) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$description&inputtype=textquery&fields=geometry&key=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK' && result['candidates'].isNotEmpty) {
        final location =
            result['candidates'][0]['geometry']['location']
                as Map<String, dynamic>;
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  // ฟังก์ชันอัปเดตแผนที่และ Marker
  void _updateMapAndMarker(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: newLocation,
          infoWindow: const InfoWindow(title: 'ตำแหน่งที่เลือก'),
        ),
      );
    });
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 16));
  }

  // ฟังก์ชันยืนยันตำแหน่ง
  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      _showSnackbar("กรุณาเลือกตำแหน่งบนแผนที่ก่อน");
    }
  }

  // ฟังก์ชันแสดง Snackbar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "เลือกตำแหน่งร้าน",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF34C759),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: _defaultInitialPosition,
              zoom: 12,
            ),
            onTap: (LatLng pos) {
              _updateMapAndMarker(pos);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false, // ซ่อนปุ่มซูมเพื่อความสวยงาม
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TypeAheadField<String>(
                controller: _searchController, // ใช้ controller เดิม
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller, // ใช้ controller ที่มาจาก builder
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'ค้นหาสถานที่...',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF34C759),
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                controller.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                  );
                },
                suggestionsCallback: (pattern) =>
                    fetchPlaceSuggestions(pattern), // ใช้ (pattern)
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFF34C759),
                    ),
                    title: Text(suggestion),
                  );
                },
                emptyBuilder: (context) {
                  return InkWell(
                    onTap: () {
                      _getCurrentLocation();
                      FocusScope.of(context).unfocus(); // ซ่อนคีย์บอร์ด
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.my_location,
                        color: Color(0xFF34C759),
                      ),
                      title: Text("ตำแหน่งของคุณ"),
                    ),
                  );
                },
                onSelected: (suggestion) async {
                  final location = await fetchLatLngFromPlaceName(suggestion);
                  if (location != null) {
                    _updateMapAndMarker(location);
                    _searchController.text = suggestion;
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 100, // ปรับตำแหน่งให้ไม่ทับปุ่มยืนยัน
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF34C759)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ElevatedButton(
          onPressed: _selectedLocation != null ? _confirmLocation : null,
          child: const Text(
            "ยืนยันตำแหน่ง",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedLocation != null
                ? const Color(0xFF34C759)
                : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
          ),
        ),
      ),
    );
  }
}
