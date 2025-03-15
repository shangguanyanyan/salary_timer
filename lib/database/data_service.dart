import 'package:flutter/material.dart';
import '../models/earning_record.dart';
import '../screens/notifications_screen.dart';
import 'database_helper.dart';
import 'earning_repository.dart';
import 'milestone_repository.dart';
import 'notification_repository.dart';
import 'settings_repository.dart';
import 'work_log_repository.dart';

class DataService {
  static final DataService instance = DataService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final EarningRepository _earningRepository = EarningRepository();
  final MilestoneRepository _milestoneRepository = MilestoneRepository();
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final WorkLogRepository _workLogRepository = WorkLogRepository();

  DataService._init();

  // 初始化数据库
  Future<void> initialize() async {
    await _dbHelper.database;
  }

  // 关闭数据库
  Future<void> close() async {
    await _dbHelper.close();
  }

  // ===== 收入记录相关方法 =====

  // 添加收入记录
  Future<void> addEarning(
    double amount,
    Duration workDuration,
    double hourlyRate,
  ) async {
    final record = EarningRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      workDuration: workDuration,
      hourlyRate: hourlyRate,
    );
    await _earningRepository.insert(record);
  }

  // 获取所有收入记录
  Future<List<EarningRecord>> getAllEarnings() async {
    return await _earningRepository.getAll();
  }

  // 获取今日收入
  Future<double> getTodayEarnings() async {
    return await _earningRepository.getTodayEarnings();
  }

  // 获取本周收入
  Future<double> getWeekEarnings() async {
    return await _earningRepository.getWeekEarnings();
  }

  // 获取本月收入
  Future<double> getMonthEarnings() async {
    return await _earningRepository.getMonthEarnings();
  }

  // 获取总收入
  Future<double> getTotalEarnings() async {
    return await _earningRepository.getTotalEarnings();
  }

  // 获取按日期分组的收入记录
  Future<Map<String, List<EarningRecord>>> getGroupedEarnings() async {
    final records = await _earningRepository.getAll();
    final Map<String, List<EarningRecord>> grouped = {};

    for (final record in records) {
      final dateStr = _formatDateKey(record.date);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(record);
    }

    return grouped;
  }

  // 格式化日期为键
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===== 工作日志相关方法 =====

  // 添加工作日志
  Future<void> addWorkLog({
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required Duration regularTime,
    required Duration overtimeTime,
    required double regularEarnings,
    required double overtimeEarnings,
    required double totalEarnings,
    required double hourlyRate,
    required double overtimeRate,
  }) async {
    final log = WorkLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      regularTime: regularTime,
      overtimeTime: overtimeTime,
      regularEarnings: regularEarnings,
      overtimeEarnings: overtimeEarnings,
      totalEarnings: totalEarnings,
      hourlyRate: hourlyRate,
      overtimeRate: overtimeRate,
    );
    await _workLogRepository.insert(log);
  }

  // 获取所有工作日志
  Future<List<WorkLog>> getAllWorkLogs() async {
    return await _workLogRepository.getAll();
  }

  // 获取今日工作时长
  Future<Duration> getTodayWorkDuration() async {
    return await _workLogRepository.getTodayWorkDuration();
  }

  // 获取本周工作时长
  Future<Duration> getWeekWorkDuration() async {
    return await _workLogRepository.getWeekWorkDuration();
  }

  // 获取本月工作时长
  Future<Duration> getMonthWorkDuration() async {
    return await _workLogRepository.getMonthWorkDuration();
  }

  // ===== 通知相关方法 =====

  // 添加通知
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: DateTime.now(),
      type: type,
      isRead: false,
    );
    await _notificationRepository.insert(notification);
  }

  // 获取所有通知
  Future<List<NotificationItem>> getAllNotifications() async {
    return await _notificationRepository.getAll();
  }

  // 获取未读通知
  Future<List<NotificationItem>> getUnreadNotifications() async {
    return await _notificationRepository.getUnread();
  }

  // 获取未读通知数量
  Future<int> getUnreadNotificationCount() async {
    return await _notificationRepository.getUnreadCount();
  }

  // 标记通知为已读
  Future<void> markNotificationAsRead(String id) async {
    await _notificationRepository.markAsRead(id);
  }

  // 标记所有通知为已读
  Future<void> markAllNotificationsAsRead() async {
    await _notificationRepository.markAllAsRead();
  }

  // ===== 设置相关方法 =====

  // 保存时薪
  Future<void> saveHourlyRate(double rate) async {
    await _settingsRepository.saveHourlyRate(rate);
  }

  // 获取时薪
  Future<double> getHourlyRate() async {
    return await _settingsRepository.getHourlyRate();
  }

  // 保存自动计时设置
  Future<void> saveAutoTimingSettings({
    required bool enabled,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<bool> workDays,
  }) async {
    await _settingsRepository.saveAutoTimingEnabled(enabled);
    await _settingsRepository.saveAutoStartTime(startTime);
    await _settingsRepository.saveAutoEndTime(endTime);
    await _settingsRepository.saveWorkDays(workDays);
  }

  // 获取自动计时启用状态
  Future<bool> getAutoTimingEnabled() async {
    return await _settingsRepository.getAutoTimingEnabled();
  }

  // 获取自动开始时间
  Future<TimeOfDay> getAutoStartTime() async {
    return await _settingsRepository.getAutoStartTime();
  }

  // 获取自动结束时间
  Future<TimeOfDay> getAutoEndTime() async {
    return await _settingsRepository.getAutoEndTime();
  }

  // 获取工作日设置
  Future<List<bool>> getWorkDays() async {
    return await _settingsRepository.getWorkDays();
  }

  // 保存加班设置
  Future<void> saveOvertimeSettings({
    required bool enabled,
    required int regularHoursLimit,
    required double overtimeRate,
  }) async {
    await _settingsRepository.saveOvertimeSettings(
      enabled: enabled,
      regularHoursLimit: regularHoursLimit,
      overtimeRate: overtimeRate,
    );
  }

  // 获取加班启用状态
  Future<bool> getOvertimeEnabled() async {
    return await _settingsRepository.getOvertimeEnabled();
  }

  // 获取正常工作时间上限
  Future<int> getRegularHoursLimit() async {
    return await _settingsRepository.getRegularHoursLimit();
  }

  // 获取加班工资倍率
  Future<double> getOvertimeRate() async {
    return await _settingsRepository.getOvertimeRate();
  }

  // 保存储蓄目标
  Future<void> saveSavingGoal({
    required double amount,
    required String name,
    DateTime? deadline,
  }) async {
    await _settingsRepository.saveSavingGoal(
      amount: amount,
      name: name,
      deadline: deadline,
    );
  }

  // 获取储蓄目标金额
  Future<double> getSavingGoal() async {
    return await _settingsRepository.getSavingGoal();
  }

  // 获取储蓄目标名称
  Future<String> getGoalName() async {
    return await _settingsRepository.getGoalName();
  }

  // 获取储蓄目标截止日期
  Future<DateTime?> getGoalDeadline() async {
    return await _settingsRepository.getGoalDeadline();
  }

  // ===== 里程碑相关方法 =====

  // 保存里程碑
  Future<void> saveMilestone(String key, double value) async {
    await _milestoneRepository.saveMilestone(key, value);
  }

  // 检查里程碑是否已达成
  Future<bool> isMilestoneReached(String key) async {
    return await _milestoneRepository.isMilestoneReached(key);
  }

  // 获取所有里程碑
  Future<Map<String, double>> getAllMilestones() async {
    return await _milestoneRepository.getAllMilestones();
  }
}
