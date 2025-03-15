import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('salary_timer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建收入记录表
    await db.execute('''
    CREATE TABLE earning_records (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      amount REAL NOT NULL,
      work_duration_seconds INTEGER NOT NULL,
      hourly_rate REAL NOT NULL
    )
    ''');

    // 创建工作日志表
    await db.execute('''
    CREATE TABLE work_logs (
      id TEXT PRIMARY KEY,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      duration_seconds INTEGER NOT NULL,
      regular_time_seconds INTEGER NOT NULL,
      overtime_seconds INTEGER NOT NULL,
      regular_earnings REAL NOT NULL,
      overtime_earnings REAL NOT NULL,
      total_earnings REAL NOT NULL,
      hourly_rate REAL NOT NULL,
      overtime_rate REAL NOT NULL
    )
    ''');

    // 创建通知表
    await db.execute('''
    CREATE TABLE notifications (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      time TEXT NOT NULL,
      type TEXT NOT NULL,
      is_read INTEGER NOT NULL
    )
    ''');

    // 创建设置表
    await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      value_type TEXT NOT NULL
    )
    ''');

    // 创建里程碑表
    await db.execute('''
    CREATE TABLE milestones (
      key TEXT PRIMARY KEY,
      value REAL NOT NULL,
      reached_at TEXT NOT NULL
    )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
