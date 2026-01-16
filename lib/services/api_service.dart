import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  // ============================================
  // TOKEN & USER DATA STORAGE METHODS
  // ============================================

  /// Save authentication token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint('✅ Token saved');
  }

  /// Get authentication token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Clear authentication token from local storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('✅ Token cleared');
  }

  /// Save user data to local storage
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user));
    debugPrint('✅ User data saved');
  }

  /// Get user data from local storage
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear user data from local storage
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    debugPrint('✅ User data cleared');
  }

  // ============================================
  // GENERIC HTTP METHODS
  // ============================================

  /// POST request with form data (for auth endpoints)
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
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Request failed');
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');

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

  /// GET request - with robust type conversion
  static Future<dynamic> getRequest(String endpoint) async {
    try {
      debugPrint('📤 GET: $baseUrl/$endpoint');
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle "data" wrapper if present
        dynamic data;
        if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'];
        } else {
          data = responseData;
        }

        // Convert recursively
        return _convertDeep(data);
      } else {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ GET Request Error: $e');
      rethrow;
    }
  }

  /// PUT request with JSON body
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        // ✅ EXTRACT ERROR MESSAGE FROM RESPONSE
        try {
          final responseData = json.decode(response.body);
          final errorMessage =
              responseData['error'] ??
              responseData['message'] ??
              'Request failed with status ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          // If JSON parsing fails, use generic error
          throw Exception('Request failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('❌ PUT Request Error: $e');
      rethrow;
    }
  }

  /// PUT request with form data (for FCM token updates and other form submissions)
  static Future<void> put(String endpoint, Map<String, String> data) async {
    try {
      debugPrint('📤 PUT Form to: $baseUrl/$endpoint');
      debugPrint('📤 Data: $data');

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        body: data,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');

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
  /// Helper method to convert types - ensures proper Map<String, dynamic> typing
  static Map<String, dynamic> _convertTypes(Map item) {
    final Map<String, dynamic> converted = {};
    item.forEach((key, value) {
      // Ensure key is String
      final String stringKey = key.toString();

      // Try to convert numeric strings to numbers
      if (value is String) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          converted[stringKey] = intValue;
          return;
        }

        final doubleValue = double.tryParse(value);
        if (doubleValue != null) {
          converted[stringKey] = doubleValue;
          return;
        }
      }

      // Keep original value if not convertible
      converted[stringKey] = value;
    });
    return converted;
  }

  // Recursive converter that handles nested Lists and Maps
  static dynamic _convertDeep(dynamic input) {
    if (input is List) {
      return input.map((e) => _convertDeep(e)).toList();
    } else if (input is Map) {
      // Cast keys to String and values recursively
      final Map<String, dynamic> converted = {};
      input.forEach((key, value) {
        final String strKey = key.toString();

        // Try to parse numeric strings for specific fields if needed,
        // OR just return the cleaned value.
        // For safety, let's keep values as they are but ensure Map<String, dynamic> structure
        converted[strKey] = _convertDeep(value);
      });
      return converted;
    }
    return input;
  }
}
