import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: '成就解锁',
      message: '恭喜！你已解锁"薪资起步"成就。',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.achievement,
      isRead: false,
    ),
    NotificationItem(
      title: '薪资里程碑',
      message: '你的今日薪资已突破¥500。继续保持！',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.milestone,
      isRead: true,
    ),
    NotificationItem(
      title: '工作时间提醒',
      message: '你今日已连续工作6小时，建议休息片刻。',
      time: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.reminder,
      isRead: true,
    ),
    NotificationItem(
      title: '每周薪资报告',
      message: '你的上周薪资总额为¥3,756.20，比前一周增长15%。',
      time: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.report,
      isRead: false,
    ),
    NotificationItem(
      title: '时薪更新',
      message: '你的时薪已从¥50.00更新为¥54.30。',
      time: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.update,
      isRead: true,
    ),
    NotificationItem(
      title: '成就进度',
      message: '你的"薪资大师"成就已完成45%。',
      time: DateTime.now().subtract(const Duration(days: 4)),
      type: NotificationType.achievement,
      isRead: true,
    ),
  ];

  bool _showOnlyUnread = false;

  List<NotificationItem> get _filteredNotifications {
    if (_showOnlyUnread) {
      return _notifications
          .where((notification) => !notification.isRead)
          .toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: '全部标为已读',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Option
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              child: Row(
                children: [
                  const Text('仅显示未读通知'),
                  const Spacer(),
                  Switch(
                    value: _showOnlyUnread,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyUnread = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child:
                  _filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                        itemCount: _filteredNotifications.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return _buildNotificationItem(notification, index);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无通知',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread ? '没有未读通知' : '你目前没有任何通知',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, int index) {
    final IconData iconData = _getNotificationIcon(notification.type);
    final Color iconColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key('notification_$index'),
      background: Container(
        color: Colors.red[400],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('通知已删除'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '撤销',
              onPressed: () {
                setState(() {
                  _notifications.insert(index, notification);
                });
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isThreeLine: true,
        trailing:
            !notification.isRead
                ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.milestone:
        return Icons.flag;
      case NotificationType.reminder:
        return Icons.timer;
      case NotificationType.report:
        return Icons.bar_chart;
      case NotificationType.update:
        return Icons.update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.milestone:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.report:
        return Colors.purple;
      case NotificationType.update:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${difference.inDays} 天前';
    }
  }

  void _markAsRead(NotificationItem notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('所有通知已标为已读'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum NotificationType { achievement, milestone, reminder, report, update }

class NotificationItem {
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
