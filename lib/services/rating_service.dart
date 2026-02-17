import 'package:flutter/foundation.dart';
import 'package:Tiffinity/services/api_service.dart';

class RatingService {
  static Future<Map<String, dynamic>> submitMessRating({
    required String orderId,
    required String messOwnerId,
    required String customerId,
    required int rating,
    String? review,
  }) async {
    try {
      return await ApiService.postForm('ratings/mess_ratings.php', {
        'order_id': orderId,
        'mess_owner_id': messOwnerId,
        'customer_id': customerId,
        'rating': rating.toString(),
        'review': (review ?? '').trim(),
      });
    } catch (e) {
      debugPrint('submitMessRating ratings/ path error: $e');
      try {
        // Backward-compatible fallback if endpoint is still at API root
        return await ApiService.postForm('ratings/mess_ratings.php', {
          'order_id': orderId,
          'mess_owner_id': messOwnerId,
          'customer_id': customerId,
          'rating': rating.toString(),
          'review': (review ?? '').trim(),
        });
      } catch (fallbackError) {
        debugPrint('submitMessRating fallback error: $fallbackError');
        return {'status': 'error', 'message': 'Failed to submit mess rating'};
      }
    }
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

  static Future<double> getMovingAverage({
    required String type,
    required String id,
  }) async {
    try {
      final response = await ApiService.getRequest(
        'ratings/moving_average.php?type=$type&id=$id',
      );

      if (response is Map) {
        final value = double.tryParse(response['moving_avg']?.toString() ?? '');
        return value ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('getMovingAverage ratings/ path error: $e');
      try {
        // Backward-compatible fallback if endpoint is still at API root
        final response = await ApiService.getRequest(
          'moving_average.php?type=$type&id=$id',
        );
        if (response is Map) {
          final value = double.tryParse(
            response['moving_avg']?.toString() ?? '',
          );
          return value ?? 0.0;
        }
        return 0.0;
      } catch (fallbackError) {
        debugPrint('getMovingAverage fallback error: $fallbackError');
        return 0.0;
      }
    }
  }
}
