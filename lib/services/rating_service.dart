import 'package:flutter/foundation.dart';
import 'package:Tiffinity/services/api_service.dart';

class RatingService {
  static Future<Map<String, dynamic>> submitMessRating({
    required String orderId,
    required String messId,
    required String customerId,
    required int rating,
    String? review,
  }) async {
    return await ApiService.postForm('ratings/mess_ratings.php', {
      'order_id': orderId,
      'mess_id': messId,
      'customer_id': customerId,
      'rating': rating.toString(),
      'review': (review ?? '').trim(),
    });
  }

  static Future<Map<String, dynamic>> submitDeliveryRating({
    required String orderId,
    required String deliveryPartnerId,
    required String customerId,
    required int rating,
    String? review,
  }) async {
    try {
      return await ApiService.postForm('ratings/delivery_boy_ratings.php', {
        'order_id': orderId,
        'delivery_partner_id': deliveryPartnerId,
        'customer_id': customerId,
        'rating': rating.toString(),
        'review': (review ?? '').trim(),
      });
    } catch (e) {
      debugPrint('submitDeliveryRating ratings/ path error: $e');
      try {
        // Backward-compatible fallback if endpoint is still at API root
        return await ApiService.postForm('delivery_boy_ratings.php', {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
          'customer_id': customerId,
          'rating': rating.toString(),
          'review': (review ?? '').trim(),
        });
      } catch (fallbackError) {
        debugPrint('submitDeliveryRating fallback error: $fallbackError');
        return {
          'status': 'error',
          'message': 'Failed to submit delivery partner rating',
        };
      }
    }
  }

  static Future<Map<String, dynamic>?> getLatestUnratedOrder({
    required String customerId,
  }) async {
    try {
      final response = await ApiService.postForm(
        'ratings/get_latest_unrated_order.php',
        {'customer_id': customerId},
      );

      if (response['success'] == true) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('getLatestUnratedOrder error: $e');
      try {
        // fallback if endpoint not inside ratings folder
        final response = await ApiService.postForm(
          'get_latest_unrated_order.php',
          {'customer_id': customerId},
        );

        if (response['success'] == true) {
          return response;
        }

        return null;
      } catch (fallbackError) {
        debugPrint('getLatestUnratedOrder fallback error: $fallbackError');
        return null;
      }
    }
  }
}
