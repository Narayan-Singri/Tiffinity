// ✅ FIXED order_service.dart - Matching your ApiService methods
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
  }) async {
    try {
      // NEW CODE (Sends Form Data)
      final response = await ApiService.postForm('orders/create_order.php', {
        'customer_id': customerId,
        'mess_id': messId.toString(),
        'items': json.encode(
          items,
        ), // PHP receives this as a string and needs json_decode
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
      return await ApiService.getRequest('orders/get_order.php?id=$orderId');
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
      final data = await ApiService.getRequest(
        'orders/get_customer_orders.php?customer_id=$customerId',
      );
      // ✅ FIX: Defensive response parsing
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
      print('❌ Get Customer Orders Error: $e');
      rethrow;
    }
  }

  // ✅ CORRECT: Get all orders for a mess
  // File is in /api/orders/ folder, not /api/messes/ folder!
  static Future<List<Map<String, dynamic>>> getMessOrders(int messId) async {
    try {
      final response = await ApiService.getRequest(
        'orders/get_mess_orders.php?mess_id=$messId',
      );

      // Helper to safely parse
      Map<String, dynamic> safeParse(dynamic item) {
        if (item is! Map) return {};
        // Ensure we return a clean Map<String, dynamic>
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
