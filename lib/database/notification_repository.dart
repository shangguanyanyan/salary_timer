import 'package:sqflite/sqflite.dart';
import '../screens/notifications_screen.dart';
import 'database_helper.dart';

class NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 插入通知
  Future<void> insert(NotificationItem notification) async {
    final db = await _dbHelper.database;
    await db.insert('notifications', {
      'id': notification.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': notification.title,
      'message': notification.message,
      'time': notification.time.toIso8601String(),
      'type': notification.type.toString().split('.').last,
      'is_read': notification.isRead ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 获取所有通知
  Future<List<NotificationItem>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('notifications', orderBy: 'time DESC');

    return List.generate(maps.length, (i) {
      return NotificationItem(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        message: maps[i]['message'] as String,
        time: DateTime.parse(maps[i]['time'] as String),
        type: _parseNotificationType(maps[i]['type'] as String),
        isRead: (maps[i]['is_read'] as int) == 1,
      );
    });
  }

  // 获取未读通知
  Future<List<NotificationItem>> getUnread() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'time DESC',
    );

    return List.generate(maps.length, (i) {
      return NotificationItem(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        message: maps[i]['message'] as String,
        time: DateTime.parse(maps[i]['time'] as String),
        type: _parseNotificationType(maps[i]['type'] as String),
        isRead: false,
      );
    });
  }

  // 获取未读通知数量
  Future<int> getUnreadCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 标记通知为已读
  Future<void> markAsRead(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 标记所有通知为已读
  Future<void> markAllAsRead() async {
    final db = await _dbHelper.database;
    await db.update('notifications', {'is_read': 1});
  }

  // 删除通知
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  // 清空所有通知
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('notifications');
  }

  // 解析通知类型
  NotificationType _parseNotificationType(String typeString) {
    switch (typeString) {
      case 'achievement':
        return NotificationType.achievement;
      case 'milestone':
        return NotificationType.milestone;
      case 'reminder':
        return NotificationType.reminder;
      case 'report':
        return NotificationType.report;
      case 'update':
        return NotificationType.update;
      default:
        return NotificationType.update;
    }
  }
}
