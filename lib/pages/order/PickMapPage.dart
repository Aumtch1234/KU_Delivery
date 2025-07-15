// lib/pages/order/PickMapPage.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickMapPage extends StatefulWidget {
  const PickMapPage({super.key});
  @override
  State<PickMapPage> createState() => _PickMapPageState();
}

class _PickMapPageState extends State<PickMapPage> {
  LatLng? selectedLocation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตำแหน่งบนแผนที่')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.736717, 100.523186), // Bangkok
          zoom: 15,
        ),
        onTap: (latLng) {
          setState(() => selectedLocation = latLng);
        },
        markers: selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: selectedLocation!,
                ),
              }
            : {},
      ),
      floatingActionButton: selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
              label: const Text('เลือกตำแหน่งนี้'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
