import 'package:Tiffinity/services/api_service.dart';

class MessService {
  // Get all online messes
  static Future<List<Map<String, dynamic>>> getAllMesses() async {
    try {
      final response = await ApiService.get('/messes');
      if (response['success']) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching messes: $e');
      return [];
    }
  }

  // Get mess by ID
  static Future<Map<String, dynamic>?> getMessById(int messId) async {
    try {
      final response = await ApiService.get('/messes/$messId');
      if (response['success']) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching mess: $e');
      return null;
    }
  }

  // Get mess by owner ID
  static Future<Map<String, dynamic>?> getMessByOwner(String ownerId) async {
    try {
      final response = await ApiService.get('/messes/owner/$ownerId');
      if (response['success']) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching owner mess: $e');
      return null;
    }
  }

  // Create new mess (for admin)
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
      final response = await ApiService.post('/messes', {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'phone': phone,
        'address': address,
        'mess_type': messType,
        'image_url': imageUrl,
        'isOnline': isOnline,
      });

      if (response['success']) {
        return {
          'success': true,
          'mess_id': response['data']['mess_id'],
          'message': 'Mess created successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to create mess',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Toggle mess online/offline status
  static Future<bool> toggleMessStatus(int messId, bool isOnline) async {
    try {
      final response = await ApiService.put('/messes/$messId/toggle-status', {
        'isOnline': isOnline,
      });
      return response['success'];
    } catch (e) {
      print('Error toggling mess status: $e');
      return false;
    }
  }
}
