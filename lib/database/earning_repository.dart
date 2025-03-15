import 'package:sqflite/sqflite.dart';
import '../models/earning_record.dart';
import 'database_helper.dart';

class EarningRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 插入收入记录
  Future<void> insert(EarningRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('earning_records', {
      'id': record.id,
      'date': record.date.toIso8601String(),
      'amount': record.amount,
      'work_duration_seconds': record.workDuration.inSeconds,
      'hourly_rate': record.hourlyRate,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 获取所有收入记录
  Future<List<EarningRecord>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('earning_records', orderBy: 'date DESC');

    return List.generate(maps.length, (i) {
      return EarningRecord(
        id: maps[i]['id'] as String,
        date: DateTime.parse(maps[i]['date'] as String),
        amount: maps[i]['amount'] as double,
        workDuration: Duration(
          seconds: maps[i]['work_duration_seconds'] as int,
        ),
        hourlyRate: maps[i]['hourly_rate'] as double,
      );
    });
  }

  // 获取特定日期范围内的收入记录
  Future<List<EarningRecord>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final maps = await db.query(
      'earning_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return EarningRecord(
        id: maps[i]['id'] as String,
        date: DateTime.parse(maps[i]['date'] as String),
        amount: maps[i]['amount'] as double,
        workDuration: Duration(
          seconds: maps[i]['work_duration_seconds'] as int,
        ),
        hourlyRate: maps[i]['hourly_rate'] as double,
      );
    });
  }

  // 获取今日收入
  Future<double> getTodayEarnings() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final records = await getByDateRange(
      today,
      tomorrow.subtract(const Duration(seconds: 1)),
    );
    return records.fold<double>(0.0, (sum, record) => sum + record.amount);
  }

  // 获取本周收入
  Future<double> getWeekEarnings() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));

    final records = await getByDateRange(weekStart, weekEnd);
    return records.fold<double>(0.0, (sum, record) => sum + record.amount);
  }

  // 获取本月收入
  Future<double> getMonthEarnings() async {
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

    final records = await getByDateRange(monthStart, monthEnd);
    return records.fold<double>(0.0, (sum, record) => sum + record.amount);
  }

  // 获取总收入
  Future<double> getTotalEarnings() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM earning_records',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // 删除收入记录
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('earning_records', where: 'id = ?', whereArgs: [id]);
  }

  // 清空所有收入记录
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('earning_records');
  }
}
