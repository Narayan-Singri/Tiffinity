import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OrderLiveMap extends StatefulWidget {
  final String status;
  final Map? deliveryPartner;
  final LatLng? destination;

  const OrderLiveMap({
    super.key,
    required this.status,
    this.deliveryPartner,
    this.destination,
  });

  @override
  State<OrderLiveMap> createState() => _OrderLiveMapState();
}

class _OrderLiveMapState extends State<OrderLiveMap> {
  GoogleMapController? _mapController;

  LatLng? _currentDriverLocation;
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _extractAndSetLocation();
  }

  @override
  void didUpdateWidget(OrderLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deliveryPartner != oldWidget.deliveryPartner) {
      _extractAndSetLocation();
    }
  }

  void _extractAndSetLocation() {
    if (widget.deliveryPartner != null) {
      final lat = double.tryParse(widget.deliveryPartner!['current_location_lat']?.toString() ?? '');
      final lng = double.tryParse(widget.deliveryPartner!['current_location_lng']?.toString() ?? '');

      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);

        bool shouldFetchRoute = _routePoints.isEmpty || _currentDriverLocation == null;

        setState(() {
          _currentDriverLocation = newLocation;
        });

        // Animate camera smoothly to the new location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(newLocation),
          );
        }

        // Fetch route if we have a destination and haven't fetched it yet
        if (shouldFetchRoute && widget.destination != null) {
          _fetchRoute(newLocation, widget.destination!);
        }
      }
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    if (_isFetchingRoute) return;

    setState(() { _isFetchingRoute = true; });

    try {
      // Kept your free OSRM routing logic!
      final url = 'http://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    } finally {
      if (mounted) {
        setState(() { _isFetchingRoute = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = widget.status.toLowerCase();

    // Show tracking elements when accepted, confirmed, ready, or out_for_delivery
    final bool showTracking = normalizedStatus == 'accepted' ||
        normalizedStatus == 'confirmed' ||
        normalizedStatus == 'ready' ||
        normalizedStatus == 'out_for_delivery';

    if (_currentDriverLocation == null) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                "Locating delivery partner...",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            ],
          ),
        ),
      );
    }

    // Build Markers Set
    final Set<Marker> markers = {};

    if (showTracking) {
      // Driver Marker (Orange)
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: _currentDriverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: "Delivery Partner"),
        ),
      );

      // Destination Marker (Red)
      if (widget.destination != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination_marker'),
            position: widget.destination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: "Delivery Location"),
          ),
        );
      }
    }

    // Build Polylines Set
    final Set<Polyline> polylines = {};

    if (_routePoints.isNotEmpty && showTracking) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: _routePoints,
          color: Colors.blueAccent.withOpacity(0.8),
          width: 4,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentDriverLocation!,
            zoom: 15.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: markers,
          polylines: polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false, // Hiding controls for a cleaner look
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),

        // SHADOW GRADIENT
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),

        // Floating Status Message
        if (normalizedStatus == 'confirmed' ||
            normalizedStatus == 'ready' ||
            normalizedStatus == 'accepted' ||
            normalizedStatus == 'pending')
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.soup_kitchen,
                        size: 24,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Mess is preparing your order...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}