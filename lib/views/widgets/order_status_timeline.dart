import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int stepIndex = _getStepIndex(currentStatus);
    bool isCancelled = currentStatus.toLowerCase() == 'cancelled';

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text(
              "Order Cancelled",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStep(0, "Order Placed", Icons.receipt_long, stepIndex, isDark),
          _buildConnector(0, stepIndex, isDark),
          _buildStep(
            1,
            "Confirmed",
            Icons.thumb_up_alt_outlined,
            stepIndex,
            isDark,
          ),
          _buildConnector(1, stepIndex, isDark),
          _buildStep(2, "Preparing", Icons.outdoor_grill, stepIndex, isDark),
          _buildConnector(2, stepIndex, isDark),
          _buildStep(
            3,
            "Out for Delivery",
            Icons.delivery_dining,
            stepIndex,
            isDark,
          ),
          _buildConnector(3, stepIndex, isDark),
          _buildStep(4, "Delivered", Icons.home, stepIndex, isDark),
        ],
      ),
    );
  }

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'confirmed':
        return 1;
      case 'preparing':
        return 2;
      case 'out_for_delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildStep(
    int index,
    String title,
    IconData icon,
    int currentIndex,
    bool isDark,
  ) {
    bool isCompleted = index <= currentIndex;
    bool isActive = index == currentIndex;
    const activeColor = Color.fromARGB(255, 27, 84, 78);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? activeColor
                    : (isDark ? Colors.grey[700] : Colors.grey[200]),
            shape: BoxShape.circle,
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          child: Icon(
            icon,
            color:
                isCompleted
                    ? Colors.white
                    : (isDark ? Colors.grey[500] : Colors.grey),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            color:
                isCompleted
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[600] : Colors.grey),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int index, int currentIndex, bool isDark) {
    bool isCompleted = index < currentIndex;
    return Container(
      margin: const EdgeInsets.only(left: 18),
      height: 24,
      width: 2,
      decoration: BoxDecoration(
        color:
            isCompleted
                ? const Color.fromARGB(255, 27, 84, 78)
                : (isDark ? Colors.grey[700] : Colors.grey[200]),
      ),
    );
  }
}
