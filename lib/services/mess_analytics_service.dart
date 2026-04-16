// lib/services/mess_analytics_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MessAnalyticsService {
  // Replace with your actual base URL if it's imported from a config file
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  /// Fetch day-wise analytics for a specific mess
  static Future<Map<String, dynamic>> getMessAnalytics({
    required String messId,
    int days = 30, // Fetch last 30 days by default
  }) async {
    try {
      debugPrint('📊 Fetching analytics for Mess: $messId (Last $days days)');

      final response = await http.post(
        // 👇 UPDATED PATH: Now points to /orders/mess_analytics.php 👇
        Uri.parse('$baseUrl/orders/mess_analytics.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'mess_id': messId,
          'days': days.toString(),
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return jsonData; // Returns the success status, summary, and daily_data
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error (Analytics): $e');
          return {'success': false, 'message': 'Invalid server response'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('❌ Analytics API Error: $e');
      return {'success': false, 'message': 'Network error occurred. Please check your connection.'};
    }
  }
}