import 'package:Tiffinity/services/api_service.dart';

class UserService {
  // Get user by ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await ApiService.get('/users/$userId');
      if (response['success']) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }
}
