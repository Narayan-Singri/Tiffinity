import 'package:flutter/material.dart';

class ContactButtonsRow extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onGoToMap;

  const ContactButtonsRow({
    super.key,
    required this.onCall,
    required this.onGoToMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCall,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.call, size: 18),
            label: const Text('Call'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onGoToMap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Go to map'),
          ),
        ),
      ],
    );
  }
}
