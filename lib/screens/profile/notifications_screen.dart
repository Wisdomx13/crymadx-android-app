import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// Notifications Screen - Full subpage
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notification> _notifications = [
    _Notification(
      icon: Icons.trending_up,
      title: 'BTC Price Alert',
      message: 'Bitcoin reached \$92,655.70',
      time: '2 min ago',
      type: 'price',
      isRead: false,
    ),
    _Notification(
      icon: Icons.check_circle,
      title: 'Deposit Successful',
      message: 'Your deposit of 500 USDT has been confirmed',
      time: '15 min ago',
      type: 'success',
      isRead: false,
    ),
    _Notification(
      icon: Icons.swap_horiz,
      title: 'Trade Executed',
      message: 'Buy order for 0.01 BTC completed at \$92,500',
      time: '1 hour ago',
      type: 'trade',
      isRead: true,
    ),
    _Notification(
      icon: Icons.security,
      title: 'Security Alert',
      message: 'New login detected from Chrome on Windows',
      time: '3 hours ago',
      type: 'security',
      isRead: true,
    ),
    _Notification(
      icon: Icons.campaign,
      title: 'New Promotion',
      message: 'Trade & Win Campaign - Up to \$600,000 in prizes!',
      time: '5 hours ago',
      type: 'promo',
      isRead: true,
    ),
    _Notification(
      icon: Icons.people,
      title: 'New Referral',
      message: 'j***@gmail.com signed up using your referral code',
      time: 'Yesterday',
      type: 'referral',
      isRead: true,
    ),
    _Notification(
      icon: Icons.trending_down,
      title: 'ETH Price Alert',
      message: 'Ethereum dropped below \$2,200',
      time: 'Yesterday',
      type: 'price',
      isRead: true,
    ),
    _Notification(
      icon: Icons.verified,
      title: 'KYC Update',
      message: 'Your identity verification is pending review',
      time: '2 days ago',
      type: 'kyc',
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('All notifications marked as read'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
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
      body: Column(
        children: [
          // Unread count
          if (unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.1),
              child: Text(
                '$unreadCount unread notifications',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          // Notifications List
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) => _NotificationItem(
                notification: _notifications[index],
                onTap: () {
                  setState(() {
                    _notifications[index].isRead = true;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notification {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final String type;
  bool isRead;

  _Notification({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

class _NotificationItem extends StatelessWidget {
  final _Notification notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  Color get _iconColor {
    switch (notification.type) {
      case 'price':
        return notification.icon == Icons.trending_up ? AppColors.tradingBuy : AppColors.tradingSell;
      case 'success':
        return AppColors.tradingBuy;
      case 'trade':
        return AppColors.primary;
      case 'security':
        return Colors.orange;
      case 'promo':
        return Colors.purple;
      case 'referral':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(notification.icon, color: _iconColor, size: 20),
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
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
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
                    notification.message,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(notification.time, style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
