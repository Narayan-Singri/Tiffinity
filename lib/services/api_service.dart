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
    Map<String, String> data,
  ) async {
    try {
      debugPrint('📤 POST Form to: $baseUrl/$endpoint');
      debugPrint('📤 Data: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        body: data,
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

  /// GET request - returns data field from response
  static Future<dynamic> getRequest(String endpoint) async {
    try {
      debugPrint('📤 GET: $baseUrl/$endpoint');

      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Return the 'data' field if it exists, otherwise return full response
        return responseData['data'] ?? responseData;
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

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        throw Exception('Request failed');
      }
    } catch (e) {
      debugPrint('❌ PUT Request Error: $e');
      rethrow;
    }
  }

  /// PUT request with form data (legacy - for FCM token updates)
  static Future<void> put(String endpoint, Map<String, String> data) async {
    try {
      debugPrint('📤 PUT Form to: $baseUrl/$endpoint');

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        body: data,
      );

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
  // AUTH ENDPOINTS (Legacy methods for backward compatibility)
  // ============================================

  /// Register new user (legacy method)
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      print('📤 Registering user...');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'role': role,
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Server error');
      }
    } catch (e) {
      print('❌ Registration Error: $e');
      rethrow;
    }
  }

  /// Login user (legacy method)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📤 Logging in...');
      print('📤 Form Data: {email: $email, password: $password}');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      rethrow;
    }
  }

  // ============================================
  // MESS ENDPOINTS (Legacy methods)
  // ============================================

  /// Get all messes (legacy method)
  static Future<List<dynamic>> getMesses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messes'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load messes');
      }
    } catch (e) {
      debugPrint('❌ Get Messes Error: $e');
      rethrow;
    }
  }

  /// Get single mess by ID (legacy method)
  static Future<Map<String, dynamic>> getMess(int messId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messes/$messId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load mess');
      }
    } catch (e) {
      debugPrint('❌ Get Mess Error: $e');
      rethrow;
    }
  }

  /// Get mess by owner ID (legacy method)
  static Future<Map<String, dynamic>> getMessByOwner(String ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messes/owner/$ownerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load mess');
      }
    } catch (e) {
      debugPrint('❌ Get Mess By Owner Error: $e');
      rethrow;
    }
  }

  /// Create new mess (legacy method)
  static Future<Map<String, dynamic>> createMess({
    required String name,
    required String ownerId,
    required String address,
    required String phone,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messes/create'),
        body: {
          'name': name,
          'owner_id': ownerId,
          'address': address,
          'phone': phone,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to create mess');
      }
    } catch (e) {
      debugPrint('❌ Create Mess Error: $e');
      rethrow;
    }
  }

  /// Toggle mess status (legacy method)
  static Future<void> toggleMessStatus(int messId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messes/$messId/toggle-status'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle mess status');
      }
    } catch (e) {
      debugPrint('❌ Toggle Mess Status Error: $e');
      rethrow;
    }
  }

  // ============================================
  // MENU ENDPOINTS (Legacy methods)
  // ============================================

  /// Get menu for a mess (legacy method)
  static Future<List<dynamic>> getMenu(int messId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messes/$messId/menu'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      debugPrint('❌ Get Menu Error: $e');
      rethrow;
    }
  }

  /// Add menu item (legacy method)
  static Future<Map<String, dynamic>> addMenuItem({
    required int messId,
    required String name,
    required String category,
    required double price,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/menu'),
        body: {
          'mess_id': messId.toString(),
          'name': name,
          'category': category,
          'price': price.toString(),
          if (description != null) 'description': description,
          if (imageUrl != null) 'image_url': imageUrl,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to add menu item');
      }
    } catch (e) {
      debugPrint('❌ Add Menu Item Error: $e');
      rethrow;
    }
  }

  /// Update menu item (legacy method)
  static Future<void> updateMenuItem({
    required int itemId,
    String? name,
    String? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/menu/$itemId'),
        body: {
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (price != null) 'price': price.toString(),
          if (description != null) 'description': description,
          if (imageUrl != null) 'image_url': imageUrl,
          if (isAvailable != null) 'is_available': isAvailable ? '1' : '0',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update menu item');
      }
    } catch (e) {
      debugPrint('❌ Update Menu Item Error: $e');
      rethrow;
    }
  }

  /// Delete menu item (legacy method)
  static Future<void> deleteMenuItem(int itemId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/menu/$itemId'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu item');
      }
    } catch (e) {
      debugPrint('❌ Delete Menu Item Error: $e');
      rethrow;
    }
  }

  // ============================================
  // ORDER ENDPOINTS (Legacy methods)
  // ============================================

  /// Create order (legacy method)
  static Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required int messId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'mess_id': messId,
          'items': items,
          'total_amount': totalAmount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Create Order Error: $e');
      rethrow;
    }
  }

  /// Get order by ID (legacy method)
  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$orderId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load order');
      }
    } catch (e) {
      debugPrint('❌ Get Order Error: $e');
      rethrow;
    }
  }

  /// Get customer orders (legacy method)
  static Future<List<dynamic>> getCustomerOrders(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/customer/$customerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      debugPrint('❌ Get Customer Orders Error: $e');
      rethrow;
    }
  }

  /// Get mess orders (legacy method)
  static Future<List<dynamic>> getMessOrders(int messId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/mess/$messId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      debugPrint('❌ Get Mess Orders Error: $e');
      rethrow;
    }
  }

  /// Update order status (legacy method)
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        body: {'status': status},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      debugPrint('❌ Update Order Status Error: $e');
      rethrow;
    }
  }

  // ============================================
  // USER ENDPOINTS (Legacy methods)
  // ============================================

  /// Get user by ID (legacy method)
  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load user');
      }
    } catch (e) {
      debugPrint('❌ Get User Error: $e');
      rethrow;
    }
  }

  /// Update FCM token (legacy method)
  static Future<void> updateFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/fcm-token'),
        body: {'fcm_token': fcmToken},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update FCM token');
      }
    } catch (e) {
      debugPrint('❌ Update FCM Token Error: $e');
      rethrow;
    }
  }
}
