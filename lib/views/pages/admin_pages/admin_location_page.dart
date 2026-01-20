import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Tiffinity/services/api_service.dart';

class AdminLocationPage extends StatefulWidget {
  final int messId;
  final String ownerName;

  const AdminLocationPage({
    super.key,
    required this.messId,
    required this.ownerName,
  });

  @override
  State<AdminLocationPage> createState() => _AdminLocationPageState();
}

class _AdminLocationPageState extends State<AdminLocationPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = 'Detecting location...';
  bool _isLoading = true;
  bool _isSaving = false;
  final Set<Marker> _markers = {};

  final TextEditingController _shopNoController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _shopNoController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();

      if (permission.isDenied) {
        _showError('Location permission is required');
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable location services');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error getting location: $e');
    }
  }

  Future<void> _updateLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      String address = 'Selected location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';

        // Auto-fill fields from detected location
        _areaController.text = place.subLocality ?? '';
        _landmarkController.text = place.street ?? '';
        _pincodeController.text = place.postalCode ?? '';
      }

      setState(() {
        _currentPosition = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _currentAddress = address;
        _isLoading = false;

        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('mess_location'),
            position: LatLng(latitude, longitude),
            draggable: true,
            onDragEnd: (newPosition) {
              _updateLocationFromCoordinates(
                newPosition.latitude,
                newPosition.longitude,
              );
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 17.0),
      );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_currentPosition == null) {
      _showError('Location not detected yet');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response =
          await ApiService.postForm('messes/save_mess_location.php', {
            'mess_id': widget.messId.toString(),
            'latitude': _currentPosition!.latitude.toString(),
            'longitude': _currentPosition!.longitude.toString(),
            'shop_no': _shopNoController.text.trim(),
            'area': _areaController.text.trim(),
            'landmark': _landmarkController.text.trim(),
            'pincode': _pincodeController.text.trim(),
          });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError(response['message'] ?? 'Failed to save location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Mess Location'),
        backgroundColor: const Color(0xFF00695C),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Map View
                  Expanded(
                    flex: 2,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition?.latitude ?? 19.0760,
                          _currentPosition?.longitude ?? 72.8777,
                        ),
                        zoom: 17.0,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (LatLng position) {
                        _updateLocationFromCoordinates(
                          position.latitude,
                          position.longitude,
                        );
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),

                  // Address Form
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mess Location for ${widget.ownerName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: _shopNoController,
                              decoration: InputDecoration(
                                labelText: 'Shop/Outlet Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.store),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _areaController,
                              decoration: InputDecoration(
                                labelText: 'Area/Locality',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _landmarkController,
                              decoration: InputDecoration(
                                labelText: 'Landmark',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.place),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Pin Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.pin_drop),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00695C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isSaving
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Save Mess Location',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00695C),
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
