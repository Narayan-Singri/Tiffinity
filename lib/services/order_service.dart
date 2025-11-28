import 'package:Tiffinity/services/api_service.dart';

class OrderService {
  // Create new order
  static Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required int messId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiService.post('/orders', {
        'customer_id': customerId,
        'mess_id': messId,
        'total_amount': totalAmount,
        'items': items,
      });

      if (response['success']) {
        return {
          'success': true,
          'order_id': response['data']['order_id'],
          'message': 'Order placed successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await ApiService.get('/orders/$orderId');
      if (response['success']) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Get customer orders
  static Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    try {
      final response = await ApiService.get('/orders/customer/$customerId');
      if (response['success']) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching customer orders: $e');
      return [];
    }
  }

  // Get mess orders (for admin)
  static Future<List<Map<String, dynamic>>> getMessOrders(int messId) async {
    try {
      final response = await ApiService.get('/orders/mess/$messId');
      if (response['success']) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching mess orders: $e');
      return [];
    }
  }

  // Update order status
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await ApiService.put('/orders/$orderId/status', {
        'status': status,
      });
      return response['success'];
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
}
