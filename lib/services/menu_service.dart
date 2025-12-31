// menu_service.dart
import 'package:Tiffinity/services/api_service.dart';

class MenuService {
  static Future<List<Map<String, dynamic>>> getMenuItems(int messId) async {
    try {
      final response = await ApiService.getRequest(
        'menu/get_menu.php?mess_id=$messId',
      );

      // Helper to safely parse a single item
      Map<String, dynamic> safeParse(dynamic item) {
        if (item is! Map) return {};
        return {
          'id': int.tryParse(item['id']?.toString() ?? '0') ?? 0,
          'mess_id': int.tryParse(item['mess_id']?.toString() ?? '0') ?? 0,
          'name': item['name']?.toString() ?? '',
          'description': item['description']?.toString() ?? '',
          'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'image_url': item['image_url']?.toString(),
          'type': item['type']?.toString() ?? 'veg',
          'is_available':
              int.tryParse(item['is_available']?.toString() ?? '1') ?? 1,
        };
      }

      if (response is List) {
        return response.map((e) => safeParse(e)).toList();
      } else if (response is Map) {
        // Handle single object response or wrapped response
        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List).map((e) => safeParse(e)).toList();
        }
        return [safeParse(response)];
      }

      return [];
    } catch (e) {
      print('❌ Error fetching menu: $e');
      return [];
    }
  }

  // Add menu item
  static Future<bool> addMenuItem({
    required int messId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? type,
    bool isAvailable = true,
  }) async {
    try {
      await ApiService.postForm('menu/add_menu_item.php', {
        'mess_id': messId.toString(),
        'name': name,
        'price': price.toString(),
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (type != null) 'type': type,
        'is_available': isAvailable ? '1' : '0',
      });
      return true;
    } catch (e) {
      print('❌ Error adding menu item: $e');
      return false;
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
      final body = <String, String>{'item_id': itemId.toString()};
      if (name != null) body['name'] = name;
      if (price != null) body['price'] = price.toString();
      if (description != null) body['description'] = description;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (type != null) body['type'] = type;
      if (isAvailable != null) body['is_available'] = isAvailable ? '1' : '0';

      await ApiService.postForm('menu/update_menu_item.php', body);
      return true;
    } catch (e) {
      print('❌ Error updating menu item: $e');
      return false;
    }
  }

  // Delete menu item
  static Future<bool> deleteMenuItem(int itemId) async {
    try {
      await ApiService.postForm('menu/delete_menu_item.php', {
        'item_id': itemId.toString(),
      });
      return true;
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      return false;
    }
  }
}
