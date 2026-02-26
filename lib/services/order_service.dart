import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'dart:convert';

class OrderService {
  static const Set<String> _assignmentAcceptedOrBeyond = {
    'accepted',
    'reached_pickup',
    'picked_up',
    'out_for_delivery',
    'in_transit',
    'delivered',
  };

  static Map<String, dynamic> _normalizeOrderStatus(Map<String, dynamic> raw) {
    final order = Map<String, dynamic>.from(raw);
    final status = (order['status'] ?? '').toString().toLowerCase().trim();
    final assignmentStatus = _extractAssignmentStatus(order);

    // confirmed must only be shown once delivery assignment is accepted.
    // Do not override backend status — backend is source of truth

    return order;
  }

  static String? _extractAssignmentStatus(Map<String, dynamic> order) {
    final directKeys = [
      'assignment_status',
      'delivery_assignment_status',
      'delivery_status',
      'delivery_assignment',
    ];

    for (final key in directKeys) {
      final value = order[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.toLowerCase().trim();
      }
      if (value is Map) {
        final nested = value['status'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.toLowerCase().trim();
        }
      }
    }

    final partnerDetails = order['delivery_partner_details'];
    if (partnerDetails is Map) {
      final nestedCandidates = [
        partnerDetails['assignment_status'],
        partnerDetails['delivery_assignment_status'],
        partnerDetails['status'],
      ];
      for (final value in nestedCandidates) {
        if (value is String && value.trim().isNotEmpty) {
          return value.toLowerCase().trim();
        }
      }
    }

    return null;
  }

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
      debugPrint('Create Order Error: $e');
      rethrow;
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final data = await ApiService.getRequest(
        'orders/get_order.php?id=$orderId',
      );
      if (data is Map) {
        return _normalizeOrderStatus(Map<String, dynamic>.from(data));
      }
      return data;
    } catch (e) {
      debugPrint('Get Order By ID Error: $e');
      rethrow;
    }
  }

  // Get all orders for a customer
  static Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    try {
      final data = await ApiService.getRequest(
        'orders/get_customer_orders.php?customer_id=$customerId',
      );

      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map(
            (item) => _normalizeOrderStatus(Map<String, dynamic>.from(item)),
          ),
        );
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(
          data['data'].map(
            (item) => _normalizeOrderStatus(Map<String, dynamic>.from(item)),
          ),
        );
      } else if (data is Map && data.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(
          data['orders'].map(
            (item) => _normalizeOrderStatus(Map<String, dynamic>.from(item)),
          ),
        );
      } else if (data is Map) {
        return [_normalizeOrderStatus(Map<String, dynamic>.from(data))];
      }

      return [];
    } catch (e) {
      debugPrint('Get Customer Orders Error: $e');
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
        return response
            .map((e) => _normalizeOrderStatus(safeParse(e)))
            .toList();
      } else if (response is Map) {
        if (response.containsKey('orders') && response['orders'] is List) {
          return (response['orders'] as List)
              .map((e) => _normalizeOrderStatus(safeParse(e)))
              .toList();
        }

        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List)
              .map((e) => _normalizeOrderStatus(safeParse(e)))
              .toList();
        }

        return [_normalizeOrderStatus(safeParse(response))];
      }

      return [];
    } catch (e) {
      debugPrint('Get Mess Orders Error: $e');
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
      debugPrint('Update Order Status Error: $e');
      return false;
    }
  }

  // Reject order with reason
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
      debugPrint('Reject Order Error: $e');
      return false;
    }
  }
}
