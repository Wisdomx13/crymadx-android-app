import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message
}

/// Notification types
enum NotificationType {
  transaction,
  trade,
  p2p,
  kyc,
  security,
  marketing,
  system,
}

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'CrymadX',
      body: message.notification?.body ?? '',
      type: _parseType(message.data['type']),
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'transaction':
        return NotificationType.transaction;
      case 'trade':
        return NotificationType.trade;
      case 'p2p':
        return NotificationType.p2p;
      case 'kyc':
        return NotificationType.kyc;
      case 'security':
        return NotificationType.security;
      case 'marketing':
        return NotificationType.marketing;
      default:
        return NotificationType.system;
    }
  }
}

/// Notification service for push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final _notificationController = StreamController<AppNotification>.broadcast();
  final List<AppNotification> _notifications = [];

  String? _fcmToken;
  bool _isInitialized = false;

  /// Stream of incoming notifications
  Stream<AppNotification> get onNotification => _notificationController.stream;

  /// Get all notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Initialize local notifications
      await _initLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from notification)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'crymadx_channel',
        'CrymadX Notifications',
        description: 'Notifications from CrymadX',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final notification = AppNotification.fromRemoteMessage(message);
    _notifications.insert(0, notification);
    _notificationController.add(notification);

    // Show local notification
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'crymadx_channel',
      'CrymadX Notifications',
      channelDescription: 'Notifications from CrymadX',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');
    final notification = AppNotification.fromRemoteMessage(message);
    _navigateFromNotification(notification);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateFromData(data);
    }
  }

  void _navigateFromNotification(AppNotification notification) {
    // Navigation will be handled by the app based on notification type
    switch (notification.type) {
      case NotificationType.transaction:
        // Navigate to transaction details
        break;
      case NotificationType.trade:
        // Navigate to trade/order details
        break;
      case NotificationType.p2p:
        // Navigate to P2P trade
        break;
      case NotificationType.kyc:
        // Navigate to KYC screen
        break;
      case NotificationType.security:
        // Navigate to security settings
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case 'transaction':
        // Navigate to transaction with id
        break;
      case 'trade':
        // Navigate to trade with id
        break;
      case 'p2p':
        // Navigate to P2P trade with id
        break;
      default:
        break;
    }
  }

  void _onTokenRefresh(String token) {
    debugPrint('FCM Token refreshed: $token');
    _fcmToken = token;
    _registerTokenWithBackend(token);
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Send token to backend
      await api.post(
        '/user/push-token',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Register current token with backend (call after login)
  Future<void> registerToken() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        data: _notifications[index].data,
        timestamp: _notifications[index].timestamp,
        isRead: true,
      );
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          title: _notifications[i].title,
          body: _notifications[i].body,
          type: _notifications[i].type,
          data: _notifications[i].data,
          timestamp: _notifications[i].timestamp,
          isRead: true,
        );
      }
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  /// Show a local notification (for app-generated notifications)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'crymadx_channel',
      'CrymadX Notifications',
      channelDescription: 'Notifications from CrymadX',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Dispose the service
  void dispose() {
    _notificationController.close();
  }
}

/// Global notification service instance
final notificationService = NotificationService();
