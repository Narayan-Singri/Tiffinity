import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'dart:convert';

class OrderService {
  // Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required int messId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    try {
      final response = await ApiService.postForm('orders/create_order.php', {
        'customer_id': customerId,
        'mess_id': messId.toString(),
        'items': json.encode(items),
        'total_amount': totalAmount.toString(),
        'delivery_address': deliveryAddress,
      });
      return response;
    } catch (e) {
      debugPrint('❌ Create Order Error: $e');
      rethrow;
    }
  }

  // ✅ Get order by ID (Enhanced with full details)
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      return await ApiService.getRequest('orders/get_order.php?id=$orderId');
    } catch (e) {
      debugPrint('❌ Get Order By ID Error: $e');
      rethrow;
    }
  }

  // ✅ Get all orders for a customer
  static Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    try {
      final data = await ApiService.getRequest(
        'orders/get_customer_orders.php?customer_id=$customerId',
      );

      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(
          data['data'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(
          data['orders'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get Customer Orders Error: $e');
      rethrow;
    }
  }

  // Get all orders for a mess
  static Future<List<Map<String, dynamic>>> getMessOrders(int messId) async {
    try {
      final response = await ApiService.getRequest(
        'orders/get_mess_orders.php?mess_id=$messId',
      );

      Map<String, dynamic> safeParse(dynamic item) {
        if (item is! Map) return {};
        return Map<String, dynamic>.from(item);
      }

      if (response is List) {
        return response.map((e) => safeParse(e)).toList();
      } else if (response is Map) {
        if (response.containsKey('orders') && response['orders'] is List) {
          return (response['orders'] as List).map((e) => safeParse(e)).toList();
        }

        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List).map((e) => safeParse(e)).toList();
        }

        return [safeParse(response)];
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get Mess Orders Error: $e');
      rethrow;
    }
  }

  // Update order status
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await ApiService.postForm('orders/update_order_status.php?id=$orderId', {
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Update Order Status Error: $e');
      return false;
    }
  }

  // ✅ Reject order with reason
  static Future<bool> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await ApiService.postForm('orders/reject_order.php', {
        'order_id': orderId,
        'reason': reason,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Reject Order Error: $e');
      return false;
    }
  }
}
