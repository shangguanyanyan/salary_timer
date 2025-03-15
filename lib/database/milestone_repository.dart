import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class MilestoneRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 保存里程碑
  Future<void> saveMilestone(String key, double value) async {
    final db = await _dbHelper.database;
    await db.insert('milestones', {
      'key': key,
      'value': value,
      'reached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 检查里程碑是否已达成
  Future<bool> isMilestoneReached(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'milestones',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty;
  }

  // 获取里程碑值
  Future<double?> getMilestoneValue(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'milestones',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) {
      return null;
    }
    return result.first['value'] as double;
  }

  // 获取里程碑达成时间
  Future<DateTime?> getMilestoneReachedAt(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'milestones',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) {
      return null;
    }
    return DateTime.parse(result.first['reached_at'] as String);
  }

  // 获取所有里程碑
  Future<Map<String, double>> getAllMilestones() async {
    final db = await _dbHelper.database;
    final result = await db.query('milestones');

    final Map<String, double> milestones = {};
    for (final row in result) {
      milestones[row['key'] as String] = row['value'] as double;
    }
    return milestones;
  }

  // 删除里程碑
  Future<void> deleteMilestone(String key) async {
    final db = await _dbHelper.database;
    await db.delete('milestones', where: 'key = ?', whereArgs: [key]);
  }

  // 清空所有里程碑
  Future<void> deleteAllMilestones() async {
    final db = await _dbHelper.database;
    await db.delete('milestones');
  }
}
