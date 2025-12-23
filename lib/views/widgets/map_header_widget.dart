import 'package:flutter/material.dart';

class MapHeaderWidget extends StatelessWidget {
  const MapHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(
          child: Text(
            'Map placeholder',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
