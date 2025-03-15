import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService extends ChangeNotifier {
  double _currentSalary = 0.0;
  double _hourlyRate = 54.30; // 默认时薪
  Timer? _timer;
  Timer? _autoStartTimer; // 自动开始计时器
  Timer? _autoEndTimer; // 自动结束计时器
  bool _isWorking = false;
  DateTime _startTime = DateTime.now();
  Duration _elapsedTime = Duration.zero;

  // 自动计时设置
  bool _autoTimingEnabled = false; // 是否启用自动计时
  TimeOfDay _autoStartTime = const TimeOfDay(hour: 9, minute: 0); // 默认早上9点开始
  TimeOfDay _autoEndTime = const TimeOfDay(hour: 19, minute: 0); // 默认晚上7点结束
  List<bool> _workDays = [
    false,
    true,
    true,
    true,
    true,
    true,
    false,
  ]; // 默认周一到周五工作

  // 获取当前薪资
  double get currentSalary => _currentSalary;

  // 获取是否正在工作
  bool get isWorking => _isWorking;

  // 获取已经工作的时间
  Duration get elapsedTime => _elapsedTime;

  // 获取时薪
  double get hourlyRate => _hourlyRate;

  // 自动计时相关的getter
  bool get autoTimingEnabled => _autoTimingEnabled;
  TimeOfDay get autoStartTime => _autoStartTime;
  TimeOfDay get autoEndTime => _autoEndTime;
  List<bool> get workDays => _workDays;

  // 设置时薪
  set hourlyRate(double rate) {
    _hourlyRate = rate;
    _saveSettings();
    notifyListeners();
  }

  // 设置自动计时开关
  set autoTimingEnabled(bool enabled) {
    _autoTimingEnabled = enabled;
    if (enabled) {
      _setupAutoTimers();
    } else {
      _cancelAutoTimers();
    }
    _saveSettings();
    notifyListeners();
  }

  // 设置自动开始时间
  set autoStartTime(TimeOfDay time) {
    _autoStartTime = time;
    if (_autoTimingEnabled) {
      _setupAutoTimers();
    }
    _saveSettings();
    notifyListeners();
  }

  // 设置自动结束时间
  set autoEndTime(TimeOfDay time) {
    _autoEndTime = time;
    if (_autoTimingEnabled) {
      _setupAutoTimers();
    }
    _saveSettings();
    notifyListeners();
  }

  // 设置工作日
  void setWorkDay(int day, bool value) {
    if (day >= 0 && day < 7) {
      _workDays[day] = value;
      if (_autoTimingEnabled) {
        _setupAutoTimers();
      }
      _saveSettings();
      notifyListeners();
    }
  }

  TimerService() {
    _loadSettings();
  }

  // 从 SharedPreferences 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hourlyRate = prefs.getDouble('hourly_rate') ?? _hourlyRate;

    // 加载自动计时设置
    _autoTimingEnabled = prefs.getBool('auto_timing_enabled') ?? false;
    final autoStartHour = prefs.getInt('auto_start_hour') ?? 9;
    final autoStartMinute = prefs.getInt('auto_start_minute') ?? 0;
    _autoStartTime = TimeOfDay(hour: autoStartHour, minute: autoStartMinute);

    final autoEndHour = prefs.getInt('auto_end_hour') ?? 19;
    final autoEndMinute = prefs.getInt('auto_end_minute') ?? 0;
    _autoEndTime = TimeOfDay(hour: autoEndHour, minute: autoEndMinute);

    // 加载工作日设置
    for (int i = 0; i < 7; i++) {
      _workDays[i] =
          prefs.getBool('work_day_$i') ?? (i > 0 && i < 6); // 默认周一到周五
    }

    // 如果之前在工作，恢复计时器状态
    final wasWorking = prefs.getBool('is_working') ?? false;
    final startTimeMillis = prefs.getInt('start_time');

    if (wasWorking && startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      _toggleTimer();
    }

    // 设置自动计时器
    if (_autoTimingEnabled) {
      _setupAutoTimers();
    }

    notifyListeners();
  }

  // 保存设置到 SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hourly_rate', _hourlyRate);
    prefs.setBool('is_working', _isWorking);

    // 保存自动计时设置
    prefs.setBool('auto_timing_enabled', _autoTimingEnabled);
    prefs.setInt('auto_start_hour', _autoStartTime.hour);
    prefs.setInt('auto_start_minute', _autoStartTime.minute);
    prefs.setInt('auto_end_hour', _autoEndTime.hour);
    prefs.setInt('auto_end_minute', _autoEndTime.minute);

    // 保存工作日设置
    for (int i = 0; i < 7; i++) {
      prefs.setBool('work_day_$i', _workDays[i]);
    }

    if (_isWorking) {
      prefs.setInt('start_time', _startTime.millisecondsSinceEpoch);
    } else {
      prefs.remove('start_time');
    }
  }

  // 设置自动计时器
  void _setupAutoTimers() {
    // 取消之前的计时器
    _cancelAutoTimers();

    if (!_autoTimingEnabled) return;

    // 检查当前是否在工作时间范围内，如果是，则自动开始计时
    if (isWithinWorkingHours() && !_isWorking) {
      _toggleTimer();
    }

    // 设置每日自动开始和结束计时器
    _setupDailyTimers();
  }

  // 设置每日自动计时器
  void _setupDailyTimers() {
    // 获取当前时间
    final now = DateTime.now();

    // 计算今天的开始和结束时间点
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      _autoStartTime.hour,
      _autoStartTime.minute,
    );

    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      _autoEndTime.hour,
      _autoEndTime.minute,
    );

    // 计算到下一个开始时间的延迟
    Duration startDelay;
    if (now.isBefore(todayStart)) {
      // 今天的开始时间还没到
      startDelay = todayStart.difference(now);
    } else {
      // 今天的开始时间已经过了，计算到明天开始时间的延迟
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      startDelay = tomorrowStart.difference(now);
    }

    // 计算到下一个结束时间的延迟
    Duration endDelay;
    if (now.isBefore(todayEnd)) {
      // 今天的结束时间还没到
      endDelay = todayEnd.difference(now);
    } else {
      // 今天的结束时间已经过了，计算到明天结束时间的延迟
      final tomorrowEnd = todayEnd.add(const Duration(days: 1));
      endDelay = tomorrowEnd.difference(now);
    }

    // 设置自动开始计时器
    _autoStartTimer = Timer(startDelay, () {
      // 检查当天是否是工作日
      final startDay = DateTime.now().weekday % 7; // 0-6，0 表示周日
      if (_workDays[startDay]) {
        _toggleTimer();
      }

      // 重新设置明天的计时器
      _setupDailyTimers();
    });

    // 设置自动结束计时器
    _autoEndTimer = Timer(endDelay, () {
      // 检查当天是否是工作日
      final endDay = DateTime.now().weekday % 7; // 0-6，0 表示周日
      if (_workDays[endDay]) {
        _toggleTimer();
      }

      // 不需要在这里重新设置计时器，因为开始计时器会处理
    });
  }

  // 取消自动计时器
  void _cancelAutoTimers() {
    _autoStartTimer?.cancel();
    _autoEndTimer?.cancel();
    _autoStartTimer = null;
    _autoEndTimer = null;
  }

  // 切换计时器状态
  void toggleTimer() {
    _toggleTimer();
    _saveSettings();
  }

  void _toggleTimer() {
    _isWorking = !_isWorking;

    if (_isWorking) {
      // 如果是新开始的工作，重置开始时间
      if (_elapsedTime.inSeconds == 0) {
        _startTime = DateTime.now();
      } else {
        // 如果是恢复工作，调整开始时间以保持已经工作的时间
        _startTime = DateTime.now().subtract(_elapsedTime);
      }

      // 启动计时器，每秒更新一次
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        _elapsedTime = now.difference(_startTime);
        // 根据已经工作的时间（小时）* 时薪计算收入
        _currentSalary = _elapsedTime.inSeconds * (_hourlyRate / 3600);
        notifyListeners();
      });
    } else {
      // 停止计时器
      _timer?.cancel();
    }

    notifyListeners();
  }

  // 重置计时器
  void resetTimer() {
    _timer?.cancel();
    _isWorking = false;
    _currentSalary = 0.0;
    _elapsedTime = Duration.zero;
    _startTime = DateTime.now();
    _saveSettings();
    notifyListeners();
  }

  // 格式化时间显示
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // 格式化时间显示（12小时制）
  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? '下午' : '上午';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // 检查当前时间是否在自动计时范围内
  bool isWithinWorkingHours() {
    if (!_autoTimingEnabled) return false;

    // 检查当前是否是工作日
    final now = DateTime.now();
    final currentDay = now.weekday % 7; // 0-6，0 表示周日
    if (!_workDays[currentDay]) return false;

    // 获取当前时间
    final currentTime = TimeOfDay.fromDateTime(now);

    // 转换为分钟进行比较
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = _autoStartTime.hour * 60 + _autoStartTime.minute;
    final endMinutes = _autoEndTime.hour * 60 + _autoEndTime.minute;

    // 检查当前时间是否在工作时间范围内
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoStartTimer?.cancel();
    _autoEndTimer?.cancel();
    super.dispose();
  }
}
