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
  final MapController _mapController = MapController();

  LatLng? _currentDriverLocation;
  LatLng? _previousDriverLocation;

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

        bool shouldFetchRoute = _routePoints.isEmpty || _previousDriverLocation == null;

        setState(() {
          _previousDriverLocation = _currentDriverLocation ?? newLocation;
          _currentDriverLocation = newLocation;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _mapController.move(newLocation, 15.0);
            } catch (e) {
              debugPrint("Map not ready to move yet: $e");
            }
          }
        });

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
      setState(() { _isFetchingRoute = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = widget.status.toLowerCase();

    // 🌟 THE FIX 1: We create a master rule for when to show the tracking elements.
    // Now, the bike and line will show up immediately when the order is accepted!
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

            // THE ROUTE LINE
            if (_routePoints.isNotEmpty && showTracking)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blueAccent.withOpacity(0.8),
                    isDotted: false,
                  ),
                ],
              ),

            // THE DESTINATION MARKER
            if (widget.destination != null && showTracking)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.destination!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

            // THE ANIMATED DELIVERY BIKE
            if (showTracking)
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

        // 🌟 THE FIX 2: Sleek Floating Status Message
        // Moved from the center of the screen to a beautiful floating badge at the top!
        if (normalizedStatus == 'confirmed' || normalizedStatus == 'ready' || normalizedStatus == 'accepted' || normalizedStatus == 'pending')
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