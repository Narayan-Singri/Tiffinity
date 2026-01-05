import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:Tiffinity/services/notification_navigation_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  String? _deviceToken;
  int _lastNotificationId = 0;
  bool _isInitialized = false;

  // ✅ Global Navigator Key for navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Generate or retrieve device token
      _deviceToken = await _getOrCreateDeviceToken();
      debugPrint('✅ Device Token: $_deviceToken');

      // Register device with backend
      await _registerDevice();

      // Start polling for notifications
      _startPolling();

      _isInitialized = true;
      debugPrint('✅ Custom Notification Service Initialized');
    } catch (e) {
      debugPrint('❌ Notification Service Error: $e');
    }
  }

  // ============================================
  // LOCAL NOTIFICATIONS SETUP
  // ============================================

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    debugPrint('✅ Local Notifications Initialized');
  }

  // ============================================
  // DEVICE TOKEN MANAGEMENT
  // ============================================

  Future<String?> _getOrCreateDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('device_token');

    if (token == null || token.isEmpty) {
      // Generate new UUID-based device token
      token = const Uuid().v4();
      await prefs.setString('device_token', token);
      debugPrint('🆕 Generated Device Token: $token');
    } else {
      debugPrint('♻️ Existing Device Token: $token');
    }

    return token;
  }

  Future<void> _registerDevice() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData == null || _deviceToken == null) {
        debugPrint('⚠️ Cannot register device: No user data or token');
        return;
      }

      final userId = userData['uid'];
      // Call update_fcm_token.php in users folder
      await ApiService.put('users/update_fcm_token.php?id=$userId', {
        'fcm_token': _deviceToken!,
      });
      debugPrint('✅ Device registered with backend');
    } catch (e) {
      debugPrint('❌ Device registration failed: $e');
    }
  }

  // ============================================
  // POLLING MECHANISM
  // ============================================

  void _startPolling() {
    // Poll every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchNotifications();
    });

    // Fetch immediately on start
    _fetchNotifications();
    debugPrint('🔄 Polling started (every 30 seconds)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    debugPrint('⏸️ Polling stopped');
  }

  Future<void> _fetchNotifications() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData == null) return;

      final userId = userData['uid'];

      // Fetch unread notifications from backend
      final response = await ApiService.getRequest(
        'notifications/fetch_notifications.php?user_id=$userId&last_id=$_lastNotificationId',
      );

      if (response is List && response.isNotEmpty) {
        debugPrint('📬 Fetched ${response.length} new notifications');

        for (var notification in response) {
          // Parse notification data
          Map<String, dynamic>? notificationData;
          if (notification['data'] != null) {
            try {
              notificationData = jsonDecode(notification['data']);
            } catch (e) {
              debugPrint('⚠️ Failed to parse notification data: $e');
            }
          }

          _showLocalNotification(
            id:
                int.tryParse(notification['id'].toString()) ??
                DateTime.now().millisecond,
            title: notification['title'] ?? 'New Notification',
            body: notification['body'] ?? '',
            payload: jsonEncode({
              'type': notification['type'],
              'order_id': notification['order_id'],
              'data': notificationData,
            }),
          );

          // Update last notification ID
          int notifId = int.tryParse(notification['id'].toString()) ?? 0;
          if (notifId > _lastNotificationId) {
            _lastNotificationId = notifId;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Fetch notifications error: $e');
    }
  }

  // ============================================
  // DISPLAY NOTIFICATIONS
  // ============================================

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_channel',
          'Order Notifications',
          channelDescription: 'Notifications for orders and updates',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('🔔 Notification displayed: $title');
  }

  // ============================================
  // NOTIFICATION TAP HANDLER
  // ============================================

  void _onNotificationTap(NotificationResponse response) async {
    debugPrint('👆 Notification tapped: ${response.payload}');

    if (response.payload == null) return;

    try {
      final payload = jsonDecode(response.payload!);
      final String? orderId = payload['order_id'];

      if (orderId == null || orderId.isEmpty) {
        debugPrint('⚠️ No order ID in notification payload');
        return;
      }

      // Get user role
      final userData = await ApiService.getUserData();
      final String? userRole = userData?['role'];

      final context = navigatorKey.currentContext;
      if (context == null || userRole == null) {
        debugPrint('⚠️ No navigation context or user role');
        return;
      }

      // Import the navigation helper at the top of the file
      // Then use it here:
      await NotificationNavigationHelper.navigateToOrder(
        context: context,
        orderId: orderId,
        userRole: userRole,
      );
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  // Helper methods to build pages (avoid circular imports)
  Widget _buildOrderTrackingPage(String orderId) {
    // Dynamically import to avoid circular dependency
    return Builder(
      builder: (context) {
        // Use dynamic import with error handling
        try {
          final orderTrackingModule = const Symbol(
            'package:Tiffinity/views/pages/customer_pages/order_tracking_page.dart',
          );
          return Container(); // Placeholder - actual page loaded below
        } catch (e) {
          debugPrint('Error loading OrderTrackingPage: $e');
          return Scaffold(
            appBar: AppBar(title: const Text('Order Tracking')),
            body: Center(child: Text('Order #$orderId')),
          );
        }
      },
    );
  }

  Widget _buildOrderDetailsPage(String orderId) {
    return Builder(
      builder: (context) {
        try {
          final orderDetailsModule = const Symbol(
            'package:Tiffinity/views/pages/admin_pages/order_details_page.dart',
          );
          return Container(); // Placeholder
        } catch (e) {
          debugPrint('Error loading OrderDetailsPage: $e');
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: Center(child: Text('Order #$orderId')),
          );
        }
      },
    );
  }

  // ============================================
  // PUBLIC METHODS
  // ============================================

  /// Manual notification (for testing)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _showLocalNotification(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
    );
  }

  /// Get device token
  Future<String?> getDeviceToken() async {
    return _deviceToken;
  }

  /// Force refresh notifications
  Future<void> refreshNotifications() async {
    await _fetchNotifications();
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
  }
}
