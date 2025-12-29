import '../services/api_service.dart';

class MessService {
  // ✅ FIX: Added getAllMesses method
  static Future<List<dynamic>> getAllMesses() async {
    final data = await ApiService.getRequest('messes');
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getMesses() async {
    final data = await ApiService.getRequest('messes');
    return data is List ? data : [];
  }

  // ✅ FIX: Added getMessById method
  static Future<Map<String, dynamic>?> getMessById(int messId) async {
    return await ApiService.getRequest('messes/$messId');
  }

  static Future<Map<String, dynamic>> getMess(int messId) async {
    return await ApiService.getRequest('messes/$messId');
  }

  static Future<Map<String, dynamic>?> getMessByOwner(String ownerId) async {
    return await ApiService.getRequest('messes/owner/$ownerId');
  }

  static Future<Map<String, dynamic>> createMess({
    required String name,
    required String ownerId,
    required String address,
    required String phone,
    String? description,
    String? messType,
    String? imageUrl,
    bool? isOnline,
  }) async {
    // ✅ Changed from postRequest to postForm
    return await ApiService.postForm('messes/create_mess', {
      'name': name,
      'owner_id': ownerId,
      'address': address,
      'phone': phone,
      if (description != null) 'description': description,
      if (messType != null) 'mess_type': messType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isOnline != null) 'is_online': isOnline ? '1' : '0',
    });
  }

  // ✅ FIX: Added bool status parameter
  static Future<bool> toggleMessStatus(int messId, bool status) async {
    try {
      // ✅ Changed to postForm
      await ApiService.postForm('messes/$messId/toggle-status', {
        'is_online': status ? '1' : '0',
      });
      return true;
    } catch (e) {
      print('❌ Toggle Mess Status Error: $e');
      return false;
    }
  }
}
