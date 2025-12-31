import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:Tiffinity/services/notification_service.dart';

class AuthService {
  static Future<void> saveFCMToken(String userId) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getToken();
      if (token != null) {
        // ✅ FIXED: Correct path with folder structure
        await ApiService.put('users/update_fcm_token.php', {
          'user_id': userId,
          'fcm_token': token,
        });
        print('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static Future<Map<String, dynamic>?> get currentUser async {
    return await ApiService.getUserData();
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  // ✅ SIGN IN - Using postForm for auth (correct)
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.postForm('login.php', {
        'email': email,
        'password': password,
      });

      if (response['success']) {
        final data = response['data'];
        await ApiService.saveToken(data['token']);
        await ApiService.saveUserData(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        throw AuthException(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login error: $e');
    }
  }

  // ✅ SIGN UP - Using postForm for auth (correct)
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await ApiService.postForm('register.php', {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'role': role,
      });

      if (response['success']) {
        final data = response['data'];
        await ApiService.saveToken(data['token']);
        await ApiService.saveUserData(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        throw AuthException(response['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign up error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.clearToken();
      await ApiService.clearUserData();
    } catch (e) {
      debugPrint('Logout error: $e');
      throw 'Logout failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
