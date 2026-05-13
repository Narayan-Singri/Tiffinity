import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  // ============================================
  // TOKEN & USER DATA STORAGE METHODS
  // ============================================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint('✅ Token saved');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('✅ Token cleared');
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user));
    debugPrint('✅ User data saved');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    debugPrint('✅ User data cleared');
  }

  // ============================================
  // GENERIC HTTP METHODS
  // ============================================

  // FIX(weekly-menu): Helper to get headers with auth token
  // This ensures all API requests include the JWT Bearer token for authentication
  // Previously, the Authorization header was missing causing backend auth failures
  static Future<Map<String, String>> _getHeaders({
    String contentType = 'application/json',
  }) async {
    final token = await getToken();
    return {
      'Content-Type': contentType,
      'Accept': 'application/json',
      if (token != null)
        'Authorization':
            'Bearer $token', // FIX(weekly-menu): include auth token
    };
  }

  /// POST request with form data (URL-encoded)
  /// FIX(weekly-menu): Now includes auth token via _getHeaders() for backend authentication
  static Future<Map<String, dynamic>> postForm(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 POST Form to: $baseUrl/$endpoint');

      final formData = <String, String>{};
      data.forEach((key, value) {
        formData[key] = value?.toString() ?? '';
      });

      debugPrint('📤 Data: $formData');

      final headers = await _getHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        encoding: Encoding.getByName('utf-8'),
        body: formData,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.body.trim().isNotEmpty) {
        final parsed = json.decode(response.body);
        if (parsed is Map<String, dynamic>) {
          if (response.statusCode == 200 || response.statusCode == 201) {
            return parsed;
          }

          final message =
              parsed['message']?.toString() ??
              parsed['error']?.toString() ??
              "Request failed with status ${response.statusCode}";
          throw Exception(message);
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        throw Exception("Empty response from server");
      }

      throw Exception("Request failed with status ${response.statusCode}");
    } catch (e) {
      debugPrint('❌ POST Form Error: $e');
      rethrow;
    }
  }

  /// POST request with JSON body
  /// FIX(weekly-menu): Now includes auth token via _getHeaders() for backend authentication
  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 POST JSON to: $baseUrl/$endpoint');

      // FIX(weekly-menu): include auth token - ensures backend can verify user identity
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint(
        '📥 Response Body: ${response.body}',
      ); // ✅ Added for consistency

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Request failed');
      }
    } catch (e) {
      debugPrint('❌ POST Request Error: $e');
      rethrow;
    }
  }

  /// GET request
  /// FIX(weekly-menu): Now includes auth token via _getHeaders() for backend authentication
  static Future<dynamic> getRequest(String endpoint) async {
    try {
      debugPrint('📤 GET: $baseUrl/$endpoint');

      // FIX(weekly-menu): include auth token - ensures backend can verify user identity
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}'); // ✅ ADDED THIS LINE

      if (response.statusCode == 200) {
        // ✅ Handle empty response
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          debugPrint('⚠️ Empty GET response body');
          return [];
        }

        try {
          final dynamic responseData = json.decode(response.body);

          // Handle "data" wrapper if present
          dynamic data;
          if (responseData is Map && responseData.containsKey('data')) {
            data = responseData['data'];
          } else {
            data = responseData;
          }

          return _convertDeep(data);
        } catch (e) {
          debugPrint('⚠️ GET JSON parse error: $e');
          return [];
        }
      } else {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ GET Request Error: $e');
      rethrow;
    }
  }

  /// PUT request with JSON body
  static Future<Map<String, dynamic>> putRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 PUT to: $baseUrl/$endpoint');
      debugPrint('📤 Data: ${json.encode(data)}');

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        try {
          final responseData = json.decode(response.body);
          final errorMessage =
              responseData['error'] ??
              responseData['message'] ??
              'Request failed with status ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Request failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('❌ PUT Request Error: $e');
      rethrow;
    }
  }

  static Future<void> put(String endpoint, Map<String, String> data) async {
    try {
      debugPrint('📤 PUT Form to: $baseUrl/$endpoint');
      debugPrint('📤 Data: $data');

      final headers = await _getHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        encoding: Encoding.getByName('utf-8'),
        body: data,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('PUT request failed');
      }
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
      rethrow;
    }
  }

  static Future<void> deleteRequest(String endpoint) async {
    try {
      debugPrint('📤 DELETE: $baseUrl/$endpoint');

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Delete request failed');
      }
    } catch (e) {
      debugPrint('❌ DELETE Request Error: $e');
      rethrow;
    }
  }

  // ============================================
  // Helper METHODS
  // ============================================

  static dynamic _convertDeep(dynamic input) {
    if (input is List) {
      return input.map((e) => _convertDeep(e)).toList();
    } else if (input is Map) {
      final Map<String, dynamic> converted = {};
      input.forEach((key, value) {
        final String strKey = key.toString();
        converted[strKey] = _convertDeep(value);
      });
      return converted;
    }
    return input;
  }
}
