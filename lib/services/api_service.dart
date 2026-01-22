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

  /// POST request with form data (URL-encoded)
  static Future<Map<String, dynamic>> postForm(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 POST Form to: $baseUrl/$endpoint');

      // Convert all values to strings for form encoding
      final formData = <String, String>{};
      data.forEach((key, value) {
        formData[key] = value?.toString() ?? '';
      });

      debugPrint('📤 Data: $formData');

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: formData,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ FIX: Handle empty response body
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          debugPrint('⚠️ Empty response body, returning success');
          return {
            'success': true,
            'message': 'Operation completed successfully',
          };
        }

        try {
          final responseData = json.decode(response.body);
          return responseData as Map<String, dynamic>;
        } catch (e) {
          debugPrint('⚠️ JSON parse error: $e');
          // If we got 200/201 but can't parse, assume success
          return {
            'success': true,
            'message': 'Operation completed successfully',
          };
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          throw Exception(responseData['message'] ?? 'Request failed');
        } catch (e) {
          throw Exception('Request failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('❌ POST Form Error: $e');
      rethrow;
    }
  }

  /// POST request with JSON body
  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 POST JSON to: $baseUrl/$endpoint');

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
  static Future<dynamic> getRequest(String endpoint) async {
    try {
      debugPrint('📤 GET: $baseUrl/$endpoint');

      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

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

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

  /// PUT request with form data (URL-encoded)
  static Future<void> put(String endpoint, Map<String, String> data) async {
    try {
      debugPrint('📤 PUT Form to: $baseUrl/$endpoint');
      debugPrint('📤 Data: $data');

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
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

  /// DELETE request
  static Future<void> deleteRequest(String endpoint) async {
    try {
      debugPrint('📤 DELETE: $baseUrl/$endpoint');

      final response = await http.delete(Uri.parse('$baseUrl/$endpoint'));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint(
        '📥 Response Body: ${response.body}',
      ); // ✅ Added for consistency

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
