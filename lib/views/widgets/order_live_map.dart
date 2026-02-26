import 'package:flutter/material.dart';

class OrderLiveMap extends StatelessWidget {
  final String status;
  final Map? deliveryPartner;

  const OrderLiveMap({super.key, required this.status, this.deliveryPartner});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://media.wired.com/photos/59269cd37034dc5f91bec0f1/master/pass/GoogleMapTA.jpg',
          fit: BoxFit.cover,
          color: Colors.white.withOpacity(0.8),
          colorBlendMode: BlendMode.modulate,
        ),
        Container(
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
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (normalizedStatus == 'confirmed' ||
                  normalizedStatus == 'ready') ...[
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
                const Text(
                  "Mess is preparing your order...",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ] else if (normalizedStatus == 'out_for_delivery') ...[
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.delivery_dining,
                    size: 30,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Order on the way!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
