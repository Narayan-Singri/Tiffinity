import 'package:flutter/material.dart';
import 'package:Tiffinity/views/pages/customer_pages/order_tracking_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/order_details_page.dart';
import 'package:Tiffinity/services/order_service.dart';

class NotificationNavigationHelper {
  static Future<void> navigateToOrder({
    required BuildContext context,
    required String orderId,
    required String userRole,
  }) async {
    try {
      debugPrint('🔀 Navigating to order: $orderId for role: $userRole');

      // Fetch order data first
      final orderData = await OrderService.getOrderById(orderId);

      if (orderData == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order not found')));
        return;
      }

      if (userRole == 'customer') {
        // Navigate to Order Tracking Page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderTrackingPage(orderId: orderId),
          ),
        );
      } else if (userRole == 'admin') {
        // Navigate to Order Details Page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    OrderDetailsPage(orderId: orderId, orderData: orderData),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening order: $e')));
    }
  }
}
