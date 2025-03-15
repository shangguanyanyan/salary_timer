import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/data_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showOnlyUnread = false;

  List<NotificationItem> _getFilteredNotifications(
    NotificationService service,
  ) {
    if (_showOnlyUnread) {
      return service.unreadNotifications;
    }
    return service.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final dataProvider = Provider.of<DataProvider>(context);
        final filteredNotifications = _getFilteredNotifications(
          notificationService,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('通知'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: notificationService.markAllAsRead,
                tooltip: '全部标为已读',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter Option
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                      filteredNotifications.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                            itemCount: filteredNotifications.length,
                            separatorBuilder:
                                (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              return _buildNotificationItem(
                                notification,
                                index,
                                notificationService,
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildNotificationItem(
    NotificationItem notification,
    int index,
    NotificationService service,
  ) {
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
        service.removeNotification(notification);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('通知已删除'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '撤销',
              onPressed: () {
                service.addNotification(notification);
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
        onTap: () => service.markAsRead(notification),
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
}

enum NotificationType { achievement, milestone, reminder, report, update }

class NotificationItem {
  final String? id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
