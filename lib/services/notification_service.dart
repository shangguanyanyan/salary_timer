import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';

class NotificationService extends ChangeNotifier {
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

  // 获取所有通知
  List<NotificationItem> get notifications => _notifications;

  // 获取未读通知数量
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  // 获取未读通知
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((notification) => !notification.isRead).toList();

  // 标记指定通知为已读
  void markAsRead(NotificationItem notification) {
    if (!notification.isRead) {
      notification.isRead = true;
      notifyListeners();
    }
  }

  // 标记所有通知为已读
  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  // 添加新通知
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // 删除通知
  void removeNotification(NotificationItem notification) {
    _notifications.remove(notification);
    notifyListeners();
  }
}
