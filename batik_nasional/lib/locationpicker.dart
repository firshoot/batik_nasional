import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _pickedLocation = LatLng(-6.200000, 106.816666); // Contoh lokasi Jakarta
  GoogleMapController? _mapController;

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_pickedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 10,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _selectLocation,
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: MarkerId('m1'),
                      position: _pickedLocation,
                    ),
                  },
          ),
          if (_pickedLocation != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop(_pickedLocation);
                },
                child: Icon(Icons.check),
              ),
            ),
        ],
      ),
    );
  }
}
