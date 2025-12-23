import 'package:flutter/material.dart';

class DistanceSummaryCard extends StatelessWidget {
  final double tripKm;
  final double pickupKm;
  final double dropKm;

  const DistanceSummaryCard({
    super.key,
    required this.tripKm,
    required this.pickupKm,
    required this.dropKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip distance: ${tripKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Pickup',
                  value: '${pickupKm.toStringAsFixed(1)} kms',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetric(
                  label: 'Drop',
                  value: '${dropKm.toStringAsFixed(1)} kms',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
