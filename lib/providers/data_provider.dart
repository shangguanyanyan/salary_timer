import 'package:flutter/material.dart';
import '../database/data_service.dart';
import '../models/earning_record.dart';
import '../screens/notifications_screen.dart';
import '../database/work_log_repository.dart';

class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService.instance;
  bool _isInitialized = false;

  // 缓存数据
  double _todayEarnings = 0.0;
  double _weekEarnings = 0.0;
  double _monthEarnings = 0.0;
  double _totalEarnings = 0.0;
  Duration _todayWorkDuration = Duration.zero;
  Duration _weekWorkDuration = Duration.zero;
  Duration _monthWorkDuration = Duration.zero;
  int _unreadNotificationCount = 0;
  double _hourlyRate = 0.0;
  bool _overtimeEnabled = false;
  int _regularHoursLimit = 8;
  double _overtimeRate = 1.5;
  double _savingGoal = 0.0;
  String _goalName = '';
  DateTime? _goalDeadline;
  List<bool> _workDays = List.filled(7, false);
  bool _autoTimingEnabled = false;
  TimeOfDay _autoStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _autoEndTime = const TimeOfDay(hour: 17, minute: 0);
  Map<String, double> _milestones = {};

  // 获取器
  double get todayEarnings => _todayEarnings;
  double get weekEarnings => _weekEarnings;
  double get monthEarnings => _monthEarnings;
  double get totalEarnings => _totalEarnings;
  Duration get todayWorkDuration => _todayWorkDuration;
  Duration get weekWorkDuration => _weekWorkDuration;
  Duration get monthWorkDuration => _monthWorkDuration;
  int get unreadNotificationCount => _unreadNotificationCount;
  double get hourlyRate => _hourlyRate;
  bool get overtimeEnabled => _overtimeEnabled;
  int get regularHoursLimit => _regularHoursLimit;
  double get overtimeRate => _overtimeRate;
  double get savingGoal => _savingGoal;
  String get goalName => _goalName;
  DateTime? get goalDeadline => _goalDeadline;
  List<bool> get workDays => _workDays;
  bool get autoTimingEnabled => _autoTimingEnabled;
  TimeOfDay get autoStartTime => _autoStartTime;
  TimeOfDay get autoEndTime => _autoEndTime;
  Map<String, double> get milestones => _milestones;

  // 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _dataService.initialize();
    await _loadAllData();

    _isInitialized = true;
    notifyListeners();
  }

  // 加载所有数据
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadEarnings(),
      _loadWorkDurations(),
      _loadNotifications(),
      _loadSettings(),
      _loadMilestones(),
    ]);
  }

  // 加载收入数据
  Future<void> _loadEarnings() async {
    _todayEarnings = await _dataService.getTodayEarnings();
    _weekEarnings = await _dataService.getWeekEarnings();
    _monthEarnings = await _dataService.getMonthEarnings();
    _totalEarnings = await _dataService.getTotalEarnings();
  }

  // 加载工作时长数据
  Future<void> _loadWorkDurations() async {
    _todayWorkDuration = await _dataService.getTodayWorkDuration();
    _weekWorkDuration = await _dataService.getWeekWorkDuration();
    _monthWorkDuration = await _dataService.getMonthWorkDuration();
  }

  // 加载通知数据
  Future<void> _loadNotifications() async {
    _unreadNotificationCount = await _dataService.getUnreadNotificationCount();
  }

  // 加载设置数据
  Future<void> _loadSettings() async {
    _hourlyRate = await _dataService.getHourlyRate();
    _overtimeEnabled = await _dataService.getOvertimeEnabled();
    _regularHoursLimit = await _dataService.getRegularHoursLimit();
    _overtimeRate = await _dataService.getOvertimeRate();
    _savingGoal = await _dataService.getSavingGoal();
    _goalName = await _dataService.getGoalName();
    _goalDeadline = await _dataService.getGoalDeadline();
    _workDays = await _dataService.getWorkDays();
    _autoTimingEnabled = await _dataService.getAutoTimingEnabled();
    _autoStartTime = await _dataService.getAutoStartTime();
    _autoEndTime = await _dataService.getAutoEndTime();
  }

  // 加载里程碑数据
  Future<void> _loadMilestones() async {
    _milestones = await _dataService.getAllMilestones();
  }

  // 刷新所有数据
  Future<void> refreshData() async {
    await _loadAllData();
    notifyListeners();
  }

  // ===== 收入记录相关方法 =====

  // 添加收入记录
  Future<void> addEarning(double amount, Duration workDuration) async {
    await _dataService.addEarning(amount, workDuration, _hourlyRate);
    await _loadEarnings();
    notifyListeners();
  }

  // 获取所有收入记录
  Future<List<EarningRecord>> getAllEarnings() async {
    return await _dataService.getAllEarnings();
  }

  // 获取按日期分组的收入记录
  Future<Map<String, List<EarningRecord>>> getGroupedEarnings() async {
    return await _dataService.getGroupedEarnings();
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
  }) async {
    await _dataService.addWorkLog(
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      regularTime: regularTime,
      overtimeTime: overtimeTime,
      regularEarnings: regularEarnings,
      overtimeEarnings: overtimeEarnings,
      totalEarnings: totalEarnings,
      hourlyRate: _hourlyRate,
      overtimeRate: _overtimeRate,
    );
    await _loadEarnings();
    await _loadWorkDurations();
    notifyListeners();
  }

  // 获取所有工作日志
  Future<List<WorkLog>> getAllWorkLogs() async {
    return await _dataService.getAllWorkLogs();
  }

  // ===== 通知相关方法 =====

  // 添加通知
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    await _dataService.addNotification(
      title: title,
      message: message,
      type: type,
    );
    await _loadNotifications();
    notifyListeners();
  }

  // 获取所有通知
  Future<List<NotificationItem>> getAllNotifications() async {
    return await _dataService.getAllNotifications();
  }

  // 获取未读通知
  Future<List<NotificationItem>> getUnreadNotifications() async {
    return await _dataService.getUnreadNotifications();
  }

  // 标记通知为已读
  Future<void> markNotificationAsRead(String id) async {
    await _dataService.markNotificationAsRead(id);
    await _loadNotifications();
    notifyListeners();
  }

  // 标记所有通知为已读
  Future<void> markAllNotificationsAsRead() async {
    await _dataService.markAllNotificationsAsRead();
    await _loadNotifications();
    notifyListeners();
  }

  // ===== 设置相关方法 =====

  // 保存时薪
  Future<void> saveHourlyRate(double rate) async {
    await _dataService.saveHourlyRate(rate);
    _hourlyRate = rate;
    notifyListeners();
  }

  // 保存自动计时设置
  Future<void> saveAutoTimingSettings({
    required bool enabled,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<bool> workDays,
  }) async {
    await _dataService.saveAutoTimingSettings(
      enabled: enabled,
      startTime: startTime,
      endTime: endTime,
      workDays: workDays,
    );
    _autoTimingEnabled = enabled;
    _autoStartTime = startTime;
    _autoEndTime = endTime;
    _workDays = workDays;
    notifyListeners();
  }

  // 保存加班设置
  Future<void> saveOvertimeSettings({
    required bool enabled,
    required int regularHoursLimit,
    required double overtimeRate,
  }) async {
    await _dataService.saveOvertimeSettings(
      enabled: enabled,
      regularHoursLimit: regularHoursLimit,
      overtimeRate: overtimeRate,
    );
    _overtimeEnabled = enabled;
    _regularHoursLimit = regularHoursLimit;
    _overtimeRate = overtimeRate;
    notifyListeners();
  }

  // 保存储蓄目标
  Future<void> saveSavingGoal({
    required double amount,
    required String name,
    DateTime? deadline,
  }) async {
    await _dataService.saveSavingGoal(
      amount: amount,
      name: name,
      deadline: deadline,
    );
    _savingGoal = amount;
    _goalName = name;
    _goalDeadline = deadline;
    notifyListeners();
  }

  // ===== 里程碑相关方法 =====

  // 保存里程碑
  Future<void> saveMilestone(String key, double value) async {
    await _dataService.saveMilestone(key, value);
    await _loadMilestones();
    notifyListeners();
  }

  // 检查里程碑是否已达成
  Future<bool> isMilestoneReached(String key) async {
    return await _dataService.isMilestoneReached(key);
  }
}
