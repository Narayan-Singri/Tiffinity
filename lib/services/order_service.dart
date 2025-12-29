import '../services/api_service.dart';
import 'dart:convert';

class OrderService {
  // Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required int messId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    try {
      final response = await ApiService.postRequest('orders', {
        'customer_id': customerId,
        'mess_id': messId.toString(),
        'items': json.encode(items),
        'total_amount': totalAmount.toString(),
      });
      return response;
    } catch (e) {
      print('❌ Create Order Error: $e');
      rethrow;
    }
  }

  // ✅ FIX: Added getOrderById method
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      return await ApiService.getRequest('orders/$orderId');
    } catch (e) {
      print('❌ Get Order By ID Error: $e');
      rethrow;
    }
  }

  // Get a specific order by ID (legacy method)
  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      return await ApiService.getRequest('orders/$orderId');
    } catch (e) {
      print('❌ Get Order Error: $e');
      rethrow;
    }
  }

  // Get all orders for a customer
  static Future<List<dynamic>> getCustomerOrders(String customerId) async {
    try {
      final data = await ApiService.getRequest('orders/customer/$customerId');
      return data is List ? data : [];
    } catch (e) {
      print('❌ Get Customer Orders Error: $e');
      rethrow;
    }
  }

  // Get all orders for a mess
  static Future<List<dynamic>> getMessOrders(int messId) async {
    try {
      final data = await ApiService.getRequest('orders/mess/$messId');
      return data is List ? data : [];
    } catch (e) {
      print('❌ Get Mess Orders Error: $e');
      rethrow;
    }
  }

  // ✅ FIX: Added return type bool
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await ApiService.putRequest('orders/$orderId/status', {'status': status});
      return true;
    } catch (e) {
      print('❌ Update Order Status Error: $e');
      return false;
    }
  }
}
