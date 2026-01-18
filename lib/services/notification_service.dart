import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'CrymadX',
      body: json['body'] ?? json['message'] ?? '',
      type: _parseType(json['type']),
      data: json['data'],
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] ?? json['read'] ?? false,
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

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<AppNotification>.broadcast();
  final List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  /// Stream of incoming notifications
  Stream<AppNotification> get onNotification => _notificationController.stream;

  /// Get all notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Fetch initial notifications from backend
      await fetchNotifications();
      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Mark notification as read (local)
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Mark all notifications as read (local)
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  /// Add a notification manually (for testing or local notifications)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);
  }

  // ============================================
  // BACKEND API METHODS
  // ============================================

  /// Fetch notifications from backend API
  Future<List<AppNotification>> fetchNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await api.get(
        ApiConfig.notificationsList,
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> items = response['notifications'] ?? response['items'] ?? response['data'] ?? [];
      final notifications = items.map((item) => AppNotification.fromJson(item)).toList();

      // Update local cache
      if (page == 1) {
        _notifications.clear();
      }
      _notifications.addAll(notifications);

      return notifications;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Return cached notifications if API fails
      return _notifications;
    }
  }

  /// Mark a notification as read on backend
  Future<bool> markAsReadOnServer(String notificationId) async {
    try {
      await api.post(
        ApiConfig.notificationsMarkRead,
        data: {'notificationId': notificationId},
      );

      // Update local state
      markAsRead(notificationId);
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read on backend
  Future<bool> markAllAsReadOnServer() async {
    try {
      await api.post(ApiConfig.notificationsMarkAllRead);

      // Update local state
      markAllAsRead();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread count from backend
  Future<int> fetchUnreadCount() async {
    try {
      final response = await api.get(ApiConfig.notificationsUnreadCount);
      return response['count'] ?? response['unreadCount'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return unreadCount; // Return local count
    }
  }

  /// Dispose the service
  void dispose() {
    _notificationController.close();
  }
}

/// Global notification service instance
final notificationService = NotificationService();
