import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/notification_service.dart';

/// Notifications Screen - Full subpage with dynamic API data
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await notificationService.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          // Use cached notifications if available
          _notifications = notificationService.notifications;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await notificationService.markAllAsReadOnServer();
    if (mounted) {
      if (success) {
        setState(() {
          _notifications = notificationService.notifications;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('All notifications marked as read'), backgroundColor: AppColors.success),
        );
      } else {
        // Still update local state
        notificationService.markAllAsRead();
        setState(() {
          _notifications = notificationService.notifications;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Marked as read locally'), backgroundColor: AppColors.warning),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    await notificationService.markAsReadOnServer(notification.id);
    if (mounted) {
      setState(() {
        _notifications = notificationService.notifications;
      });
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Icons.swap_horiz;
      case NotificationType.trade:
        return Icons.candlestick_chart;
      case NotificationType.p2p:
        return Icons.people;
      case NotificationType.kyc:
        return Icons.verified;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.marketing:
        return Icons.campaign;
      case NotificationType.system:
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return AppColors.tradingBuy;
      case NotificationType.trade:
        return AppColors.primary;
      case NotificationType.p2p:
        return Colors.blue;
      case NotificationType.kyc:
        return Colors.purple;
      case NotificationType.security:
        return Colors.orange;
      case NotificationType.marketing:
        return Colors.pink;
      case NotificationType.system:
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF333333);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: subtextColor),
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: subtextColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: subtextColor),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll notify you when something important happens',
                              style: TextStyle(color: subtextColor, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Unread count banner
                          if (unreadCount > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                                style: TextStyle(color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                          // Notifications List
                          Expanded(
                            child: ListView.builder(
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return _NotificationItem(
                                  icon: _getIconForType(notification.type),
                                  iconColor: _getColorForType(notification.type),
                                  title: notification.title,
                                  message: notification.body,
                                  time: _formatTime(notification.timestamp),
                                  isRead: notification.isRead,
                                  isDark: isDark,
                                  onTap: () => _markAsRead(notification),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF333333);
    final timeColor = isDark ? Colors.grey[700] : const Color(0xFF555555);
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: subtextColor, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: timeColor, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
