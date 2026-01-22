// menu_service.dart
import 'package:Tiffinity/models/category_model.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'dart:convert';
import 'package:Tiffinity/models/weekly_menu_model.dart';

class MenuService {
  // In menu_service.dart - getMenuItems() method

  static Future<List<Map<String, dynamic>>> getMenuItems(int messId) async {
    try {
      print('📡 FETCHING ITEMS - mess_id: $messId');
      final response = await ApiService.getRequest(
        'menu/get_menu.php?mess_id=$messId&for_customer=false',
      );

      print('📦 RAW RESPONSE: $response');
      print('📦 Response Type: ${response.runtimeType}');

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
          'category': item['category']?.toString() ?? 'Daily Menu Items',
          'is_available':
              int.tryParse(item['is_available']?.toString() ?? '1') ?? 1,
        };
      }

      if (response is List) {
        print('✅ Response is a List with ${response.length} items');
        final items = response.map((e) => safeParse(e)).toList();
        print('✅ Parsed items: $items');
        return items;
      } else if (response is Map) {
        print('📋 Response is a Map');
        // Handle single object response or wrapped response
        if (response.containsKey('data') && response['data'] is List) {
          print(
            '✅ Found "data" key with ${(response['data'] as List).length} items',
          );
          final items =
              (response['data'] as List).map((e) => safeParse(e)).toList();
          print('✅ Parsed items: $items');
          return items;
        }
        print('⚠️ Map response, treating as single item');
        return [safeParse(response)];
      }

      print('❌ Unexpected response type, returning empty list');
      return [];
    } catch (e, stackTrace) {
      print('❌ ERROR fetching menu: $e');
      print('❌ Stack trace: $stackTrace');
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
  // ENHANCED CATEGORY METHODS
  // ============================================

  /// Fetch all categories (both default and custom)
  static Future<List<Category>> getCategories(int messId) async {
    try {
      print('🔍 FETCHING CATEGORIES - mess_id: $messId');

      final response = await ApiService.getRequest(
        'menu/get_categories.php?mess_id=$messId',
      );

      print('📦 RAW CATEGORIES RESPONSE: $response');
      print('📦 Response type: ${response.runtimeType}');

      List categoriesList;

      // ✅ HANDLE DIRECT LIST (your current API response)
      if (response is List) {
        print('✅ Response is a direct List with ${response.length} categories');
        categoriesList = response;
      }
      // ✅ ALSO HANDLE WRAPPED FORMAT (for future)
      else if (response is Map && response['data'] is List) {
        print('✅ Response is wrapped - extracting data');
        categoriesList = response['data'] as List;
      } else {
        print('❌ Unexpected response structure: ${response.runtimeType}');
        return [];
      }

      if (categoriesList.isEmpty) {
        print('⚠️ Categories list is empty');
        return [];
      }

      print('✅ Found ${categoriesList.length} raw category objects');

      // Parse each category
      final categories = <Category>[];
      for (var json in categoriesList) {
        try {
          final category = Category.fromJson(json);
          categories.add(category);
          print('   ✓ Parsed category: ${category.name} (id: ${category.id})');
        } catch (e) {
          print('   ✗ Failed to parse category: $json');
          print('     Error: $e');
        }
      }

      print('✅ Successfully loaded ${categories.length} categories');

      return categories;
    } catch (e, stackTrace) {
      print('❌ ERROR fetching categories: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Create a new category
  static Future<bool> createCategory({
    required int messId,
    required String name,
  }) async {
    try {
      final response = await ApiService.postForm('menu/create_category.php', {
        'mess_id': messId.toString(),
        'name': name,
      });
      return response['success'] == true;
    } catch (e) {
      print('❌ Error creating category: $e');
      return false;
    }
  }

  /// Update category name
  static Future<bool> updateCategory({
    required int id,
    required int messId,
    required String name,
  }) async {
    try {
      final response = await ApiService.postForm('menu/update_category.php', {
        'id': id.toString(),
        'mess_id': messId.toString(),
        'name': name,
      });
      return response['success'] == true;
    } catch (e) {
      print('❌ Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  static Future<bool> deleteCategory({
    required int id,
    required int messId,
  }) async {
    try {
      final response = await ApiService.getRequest(
        'menu/delete_category.php?id=$id&mess_id=$messId',
      );
      return response['success'] == true;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  // ============================================
  // WEEKLY MENU METHODS
  // ============================================

  /// Get weekly menu for a specific week
  /// Get weekly menu for a specific week
  /// Get weekly menu for a specific week
  static Future<List<WeeklyMenuItem>> getWeeklyMenu({
    required int messId,
    String? weekStartDate,
  }) async {
    try {
      final url =
          weekStartDate != null
              ? 'menu/weekly/get_weekly_menu.php?mess_id=$messId&week_start_date=$weekStartDate'
              : 'menu/weekly/get_weekly_menu.php?mess_id=$messId';

      final response = await ApiService.getRequest(url);

      print('📦 Weekly Menu Raw Response: $response');
      print('📦 Response Type: ${response.runtimeType}');

      // ✅ FIXED: Handle both List and Map responses
      if (response is List) {
        // Response is directly a list
        print('✅ Response is List with ${response.length} items');
        return response.map((json) => WeeklyMenuItem.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        // Response is wrapped in a Map with 'data' key
        print('✅ Response is Map with data array');
        return (response['data'] as List)
            .map((json) => WeeklyMenuItem.fromJson(json))
            .toList();
      }

      print('⚠️ Response structure unexpected, returning empty list');
      return [];
    } catch (e) {
      print('❌ Error fetching weekly menu: $e');
      return [];
    }
  }

  /// Get today's menu
  static Future<List<TodaysMenuItem>> getTodaysMenu(int messId) async {
    try {
      final response = await ApiService.getRequest(
        'menu/weekly/get_todays_menu.php?mess_id=$messId',
      );

      print('📦 getTodaysMenu Raw Response: $response');
      print('📦 Response Type: ${response.runtimeType}');

      // ✅ FIXED: Handle both List and Map responses
      List dataList;

      if (response is List) {
        // Response is directly a list
        print('✅ Response is direct List with ${response.length} items');
        dataList = response;
      } else if (response is Map && response['data'] is List) {
        // Response is wrapped in a Map with 'data' key
        print('✅ Response is Map with data array');
        dataList = response['data'] as List;
      } else {
        print('⚠️ Response structure unexpected');
        return [];
      }

      final items =
          dataList.map((json) {
            print('  Parsing item: ${json['item_name']}');
            return TodaysMenuItem.fromJson(json);
          }).toList();

      print('✅ Successfully parsed ${items.length} TodaysMenuItem objects');
      return items;
    } catch (e, stackTrace) {
      print('❌ Error fetching today\'s menu: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Add items to weekly menu
  static Future<bool> addWeeklyMenu({
    required int messId,
    required String weekStartDate,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      print('📤 Adding weekly menu items...');
      print('Mess ID: $messId');
      print('Week Start: $weekStartDate');
      print('Items: $items');

      // ✅ Convert items list to JSON string for URL encoding
      final response = await ApiService.postForm(
        'menu/weekly/add_weekly_menu.php',
        {
          'mess_id': messId.toString(),
          'week_start_date': weekStartDate,
          'items': jsonEncode(items), // ✅ Encode as JSON string
        },
      );

      print('✅ Weekly menu response: $response');
      return response['success'] == true;
    } catch (e) {
      print('❌ Error adding weekly menu: $e');
      return false;
    }
  }

  /// Update day availability for a menu item
  static Future<bool> updateDayAvailability({
    required int id,
    required String day,
    required int? availability, // 1, 0, or null
  }) async {
    try {
      final response =
          await ApiService.postForm('menu/weekly/update_day_availability.php', {
            'id': id.toString(),
            'day': day.toLowerCase(),
            'availability': availability?.toString() ?? 'null',
          });
      return response['success'] == true;
    } catch (e) {
      print('❌ Error updating day availability: $e');
      return false;
    }
  }

  /// Delete item from weekly menu
  static Future<bool> deleteWeeklyMenuItem(int id, String day) async {
    try {
      final response = await ApiService.getRequest(
        'menu/weekly/delete_weekly_menu.php?id=$id&day=$day',
      );
      return response['success'] == true;
    } catch (e) {
      print('❌ Error deleting weekly menu item: $e');
      return false;
    }
  }
}
