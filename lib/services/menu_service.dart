import 'package:Tiffinity/services/api_service.dart';

class MenuService {
  // Get all menu items for a mess
  static Future<List<Map<String, dynamic>>> getMenuItems(int messId) async {
    try {
      final response = await ApiService.get('/messes/$messId/menu');
      if (response['success']) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching menu: $e');
      return [];
    }
  }

  // Add menu item
  static Future<Map<String, dynamic>> addMenuItem({
    required int messId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String type = 'veg',
    bool isAvailable = true,
  }) async {
    try {
      final response = await ApiService.post('/menu', {
        'mess_id': messId,
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'type': type,
        'is_available': isAvailable,
      });

      if (response['success']) {
        return {
          'success': true,
          'item_id': response['data']['item_id'],
          'message': 'Menu item added',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to add item',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update menu item
  static Future<bool> updateMenuItem({
    required int itemId,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? type,
    bool? isAvailable,
  }) async {
    try {
      final response = await ApiService.put('/menu/$itemId', {
        if (name != null) 'name': name,
        if (price != null) 'price': price,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (type != null) 'type': type,
        if (isAvailable != null) 'is_available': isAvailable,
      });
      return response['success'];
    } catch (e) {
      print('Error updating menu item: $e');
      return false;
    }
  }

  // Delete menu item
  static Future<bool> deleteMenuItem(int itemId) async {
    try {
      final response = await ApiService.delete('/menu/$itemId');
      return response['success'];
    } catch (e) {
      print('Error deleting menu item: $e');
      return false;
    }
  }
}
