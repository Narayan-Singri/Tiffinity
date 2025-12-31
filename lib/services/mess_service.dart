// ✅ FIXED mess_service.dart - Matching your ApiService methods
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MessService {
  // ✅ FIXED: Correct folder path with defensive parsing
  static Future<List<dynamic>> getAllMesses() async {
    try {
      final data = await ApiService.getRequest('messes/get_messes.php');

      // ✅ FIX: Defensive response parsing
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(
          data['data'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('messes')) {
        return List<Map<String, dynamic>>.from(
          data['messes'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get All Messes Error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMesses() async {
    try {
      final data = await ApiService.getRequest('messes/get_messes.php');

      // ✅ FIX: Defensive response parsing
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(
          data['data'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map && data.containsKey('messes')) {
        return List<Map<String, dynamic>>.from(
          data['messes'].map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get Messes Error: $e');
      return [];
    }
  }

  // ✅ FIXED: Correct folder path with query parameter
  static Future<Map<String, dynamic>?> getMessById(int messId) async {
    try {
      final data = await ApiService.getRequest(
        'messes/get_mess.php?id=$messId',
      );

      // ✅ FIX: Return proper map or null
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get Mess By ID Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getMess(int messId) async {
    try {
      final data = await ApiService.getRequest(
        'messes/get_mess.php?id=$messId',
      );

      // ✅ FIX: Return proper map
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0]);
      }
      return {};
    } catch (e) {
      debugPrint('❌ Get Mess Error: $e');
      return {};
    }
  }

  // ✅ FIXED: Correct folder path with query parameter
  static Future<Map<String, dynamic>?> getMessByOwner(String ownerId) async {
    try {
      final data = await ApiService.getRequest(
        'messes/get_mess_by_owner.php?owner_id=$ownerId',
      );

      // ✅ FIX: Return proper map or null
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get Mess By Owner Error: $e');
      return null;
    }
  }

  // ✅ FIXED: Correct folder path
  static Future<Map<String, dynamic>> createMess({
    required String ownerId,
    required String name,
    required String description,
    required String phone,
    required String address,
    required String messType,
    String? imageUrl,
    bool isOnline = true,
  }) async {
    try {
      debugPrint('📤 Creating mess...');
      final response = await ApiService.postForm('messes/create_mess.php', {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'phone': phone,
        'address': address,
        'mess_type': messType,
        if (imageUrl != null) 'image_url': imageUrl,
        'isOnline': isOnline ? '1' : '0',
      });

      debugPrint('📥 Create Mess Response: $response');

      if (response['message'] == 'Mess created') {
        return {
          'success': true,
          'mess_id': response['mess_id'],
          'message': 'Mess created successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['error'] ?? 'Failed to create mess',
        };
      }
    } catch (e) {
      debugPrint('❌ Create Mess Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ✅ FIXED: Correct folder path with query parameter
  static Future<bool> toggleMessStatus(int messId, bool status) async {
    try {
      await ApiService.postForm('messes/toggle_mess_status.php?id=$messId', {
        'isOnline': status ? '1' : '0',
      });
      return true;
    } catch (e) {
      debugPrint('❌ Toggle Mess Status Error: $e');
      return false;
    }
  }
}
