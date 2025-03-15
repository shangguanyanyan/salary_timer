import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/earning_record.dart';
import 'notification_service.dart';
import '../screens/notifications_screen.dart';
import '../providers/data_provider.dart';

class VaultService extends ChangeNotifier {
  List<EarningRecord> _earningRecords = [];
  double _totalEarnings = 0.0;
  double _todayEarnings = 0.0;
  double _weekEarnings = 0.0;
  double _monthEarnings = 0.0;

  // 储蓄目标
  double _savingGoal = 0.0;
  String _goalName = '';
  DateTime? _goalDeadline;

  // 薪资里程碑
  final List<double> _milestones = [100, 500, 1000, 5000, 10000, 50000, 100000];
  final Map<String, double> _reachedMilestones = {};

  // 通知服务
  NotificationService? _notificationService;

  // 数据提供者
  DataProvider? _dataProvider;

  // 设置通知服务
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  // 设置数据提供者
  void setDataProvider(DataProvider provider) {
    _dataProvider = provider;
    // 从数据提供者加载数据
    _savingGoal = provider.savingGoal;
    _goalName = provider.goalName;
    _goalDeadline = provider.goalDeadline;
    notifyListeners();
  }

  // Getters
  List<EarningRecord> get earningRecords => _earningRecords;
  double get totalEarnings => _totalEarnings;
  double get todayEarnings => _todayEarnings;
  double get weekEarnings => _weekEarnings;
  double get monthEarnings => _monthEarnings;
  double get savingGoal => _savingGoal;
  String get goalName => _goalName;
  DateTime? get goalDeadline => _goalDeadline;

  // 计算目标进度百分比
  double get goalProgress =>
      _savingGoal > 0 ? (_totalEarnings / _savingGoal * 100).clamp(0, 100) : 0;

  // 初始化
  VaultService() {
    _loadData();
  }

  // 从本地存储加载数据
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 加载收入记录
      final recordsJson = prefs.getString('earning_records');
      if (recordsJson != null) {
        _earningRecords = EarningRecord.decode(recordsJson);
      }

      // 加载目标
      _savingGoal = prefs.getDouble('saving_goal') ?? 0.0;
      _goalName = prefs.getString('goal_name') ?? '';
      final deadlineStr = prefs.getString('goal_deadline');
      _goalDeadline = deadlineStr != null ? DateTime.parse(deadlineStr) : null;

      // 加载已达成的里程碑
      await _loadReachedMilestones();

      _calculateStatistics();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vault data: $e');
      }
      // 如果加载失败，使用默认值
      _earningRecords = [];
      _savingGoal = 0.0;
      _goalName = '';
      _goalDeadline = null;
      _calculateStatistics();
    }

    notifyListeners();
  }

  // 保存数据到本地存储
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 保存收入记录
      final recordsJson = EarningRecord.encode(_earningRecords);
      await prefs.setString('earning_records', recordsJson);

      // 保存目标
      await prefs.setDouble('saving_goal', _savingGoal);
      await prefs.setString('goal_name', _goalName);
      if (_goalDeadline != null) {
        await prefs.setString(
          'goal_deadline',
          _goalDeadline!.toIso8601String(),
        );
      } else {
        await prefs.remove('goal_deadline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving vault data: $e');
      }
    }
  }

  // 计算统计数据
  void _calculateStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    _totalEarnings = _earningRecords.fold(
      0,
      (sum, record) => sum + record.amount,
    );

    _todayEarnings = _earningRecords
        .where(
          (record) =>
              record.date.isAfter(today.subtract(const Duration(seconds: 1))) ||
              record.date.isAtSameMomentAs(today),
        )
        .fold(0, (sum, record) => sum + record.amount);

    _weekEarnings = _earningRecords
        .where(
          (record) =>
              record.date.isAfter(
                weekStart.subtract(const Duration(seconds: 1)),
              ) ||
              record.date.isAtSameMomentAs(weekStart),
        )
        .fold(0, (sum, record) => sum + record.amount);

    _monthEarnings = _earningRecords
        .where(
          (record) =>
              record.date.isAfter(
                monthStart.subtract(const Duration(seconds: 1)),
              ) ||
              record.date.isAtSameMomentAs(monthStart),
        )
        .fold(0, (sum, record) => sum + record.amount);
  }

  // 添加收入记录
  Future<void> addEarning(
    double amount,
    Duration workDuration,
    double hourlyRate,
  ) async {
    if (amount <= 0) return; // 不添加零或负收入

    final record = EarningRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      workDuration: workDuration,
      hourlyRate: hourlyRate,
    );

    _earningRecords.add(record);

    // 计算统计数据前的值
    final previousTotalEarnings = _totalEarnings;
    final previousTodayEarnings = _todayEarnings;

    _calculateStatistics();

    // 检查并发送通知
    _checkMilestones(previousTotalEarnings, previousTodayEarnings);
    _checkGoalProgress();

    await _saveData();
    notifyListeners();
  }

  // 设置储蓄目标
  Future<void> setSavingGoal(
    double amount,
    String name, [
    DateTime? deadline,
  ]) async {
    final previousGoal = _savingGoal;
    final previousName = _goalName;

    _savingGoal = amount;
    _goalName = name;
    _goalDeadline = deadline;

    // 如果是新设置或修改了目标，发送通知
    if (_notificationService != null &&
        (previousGoal != amount || previousName != name)) {
      _notificationService!.addNotification(
        NotificationItem(
          title: '储蓄目标已设置',
          message: '你设置了新的储蓄目标：$name (¥${amount.toStringAsFixed(2)})',
          time: DateTime.now(),
          type: NotificationType.update,
          isRead: false,
        ),
      );
    }

    // 检查目标进度
    _checkGoalProgress();

    await _saveData();
    notifyListeners();
  }

  // 检查薪资里程碑
  void _checkMilestones(double previousTotal, double previousToday) {
    if (_notificationService == null) return;

    // 检查总收入里程碑
    for (final milestone in _milestones) {
      final key = 'total_$milestone';
      if (previousTotal < milestone &&
          _totalEarnings >= milestone &&
          !_reachedMilestones.containsKey(key)) {
        _reachedMilestones[key] = _totalEarnings;
        _notificationService!.addNotification(
          NotificationItem(
            title: '薪资里程碑',
            message: '恭喜！你的总收入已突破¥${milestone.toStringAsFixed(0)}。',
            time: DateTime.now(),
            type: NotificationType.milestone,
            isRead: false,
          ),
        );
      }
    }

    // 检查今日收入里程碑
    final dailyMilestones = [100, 200, 500, 1000];
    for (final milestone in dailyMilestones) {
      final key = 'today_${DateTime.now().toString().split(' ')[0]}_$milestone';
      if (previousToday < milestone &&
          _todayEarnings >= milestone &&
          !_reachedMilestones.containsKey(key)) {
        _reachedMilestones[key] = _todayEarnings;
        _notificationService!.addNotification(
          NotificationItem(
            title: '今日薪资里程碑',
            message: '恭喜！你的今日收入已突破¥${milestone.toStringAsFixed(0)}。',
            time: DateTime.now(),
            type: NotificationType.milestone,
            isRead: false,
          ),
        );
      }
    }

    // 保存已达成的里程碑
    _saveReachedMilestones();
  }

  // 检查目标进度
  void _checkGoalProgress() {
    if (_notificationService == null || _savingGoal <= 0) return;

    // 检查是否达到目标的特定百分比
    final progressPercentages = [25, 50, 75, 90, 100];
    for (final percentage in progressPercentages) {
      final key = 'goal_${_goalName}_$percentage';
      final requiredAmount = _savingGoal * (percentage / 100);

      if (_totalEarnings >= requiredAmount &&
          !_reachedMilestones.containsKey(key)) {
        _reachedMilestones[key] = _totalEarnings;

        String message;
        if (percentage == 100) {
          message =
              '恭喜！你已完成"$_goalName"储蓄目标 (¥${_savingGoal.toStringAsFixed(2)})。';
        } else {
          message = '你已完成"$_goalName"储蓄目标的$percentage%，继续加油！';
        }

        _notificationService!.addNotification(
          NotificationItem(
            title: '储蓄目标进度',
            message: message,
            time: DateTime.now(),
            type: NotificationType.achievement,
            isRead: false,
          ),
        );
      }
    }

    // 保存已达成的里程碑
    _saveReachedMilestones();
  }

  // 保存已达成的里程碑
  Future<void> _saveReachedMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(
        'reached_milestones',
        jsonEncode(_reachedMilestones),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving reached milestones: $e');
      }
    }
  }

  // 加载已达成的里程碑
  Future<void> _loadReachedMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final milestonesJson = prefs.getString('reached_milestones');
      if (milestonesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(milestonesJson);
        _reachedMilestones.clear();
        decoded.forEach((key, value) {
          _reachedMilestones[key] = value.toDouble();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reached milestones: $e');
      }
    }
  }

  // 获取按日期分组的收入记录
  Map<String, List<EarningRecord>> getGroupedRecords() {
    final groupedRecords = <String, List<EarningRecord>>{};

    // 按日期降序排序
    final sortedRecords = List<EarningRecord>.from(_earningRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final record in sortedRecords) {
      final dateStr = _formatDateKey(record.date);
      if (!groupedRecords.containsKey(dateStr)) {
        groupedRecords[dateStr] = [];
      }
      groupedRecords[dateStr]!.add(record);
    }

    return groupedRecords;
  }

  // 格式化日期为键
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 清除所有记录（仅用于测试）
  Future<void> clearAllRecords() async {
    _earningRecords.clear();
    _calculateStatistics();
    await _saveData();
    notifyListeners();
  }
}
