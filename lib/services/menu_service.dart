// menu_service.dart
import 'package:Tiffinity/data/category_model.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuService {
  // In menu_service.dart - getMenuItems() method

  static Future<List<Map<String, dynamic>>> getMenuItems(int messId) async {
    try {
      final response = await ApiService.getRequest(
        'menu/get_menu.php?mess_id=$messId&for_customer=false',
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
          'category':
              item['category']?.toString() ??
              'Daily Menu Items', // ✅ ADD THIS LINE
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

  /// Add menu item (updated with category support)
  static Future<bool> addMenuItem({
    required int messId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? type,
    String? category, // ✨ NEW PARAMETER
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
        if (category != null) 'category': category, // ✨ NEW FIELD
        'is_available': isAvailable ? '1' : '0',
      });
      return true;
    } catch (e) {
      print('❌ Error adding menu item: $e');
      return false;
    }
  }

  /// Update menu item (updated with category support)
  static Future<bool> updateMenuItem({
    required int itemId,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? type,
    String? category, // ✨ NEW PARAMETER
    bool? isAvailable,
  }) async {
    try {
      final body = {'item_id': itemId.toString()};
      if (name != null) body['name'] = name;
      if (price != null) body['price'] = price.toString();
      if (description != null) body['description'] = description;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (type != null) body['type'] = type;
      if (category != null) body['category'] = category; // ✨ NEW FIELD
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

  // Restore deleted menu item
  static Future<bool> restoreMenuItem(int itemId) async {
    try {
      await ApiService.postForm('menu/restore_menu_item.php', {
        'item_id': itemId.toString(),
      });
      return true;
    } catch (e) {
      print('❌ Error restoring menu item: $e');
      return false;
    }
  }

  // Get deleted menu items
  static Future<List<Map<String, dynamic>>> getDeletedMenuItems(
    int messId,
  ) async {
    try {
      final response = await ApiService.getRequest(
        'menu/get_deleted_menu.php?mess_id=$messId',
      );

      if (response is List) {
        return response.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching deleted menu: $e');
      return [];
    }
  }

  // Get menu items for customers (only available items)
  static Future<List<Map<String, dynamic>>> getCustomerMenuItems(
    int messId,
  ) async {
    try {
      final response = await ApiService.getRequest(
        'menu/get_menu.php?mess_id=$messId&for_customer=true',
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
          'category':
              item['category']?.toString() ??
              'Daily Menu Items', // ✅ ADD THIS LINE
          'is_available':
              int.tryParse(item['is_available']?.toString() ?? '1') ?? 1,
        };
      }

      if (response is List) {
        return response.map((e) => safeParse(e)).toList();
      } else if (response is Map) {
        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List).map((e) => safeParse(e)).toList();
        }
        return [safeParse(response)];
      }

      return [];
    } catch (e) {
      print('❌ Error fetching customer menu: $e');
      return [];
    }
  }

  // ============================================
  // CATEGORY METHODS
  // ============================================

  /// Fetch all categories for a mess
  static Future<List<Category>> getCategories(int messId) async {
    try {
      final url =
          '${ApiService.baseUrl}/menu/get_categories.php?mess_id=$messId';
      print('📥 GET: $url');

      final response = await http.get(Uri.parse(url));
      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ Handle both response formats
        if (data is List) {
          // Direct array format
          final categories =
              data.map((json) => Category.fromJson(json)).toList();

          print('✅ Loaded ${categories.length} categories');
          return categories;
        } else if (data is Map && data['categories'] != null) {
          // Wrapped format with "categories" key
          final List<dynamic> categoriesJson = data['categories'];
          final categories =
              categoriesJson.map((json) => Category.fromJson(json)).toList();

          print('✅ Loaded ${categories.length} categories');
          return categories;
        } else {
          print('⚠️ Unexpected response format: $data');
          return [];
        }
      } else {
        print('❌ GET Request error: ${response.body}');
        throw Exception('Request failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  /// Create a new category
  static Future<bool> createCategory({
    required int messId,
    required String categoryName,
  }) async {
    try {
      // ✅ Use postForm (URL-encoded) for consistency
      final response = await ApiService.postForm('menu/create_category.php', {
        'mess_id': messId.toString(),
        'category_name': categoryName,
      });

      return response['success'] == true;
    } catch (e) {
      print('❌ Error creating category: $e');
      return false;
    }
  }

  /// Update category name
  static Future<bool> updateCategory({
    required int messId,
    required String oldName,
    required String newName,
  }) async {
    try {
      // ✅ Use postForm (URL-encoded) for consistency
      final response = await ApiService.postForm('menu/update_category.php', {
        'mess_id': messId.toString(),
        'old_name': oldName,
        'new_name': newName,
      });

      return response['success'] == true;
    } catch (e) {
      print('❌ Error updating category: $e');
      return false;
    }
  }

  /// Delete category (moves items to Daily Menu Items)
  static Future<bool> deleteCategory({
    required int messId,
    required String categoryName,
  }) async {
    try {
      // ✅ Use postForm (URL-encoded) for consistency
      final response = await ApiService.postForm('menu/delete_category.php', {
        'mess_id': messId.toString(),
        'category_name': categoryName,
      });

      return response['success'] == true;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  /// Get menu items by category
  static Future<List<Map<String, dynamic>>> getMenuItemsByCategory(
    int messId, {
    String? category,
  }) async {
    try {
      final url =
          category != null
              ? 'menu/get_menu_by_category.php?mess_id=$messId&category=${Uri.encodeComponent(category)}'
              : 'menu/get_menu_by_category.php?mess_id=$messId';

      final response = await ApiService.getRequest(url);

      if (response is Map && response['success'] == true) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response is List) {
        return response.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching menu by category: $e');
      return [];
    }
  }

  /// Assign multiple items to a category
  static Future<bool> assignItemsToCategory({
    required int messId,
    required List<int> itemIds,
    required String categoryName,
  }) async {
    try {
      // ✅ Convert list to comma-separated string for URL encoding
      final response = await ApiService.postForm(
        'menu/assign_items_to_category.php',
        {
          'mess_id': messId.toString(),
          'item_ids': itemIds.join(','), // ✅ Convert to comma-separated string
          'category_name': categoryName,
        },
      );
      return response['success'] == true;
    } catch (e) {
      print('❌ Error assigning items to category: $e');
      return false;
    }
  }
}
