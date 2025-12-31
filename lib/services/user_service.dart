import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UserService {
  // Get user details
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    // Argument is userId
    try {
      final response = await ApiService.getRequest(
        'users/get_user.php?uid=$userId', // ✅ Use userId here
      );
      // Ensure we return the response
      return response;
    } catch (e) {
      print('❌ Get User Error: $e');
      return null; // Don't rethrow, just return null so UI doesn't crash
    }
  }

  // Update FCM token for notifications
  static Future<void> updateFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      // Also fix this URL if you haven't created the rewritten rule
      // OLD: 'users/$userId/fcm-token'
      // NEW (Likely): 'users/update_fcm.php' (check your PHP files)

      // For now, focusing on the variable error:
      await ApiService.putRequest('users/update_fcm.php', {
        'uid': userId,
        'fcm_token': fcmToken,
      });
    } catch (e) {
      print('❌ Update FCM Token Error: $e');
      // rethrow; // Optional
    }
  }
}
