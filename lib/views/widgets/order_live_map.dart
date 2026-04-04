import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==========================================
// CUSTOM TWEEN FOR SMOOTH MAP ANIMATIONS
// ==========================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    if (begin == null || end == null) return begin ?? const LatLng(0, 0);
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}

class OrderLiveMap extends StatefulWidget {
  final String status;
  final Map? deliveryPartner;
  final LatLng? destination; // 👈 NEW: The customer's drop-off location

  const OrderLiveMap({
    super.key,
    required this.status,
    this.deliveryPartner,
    this.destination, // Pass the destination from your Order model!
  });

  @override
  State<OrderLiveMap> createState() => _OrderLiveMapState();
}

class _OrderLiveMapState extends State<OrderLiveMap> {
  final MapController _mapController = MapController();

  LatLng? _currentDriverLocation;
  LatLng? _previousDriverLocation;

  List<LatLng> _routePoints = []; // 👈 NEW: Holds the road coordinates
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

        // Only fetch the route if the driver has moved significantly or it's the first time
        bool shouldFetchRoute = _routePoints.isEmpty || _previousDriverLocation == null;

        setState(() {
          _previousDriverLocation = _currentDriverLocation ?? newLocation;
          _currentDriverLocation = newLocation;
        });

        _mapController.move(newLocation, 16.0);

        // Fetch the road route
        if (shouldFetchRoute && widget.destination != null) {
          _fetchRoute(newLocation, widget.destination!);
        }
      }
    }
  }

  // 👈 NEW: Function to ask OSRM for the road path
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    if (_isFetchingRoute) return;

    setState(() { _isFetchingRoute = true; });

    try {
      // OSRM expects coordinates in Longitude,Latitude format
      final url = 'http://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            // Convert OSRM GeoJSON [lng, lat] back to FlutterMap [lat, lng]
            _routePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    } finally {
      setState(() { _isFetchingRoute = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = widget.status.toLowerCase();

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

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentDriverLocation!,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tiffinity.customer',
            ),

            // 👈 NEW: THE ROUTE LINE (Draws before the markers so it sits underneath them)
            if (_routePoints.isNotEmpty && normalizedStatus == 'out_for_delivery')
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blueAccent.withOpacity(0.8), // Beautiful Uber-like blue line
                    isDotted: false,
                  ),
                ],
              ),

            // THE DESTINATION MARKER (Customer's House)
            if (widget.destination != null && normalizedStatus == 'out_for_delivery')
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.destination!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter, // Pin points directly at the coordinate
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

            // THE ANIMATED DELIVERY BIKE
            if (normalizedStatus == 'out_for_delivery')
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentDriverLocation!,
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: TweenAnimationBuilder<LatLng>(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      tween: LatLngTween(
                        begin: _previousDriverLocation!,
                        end: _currentDriverLocation!,
                      ),
                      builder: (context, animatedLocation, child) {
                        // 👇 Wrapped the CircleAvatar in a Material widget to add the shadow!
                        return Material(
                          elevation: 4.0,
                          shape: const CircleBorder(),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: Icon(
                              Icons.delivery_dining,
                              size: 24,
                              color: Color.fromARGB(255, 27, 84, 78),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
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

        // STATUS MESSAGES
        if (normalizedStatus == 'confirmed' || normalizedStatus == 'ready' || normalizedStatus == 'accepted' || normalizedStatus == 'pending')
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.soup_kitchen,
                    size: 30,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Mess is preparing your order...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}