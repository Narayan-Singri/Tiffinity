import '../services/api_service.dart';

class MenuService {
  // Get all menu items for a mess
  static Future<List<Map<String, dynamic>>> getMenuItems(int messId) async {
    try {
      final data = await ApiService.getRequest('menu/$messId'); // ✅ Clean URL
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching menu: $e');
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
      final response = await ApiService.postRequest('menu/items', {
        // ✅ Clean URL
        'mess_id': messId.toString(),
        'name': name,
        'price': price.toString(),
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        'type': type,
        'is_available': isAvailable ? '1' : '0',
      });

      return {
        'success': true,
        'item_id': response['item_id'] ?? response['id'],
        'message': 'Menu item added successfully',
      };
    } catch (e) {
      print('❌ Error adding menu item: $e');
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
      await ApiService.putRequest('menu/items/$itemId', {
        // ✅ Clean URL
        if (name != null) 'name': name,
        if (price != null) 'price': price.toString(),
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (type != null) 'type': type,
        if (isAvailable != null) 'is_available': isAvailable ? '1' : '0',
      });
      return true;
    } catch (e) {
      print('❌ Error updating menu item: $e');
      return false;
    }
  }

  // Delete menu item
  static Future<bool> deleteMenuItem(int itemId) async {
    try {
      await ApiService.deleteRequest('menu/items/$itemId'); // ✅ Clean URL
      return true;
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      return false;
    }
  }
}
