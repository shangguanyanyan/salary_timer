import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 保存设置
  Future<void> saveSetting(String key, dynamic value) async {
    final db = await _dbHelper.database;
    String stringValue;
    String valueType;

    if (value is bool) {
      stringValue = value.toString();
      valueType = 'bool';
    } else if (value is int) {
      stringValue = value.toString();
      valueType = 'int';
    } else if (value is double) {
      stringValue = value.toString();
      valueType = 'double';
    } else if (value is String) {
      stringValue = value;
      valueType = 'string';
    } else if (value is List) {
      stringValue = jsonEncode(value);
      valueType = 'list';
    } else if (value is Map) {
      stringValue = jsonEncode(value);
      valueType = 'map';
    } else if (value is TimeOfDay) {
      stringValue = jsonEncode({'hour': value.hour, 'minute': value.minute});
      valueType = 'timeofday';
    } else if (value is DateTime) {
      stringValue = value.toIso8601String();
      valueType = 'datetime';
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }

    await db.insert('settings', {
      'key': key,
      'value': stringValue,
      'value_type': valueType,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 获取设置
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);

    if (maps.isEmpty) {
      return defaultValue;
    }

    final stringValue = maps.first['value'] as String;
    final valueType = maps.first['value_type'] as String;
    return _parseValue<T>(stringValue, valueType);
  }

  // 解析设置值
  T? _parseValue<T>(String stringValue, String valueType) {
    switch (valueType) {
      case 'string':
        return stringValue as T;
      case 'int':
        return int.parse(stringValue) as T;
      case 'double':
        return double.parse(stringValue) as T;
      case 'bool':
        return (stringValue.toLowerCase() == 'true') as T;
      case 'list':
        return jsonDecode(stringValue) as T;
      case 'map':
        return jsonDecode(stringValue) as T;
      case 'timeofday':
        final map = jsonDecode(stringValue) as Map<String, dynamic>;
        return TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int)
            as T;
      case 'datetime':
        return DateTime.parse(stringValue) as T;
      default:
        return null;
    }
  }

  // 删除设置
  Future<void> deleteSetting(String key) async {
    final db = await _dbHelper.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // 保存工作日设置
  Future<void> saveWorkDays(List<bool> workDays) async {
    await saveSetting('work_days', workDays);
  }

  // 获取工作日设置
  Future<List<bool>> getWorkDays() async {
    final result = await getSetting<List>('work_days');
    if (result == null) {
      // 默认周一到周五工作
      return [false, true, true, true, true, true, false];
    }
    return result.cast<bool>();
  }

  // 保存时薪
  Future<void> saveHourlyRate(double rate) async {
    await saveSetting('hourly_rate', rate);
  }

  // 获取时薪
  Future<double> getHourlyRate() async {
    return await getSetting<double>('hourly_rate') ?? 54.30; // 默认时薪
  }

  // 保存自动计时设置
  Future<void> saveAutoTimingEnabled(bool enabled) async {
    await saveSetting('auto_timing_enabled', enabled);
  }

  // 获取自动计时设置
  Future<bool> getAutoTimingEnabled() async {
    return await getSetting<bool>('auto_timing_enabled') ?? false;
  }

  // 保存自动开始时间
  Future<void> saveAutoStartTime(TimeOfDay time) async {
    await saveSetting('auto_start_time', time);
  }

  // 获取自动开始时间
  Future<TimeOfDay> getAutoStartTime() async {
    return await getSetting<TimeOfDay>('auto_start_time') ??
        const TimeOfDay(hour: 9, minute: 0); // 默认早上9点
  }

  // 保存自动结束时间
  Future<void> saveAutoEndTime(TimeOfDay time) async {
    await saveSetting('auto_end_time', time);
  }

  // 获取自动结束时间
  Future<TimeOfDay> getAutoEndTime() async {
    return await getSetting<TimeOfDay>('auto_end_time') ??
        const TimeOfDay(hour: 19, minute: 0); // 默认晚上7点
  }

  // 保存加班设置
  Future<void> saveOvertimeSettings({
    required bool enabled,
    required int regularHoursLimit,
    required double overtimeRate,
  }) async {
    await saveSetting('enable_overtime_calculation', enabled);
    await saveSetting('regular_hours_limit', regularHoursLimit);
    await saveSetting('overtime_rate', overtimeRate);
  }

  // 获取加班启用状态
  Future<bool> getOvertimeEnabled() async {
    return await getSetting<bool>('enable_overtime_calculation') ?? true;
  }

  // 获取正常工作时间上限
  Future<int> getRegularHoursLimit() async {
    return await getSetting<int>('regular_hours_limit') ?? 8;
  }

  // 获取加班工资倍率
  Future<double> getOvertimeRate() async {
    return await getSetting<double>('overtime_rate') ?? 1.5;
  }

  // 保存储蓄目标
  Future<void> saveSavingGoal({
    required double amount,
    required String name,
    DateTime? deadline,
  }) async {
    await saveSetting('saving_goal', amount);
    await saveSetting('goal_name', name);
    if (deadline != null) {
      await saveSetting('goal_deadline', deadline);
    } else {
      await deleteSetting('goal_deadline');
    }
  }

  // 获取储蓄目标金额
  Future<double> getSavingGoal() async {
    return await getSetting<double>('saving_goal') ?? 0.0;
  }

  // 获取储蓄目标名称
  Future<String> getGoalName() async {
    return await getSetting<String>('goal_name') ?? '';
  }

  // 获取储蓄目标截止日期
  Future<DateTime?> getGoalDeadline() async {
    return await getSetting<DateTime>('goal_deadline');
  }
}
