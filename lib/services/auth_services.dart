import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:Tiffinity/services/notification_service.dart';

class AuthService {
  static const String _verifyEmailEndpoint = 'users/verify_email.php';
  static const String _loginWithOtpEndpoint = 'users/login_with_otp.php';
  static const String _verifyLoginOtpEndpoint = 'users/verify_login_otp.php';
  static const String _forgetPasswordEndpoint = 'users/forget_password.php';
  static const String _resetPasswordEndpoint = 'users/reset_password.php';
  static const String _resendOtpEndpoint = 'users/email_otp_handler.php';
  static const String otpPurposeLogin = 'login';
  static const String otpPurposeVerify = 'verify';

  static Future<void> saveFCMToken(String userId) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getDeviceToken();
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

      if (_isSuccessful(response)) {
        final data = _extractAuthData(response);
        if (data == null) {
          throw AuthException('Invalid login response');
        }
        await ApiService.saveToken(data['token']);
        await ApiService.saveUserData(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        throw AuthException(_extractMessage(response) ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Login failed'));
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

      if (_isSuccessful(response)) {
        return {
          'success': true,
          'message': _extractMessage(response) ?? 'Registration successful',
        };
      } else {
        throw AuthException(_extractMessage(response) ?? 'Sign up failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Sign up failed'));
    }
  }

  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiService.postForm(_verifyEmailEndpoint, {
        'email': email,
        'otp': otp,
      });

      if (_isSuccessful(response)) {
        final data = _extractAuthData(response);
        if (data == null) {
          throw AuthException('Invalid OTP verification response');
        }
        await ApiService.saveToken(data['token']);
        await ApiService.saveUserData(data['user']);
        return {'success': true, 'user': data['user']};
      }

      throw AuthException(
        _extractMessage(response) ?? 'OTP verification failed',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'OTP verification failed'));
    }
  }

  Future<void> resendVerificationOtp({
    required String email,
    required String role,
  }) async {
    try {
      final response = await ApiService.postForm(_resendOtpEndpoint, {
        'email': email,
        'purpose': 'verify',
        'role': role,
      });

      if (!_isSuccessful(response)) {
        throw AuthException(
          _extractMessage(response) ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Failed to resend OTP'));
    }
  }

  Future<String> requestLoginOtp({
    required String email,
    required String role,
  }) async {
    try {
      final response = await ApiService.postForm(_loginWithOtpEndpoint, {
        'email': email,
      });
      if (!_isSuccessful(response)) {
        throw AuthException(
          _extractMessage(response) ?? 'Failed to send login OTP',
        );
      }
      return _extractOtpPurpose(response) ?? otpPurposeLogin;
    } catch (e) {
      final message = _normalizeError(e, 'Failed to send login OTP');

      // Legacy users may exist with email_verified=0.
      // In that case login OTP endpoint may return "User not found".
      // Fallback to verification OTP so they can verify and then login.
      if (_isUnverifiedLegacyCase(message)) {
        await resendVerificationOtp(email: email, role: role);
        return otpPurposeVerify;
      }

      throw AuthException(message);
    }
  }

  Future<Map<String, dynamic>> verifyLoginOtp({
    required String email,
    required String otp,
    required String role,
    String purpose = otpPurposeLogin,
  }) async {
    try {
      final endpoint =
          purpose == otpPurposeVerify
              ? _verifyEmailEndpoint
              : _verifyLoginOtpEndpoint;

      final response = await ApiService.postForm(endpoint, {
        'email': email,
        'otp': otp,
      });

      if (_isSuccessful(response)) {
        final data = _extractAuthData(response);
        if (data == null) {
          throw AuthException('Invalid login OTP response');
        }

        final user = Map<String, dynamic>.from(data['user'] ?? {});
        user['role'] = user['role'] ?? role;

        await ApiService.saveToken(data['token']);
        await ApiService.saveUserData(user);
        return {'success': true, 'user': user};
      }

      throw AuthException(
        _extractMessage(response) ?? 'Login OTP verification failed',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Login OTP verification failed'));
    }
  }

  Future<void> requestForgotPasswordOtp({required String email}) async {
    try {
      final response = await ApiService.postForm(_forgetPasswordEndpoint, {
        'email': email,
      });
      if (!_isSuccessful(response)) {
        throw AuthException(
          _extractMessage(response) ?? 'Failed to send password reset OTP',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Failed to send password reset OTP'));
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.postForm(_resetPasswordEndpoint, {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      });
      if (!_isSuccessful(response)) {
        throw AuthException(
          _extractMessage(response) ?? 'Password reset failed',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_normalizeError(e, 'Password reset failed'));
    }
  }

  static bool _isSuccessful(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return true;
    }

    final nested = response['data'];
    if (nested is Map<String, dynamic> && nested['success'] == true) {
      return true;
    }

    return false;
  }

  static String? _extractMessage(Map<String, dynamic> response) {
    if (response['message'] is String) {
      return response['message'] as String;
    }
    final nested = response['data'];
    if (nested is Map<String, dynamic> && nested['message'] is String) {
      return nested['message'] as String;
    }
    return null;
  }

  static Map<String, dynamic>? _extractAuthData(Map<String, dynamic> response) {
    final direct = response['data'];
    if (direct is Map<String, dynamic> &&
        direct['token'] != null &&
        direct['user'] is Map<String, dynamic>) {
      return direct;
    }

    if (direct is Map<String, dynamic>) {
      final nested = direct['data'];
      if (nested is Map<String, dynamic> &&
          nested['token'] != null &&
          nested['user'] is Map<String, dynamic>) {
        return nested;
      }
    }

    return null;
  }

  static String? _extractOtpPurpose(Map<String, dynamic> response) {
    final directPurpose = response['purpose'];
    if (directPurpose is String) return directPurpose;

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nestedPurpose = data['purpose'];
      if (nestedPurpose is String) return nestedPurpose;
    }
    return null;
  }

  static String _normalizeError(Object error, String fallback) {
    final text = error.toString().trim();
    if (text.isEmpty) return fallback;
    if (text.startsWith('Exception: ')) {
      final msg = text.substring('Exception: '.length).trim();
      return msg.isEmpty ? fallback : msg;
    }
    return text;
  }

  static bool _isUnverifiedLegacyCase(String message) {
    final lower = message.toLowerCase();
    return lower.contains('user not found') ||
        lower.contains('email not verified') ||
        lower.contains('not verified');
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

  Future<void> updateVerificationStatus({
    required String type,
    required String value,
  }) async {}
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
