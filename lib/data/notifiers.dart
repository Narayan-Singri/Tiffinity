import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

ValueNotifier<int> customerSelectedPageNotifier = ValueNotifier(0);
ValueNotifier<int> adminSelectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);

// Cart management with persistence
ValueNotifier<Map<String, CartItem>> cartNotifier =
    ValueNotifier<Map<String, CartItem>>({});

// Keys for SharedPreferences
const String _cartKey = 'cart_data';
const String _pendingMessKey = 'pending_mess_name';
const String _pendingMessIdKey = 'pending_mess_id';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String messId;
  final String messName;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.messId,
    required this.messName,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'messId': messId,
      'messName': messName,
      'quantity': quantity,
    };
  }

  // Create from Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price:
          (map['price'] is String)
              ? double.tryParse(map['price']) ?? 0.0
              : (map['price']?.toDouble() ?? 0.0),
      messId: map['messId']?.toString() ?? '',
      messName: map['messName']?.toString() ?? '',
      quantity:
          (map['quantity'] is String)
              ? int.tryParse(map['quantity']) ?? 1
              : (map['quantity']?.toInt() ?? 1),
    );
  }
}

// ✅ Cart Helper Functions
class CartHelper {
  // Load cart from SharedPreferences
  static Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);

      if (cartString != null && cartString.isNotEmpty) {
        final Map<String, dynamic> cartMap = json.decode(cartString);
        final Map<String, CartItem> loadedCart = {};

        cartMap.forEach((key, value) {
          loadedCart[key] = CartItem.fromMap(value as Map<String, dynamic>);
        });

        cartNotifier.value = loadedCart;
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to SharedPreferences
  static Future<void> saveCart(Map<String, CartItem> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (cart.isEmpty) {
        await prefs.remove(_cartKey);
        return;
      }

      final Map<String, dynamic> cartMap = {};
      cart.forEach((key, value) {
        cartMap[key] = value.toMap();
      });

      final cartString = json.encode(cartMap);
      await prefs.setString(_cartKey, cartString);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Clear cart
  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      cartNotifier.value = {};
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // ✅ Save pending mess info (for post-login navigation)
  static Future<void> savePendingMess(String messName, String messId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingMessKey, messName);
      await prefs.setString(_pendingMessIdKey, messId);
      print('✅ Saved pending mess: $messName (ID: $messId)');
    } catch (e) {
      print('Error saving pending mess: $e');
    }
  }

  // ✅ Get pending mess info
  static Future<Map<String, String>?> getPendingMess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messName = prefs.getString(_pendingMessKey);
      final messId = prefs.getString(_pendingMessIdKey);

      if (messName != null && messId != null) {
        print('✅ Found pending mess: $messName (ID: $messId)');
        return {'messName': messName, 'messId': messId};
      }
      print('❌ No pending mess found');
    } catch (e) {
      print('Error getting pending mess: $e');
    }
    return null;
  }

  // ✅ Clear pending mess info
  static Future<void> clearPendingMess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingMessKey);
      await prefs.remove(_pendingMessIdKey);
      print('✅ Cleared pending mess info');
    } catch (e) {
      print('Error clearing pending mess: $e');
    }
  }
}
