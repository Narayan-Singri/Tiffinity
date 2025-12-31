import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UserService {
  // Get user details
  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      return await ApiService.getRequest('users/$userId'); // ✅ Clean URL
    } catch (e) {
      print('❌ Get User Error: $e');
      rethrow;
    }
  }

  // Update FCM token for notifications
  static Future<void> updateFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await ApiService.putRequest('users/$userId/fcm-token', {
        // ✅ Clean URL
        'fcm_token': fcmToken,
      });
    } catch (e) {
      print('❌ Update FCM Token Error: $e');
      rethrow;
    }
  }
}
