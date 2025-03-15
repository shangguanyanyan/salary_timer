import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/earning_record.dart';

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
    _calculateStatistics();
    await _saveData();
    notifyListeners();
  }

  // 设置储蓄目标
  Future<void> setSavingGoal(
    double amount,
    String name, [
    DateTime? deadline,
  ]) async {
    _savingGoal = amount;
    _goalName = name;
    _goalDeadline = deadline;
    await _saveData();
    notifyListeners();
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
