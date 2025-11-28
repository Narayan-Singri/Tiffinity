import 'package:flutter/material.dart';
import 'api_service.dart';
// Add this method to AuthService class
import 'package:Tiffinity/services/notification_service.dart';

class AuthService {
  static Future<void> saveFCMToken(String userId) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getToken();

      if (token != null) {
        // Save to backend
        await ApiService.put('/users/$userId/fcm-token', {'fcm_token': token});
        print('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Current user data
  static Future<Map<String, dynamic>?> get currentUser async {
    return await ApiService.getUserData();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  // SIGN IN with Email/Password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/login', {
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

  // SIGN UP with Email/Password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/register', {
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

  // LOGOUT
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
