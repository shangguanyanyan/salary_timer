import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WorkLog {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final Duration regularTime;
  final Duration overtimeTime;
  final double regularEarnings;
  final double overtimeEarnings;
  final double totalEarnings;
  final double hourlyRate;
  final double overtimeRate;

  WorkLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.regularTime,
    required this.overtimeTime,
    required this.regularEarnings,
    required this.overtimeEarnings,
    required this.totalEarnings,
    required this.hourlyRate,
    required this.overtimeRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'regular_time_seconds': regularTime.inSeconds,
      'overtime_seconds': overtimeTime.inSeconds,
      'regular_earnings': regularEarnings,
      'overtime_earnings': overtimeEarnings,
      'total_earnings': totalEarnings,
      'hourly_rate': hourlyRate,
      'overtime_rate': overtimeRate,
    };
  }

  factory WorkLog.fromMap(Map<String, dynamic> map) {
    return WorkLog(
      id: map['id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      duration: Duration(seconds: map['duration_seconds'] as int),
      regularTime: Duration(seconds: map['regular_time_seconds'] as int),
      overtimeTime: Duration(seconds: map['overtime_seconds'] as int),
      regularEarnings: map['regular_earnings'] as double,
      overtimeEarnings: map['overtime_earnings'] as double,
      totalEarnings: map['total_earnings'] as double,
      hourlyRate: map['hourly_rate'] as double,
      overtimeRate: map['overtime_rate'] as double,
    );
  }
}

class WorkLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 插入工作日志
  Future<void> insert(WorkLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      'work_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取所有工作日志
  Future<List<WorkLog>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('work_logs', orderBy: 'end_time DESC');

    return List.generate(maps.length, (i) {
      return WorkLog.fromMap(maps[i]);
    });
  }

  // 获取特定日期范围内的工作日志
  Future<List<WorkLog>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final maps = await db.query(
      'work_logs',
      where: 'end_time >= ? AND start_time <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'end_time DESC',
    );

    return List.generate(maps.length, (i) {
      return WorkLog.fromMap(maps[i]);
    });
  }

  // 获取今日工作日志
  Future<List<WorkLog>> getTodayLogs() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return getByDateRange(today, tomorrow.subtract(const Duration(seconds: 1)));
  }

  // 获取本周工作日志
  Future<List<WorkLog>> getWeekLogs() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));

    return getByDateRange(weekStart, weekEnd);
  }

  // 获取本月工作日志
  Future<List<WorkLog>> getMonthLogs() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd =
        (now.month < 12)
            ? DateTime(
              now.year,
              now.month + 1,
              1,
            ).subtract(const Duration(seconds: 1))
            : DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));

    return getByDateRange(monthStart, monthEnd);
  }

  // 获取今日工作时长
  Future<Duration> getTodayWorkDuration() async {
    final logs = await getTodayLogs();
    return logs.fold<Duration>(Duration.zero, (sum, log) => sum + log.duration);
  }

  // 获取本周工作时长
  Future<Duration> getWeekWorkDuration() async {
    final logs = await getWeekLogs();
    return logs.fold<Duration>(Duration.zero, (sum, log) => sum + log.duration);
  }

  // 获取本月工作时长
  Future<Duration> getMonthWorkDuration() async {
    final logs = await getMonthLogs();
    return logs.fold<Duration>(Duration.zero, (sum, log) => sum + log.duration);
  }

  // 获取今日收入
  Future<double> getTodayEarnings() async {
    final logs = await getTodayLogs();
    return logs.fold<double>(0.0, (sum, log) => sum + log.totalEarnings);
  }

  // 获取本周收入
  Future<double> getWeekEarnings() async {
    final logs = await getWeekLogs();
    return logs.fold<double>(0.0, (sum, log) => sum + log.totalEarnings);
  }

  // 获取本月收入
  Future<double> getMonthEarnings() async {
    final logs = await getMonthLogs();
    return logs.fold<double>(0.0, (sum, log) => sum + log.totalEarnings);
  }

  // 删除工作日志
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('work_logs', where: 'id = ?', whereArgs: [id]);
  }

  // 清空所有工作日志
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('work_logs');
  }
}
