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
  LatLng _initialPosition = const LatLng(
    13.7563,
    100.5018,
  ); // แก้เป็นพิกัดกรุงเทพฯเริ่มต้น
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final String apiKey = "YOUR_GOOGLE_MAPS_API_KEY"; // ใส่ API KEY ของคุณตรงนี้

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // แจ้งผู้ใช้เปิดสิทธิ์ Location ใน settings
      return;
    }

    if (await Geolocator.isLocationServiceEnabled()) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });
      if (_mapController != null) {
        _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition));
      }
    }
  }

  Future<List<String>> fetchPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&language=th&key=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final predictions = result['predictions'] as List;
        return predictions.map((p) => p['description'] as String).toList();
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

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

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกตำแหน่งร้าน"),
        backgroundColor: const Color(0xFF34C759),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 16,
            ),
            onTap: (LatLng pos) {
              setState(() {
                _selectedLocation = pos;
              });
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TypeAheadField<String>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: _searchController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'ค้นหาสถานที่',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
              suggestionsCallback: fetchPlaceSuggestions,
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion),
                );
              },
              onSelected: (suggestion) async {
                final location = await fetchLatLngFromPlaceName(suggestion);
                if (location != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLng(location),
                  );
                  setState(() {
                    _selectedLocation = location;
                    _searchController.text = suggestion;
                  });
                }
              },
            ),
          ),
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: _selectedLocation != null ? _confirmLocation : null,
          icon: const Icon(Icons.check),
          label: const Text("ยืนยันตำแหน่ง"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34C759),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
