import 'dart:convert';
import 'package:Tiffinity/services/api_service.dart';

class SubscriptionService {
  // ============================================
  // MESS ADMIN METHODS
  // ============================================

  /// Create a new subscription plan
  static Future<Map<String, dynamic>> createPlan({
    required int messId,
    required String name,
    required int durationDays,
    required double price,
    String? description,
  }) async {
    return await ApiService.postForm(
      'subscriptions/create_subscription_plan.php',
      {
        'mess_id': messId,
        'name': name,
        'duration_days': durationDays,
        'price': price,
        'description': description ?? '',
        'is_active': 1,
      },
    );
  }

  /// Update existing subscription plan
  static Future<Map<String, dynamic>> updatePlan({
    required int planId,
    required String name,
    required int durationDays,
    required double price,
    String? description,
  }) async {
    return await ApiService.postForm(
      'subscriptions/update_subscription_plan.php',
      {
        'plan_id': planId,
        'name': name,
        'duration_days': durationDays,
        'price': price,
        'description': description ?? '',
      },
    );
  }

  /// Get all plans for a mess
  static Future<List<Map<String, dynamic>>> getMessPlans(int messId) async {
    final response = await ApiService.getRequest(
      'subscriptions/get_mess_plans.php?mess_id=$messId',
    );

    // ✅ FIX: getRequest already extracts 'data', so response is directly the List
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    // ✅ Fallback: In case response is still wrapped (shouldn't happen)
    if (response is Map && response['data'] is List) {
      return List<Map<String, dynamic>>.from(
        response['data'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  /// Get subscribers for a specific plan
  static Future<List<Map<String, dynamic>>> getPlanSubscribers(
    int planId,
  ) async {
    final response = await ApiService.getRequest(
      'subscriptions/get_plan_subscribers.php?plan_id=$planId',
    );

    // ✅ FIX: Check if response is List first
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (response is Map && response['data'] is List) {
      return List<Map<String, dynamic>>.from(
        response['data'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  /// Toggle plan active status
  static Future<Map<String, dynamic>> togglePlanStatus(
    int planId,
    bool isActive,
  ) async {
    return await ApiService.postForm('subscriptions/toggle_plan_status.php', {
      'plan_id': planId,
      'is_active': isActive ? 1 : 0,
    });
  }

  /// Add menu for subscription
  static Future<Map<String, dynamic>> addMenu({
    required int messId,
    required String date,
    required String mealTime,
    required List<Map<String, dynamic>> items,
  }) async {
    return await ApiService.postForm(
      'subscriptions/add_subscription_menu.php',
      {
        'mess_id': messId,
        'date': date,
        'meal_time': mealTime,
        'items': jsonEncode(items),
      },
    );
  }

  /// Get menus for date range
  static Future<List<Map<String, dynamic>>> getMenus({
    required int messId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await ApiService.getRequest(
      'subscriptions/get_subscription_menu.php?mess_id=$messId&start_date=$startDate&end_date=$endDate',
    );

    // ✅ FIX: Check if response is List first
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (response is Map && response['data'] is List) {
      return List<Map<String, dynamic>>.from(
        response['data'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  // ============================================
  // CUSTOMER METHODS
  // ============================================

  /// Get available plans for a mess
  static Future<List<Map<String, dynamic>>> getAvailablePlans(
    int messId,
  ) async {
    final response = await ApiService.getRequest(
      'subscriptions/get_available_plans.php?mess_id=$messId',
    );

    // ✅ FIX: Check if response is List first
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (response is Map && response['data'] is List) {
      return List<Map<String, dynamic>>.from(
        response['data'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  /// Subscribe to a plan
  static Future<Map<String, dynamic>> subscribeToPlan({
    required int userId,
    required int planId,
    required int messId,
  }) async {
    return await ApiService.postForm('subscriptions/subscribe_to_plan.php', {
      'user_id': userId,
      'plan_id': planId,
      'mess_id': messId,
    });
  }

  /// Get user's subscriptions
  static Future<List<Map<String, dynamic>>> getMySubscriptions(
    int userId,
  ) async {
    final response = await ApiService.getRequest(
      'subscriptions/get_my_subscriptions.php?user_id=$userId',
    );

    // ✅ FIX: Check if response is List first
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (response is Map && response['data'] is List) {
      return List<Map<String, dynamic>>.from(
        response['data'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  /// Opt-out from a meal
  static Future<Map<String, dynamic>> optOutMeal({
    required int subscriptionId,
    required int userId,
    required String date,
    required String mealTime,
  }) async {
    return await ApiService.postForm('subscriptions/opt_out_meal.php', {
      'subscription_id': subscriptionId,
      'user_id': userId,
      'date': date,
      'meal_time': mealTime,
    });
  }

  /// Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    required int subscriptionId,
    required int userId,
  }) async {
    return await ApiService.postForm('subscriptions/cancel_subscription.php', {
      'subscription_id': subscriptionId,
      'user_id': userId,
    });
  }
}
