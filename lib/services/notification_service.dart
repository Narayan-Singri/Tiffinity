import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/services/notification_navigation_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;

  String? _deviceToken;

  bool _isInitialized = false;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ===============================
  // INIT
  // ===============================

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();

    await _initFirebaseMessaging();

    await _registerDevice();

    _isInitialized = true;

    debugPrint("✅ NotificationService ready");
  }

  // ===============================
  // LOCAL NOTIFICATION
  // ===============================

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // ===============================
  // FIREBASE INIT
  // ===============================

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    _deviceToken = await messaging.getToken();

    debugPrint("FCM TOKEN = $_deviceToken");

    // foreground
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? "";
      final body = message.notification?.body ?? "";

      _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    });

    // tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message.data);
    });
  }

  // ===============================
  // REGISTER TOKEN TO BACKEND
  // ===============================

  Future<void> _registerDevice() async {
    try {
      final userData = await ApiService.getUserData();

      if (userData == null) return;

      final userId = userData['uid'];

      if (_deviceToken == null) return;

      if (_deviceToken != null) {
        await ApiService.put('users/update_fcm_token.php?id=$userId', {
          'fcm_token': _deviceToken!,
        });
      }

      debugPrint("✅ token saved to backend");
    } catch (e) {
      debugPrint("register error $e");
    }
  }

  // ===============================
  // SHOW LOCAL
  // ===============================

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final vibration = Int64List.fromList([0, 500, 200, 500]);

    final androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      vibrationPattern: vibration,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // ===============================
  // TAP
  // ===============================

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    final data = jsonDecode(response.payload!);

    _handleMessage(data);
  }

  void _handleMessage(Map<String, dynamic> data) async {
    final orderId = data["order_id"];

    if (orderId == null) return;

    final userData = await ApiService.getUserData();

    final role = userData?["role"];

    final context = navigatorKey.currentContext;

    if (context == null || role == null) return;

    await NotificationNavigationHelper.navigateToOrder(
      context: context,
      orderId: orderId,
      userRole: role,
    );
  }

  // ===============================
  // PUBLIC
  // ===============================

  Future<String?> getToken() async {
    return _deviceToken;
  }
}
