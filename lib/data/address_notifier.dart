import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ✅ ADD THIS

// Global notifier for selected address
final ValueNotifier<Map<String, dynamic>?> selectedAddressNotifier =
    ValueNotifier(null);

class AddressHelper {
  static const String _selectedAddressKey = 'selected_address';

  // Save selected address
  static Future<void> saveSelectedAddress(Map<String, dynamic> address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedAddressKey,
      jsonEncode(address),
    ); // ✅ Use JSON
    selectedAddressNotifier.value = address;
  }

  // Load selected address
  static Future<Map<String, dynamic>?> loadSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final addressString = prefs.getString(_selectedAddressKey);

    if (addressString != null) {
      return jsonDecode(addressString) as Map<String, dynamic>; // ✅ Use JSON
    }
    return null;
  }

  // Clear address
  static Future<void> clearAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAddressKey);
    selectedAddressNotifier.value = null;
  }
}
