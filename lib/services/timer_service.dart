import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vault_service.dart';
import 'vault_service_locator.dart';
import 'notification_service.dart';
import '../screens/notifications_screen.dart';
import '../providers/data_provider.dart';

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

  // 加班设置
  bool _enableOvertimeCalculation = true; // 是否启用加班计算
  int _regularHoursLimit = 8; // 正常工作时间上限（小时）
  double _overtimeRate = 1.5; // 加班工资倍率，默认1.5倍
  double _regularEarnings = 0.0; // 正常工作时间的收入
  double _overtimeEarnings = 0.0; // 加班时间的收入
  Duration _regularTime = Duration.zero; // 正常工作时间
  Duration _overtimeTime = Duration.zero; // 加班时间

  // 工作时间提醒设置
  bool _enableWorkTimeReminders = true; // 是否启用工作时间提醒
  List<int> _reminderIntervals = [2, 4, 6, 8]; // 提醒间隔（小时）
  final Map<int, bool> _sentReminders = {}; // 已发送的提醒

  // 通知服务
  NotificationService? _notificationService;

  // 数据提供者
  DataProvider? _dataProvider;

  // 工作记录相关属性
  DateTime? _currentSessionStartTime; // 当前工作会话的开始时间
  Duration _todayTotalWorkDuration = Duration.zero; // 今日总工作时长
  double _todayTotalEarnings = 0.0; // 今日总收入

  // 获取今日总工作时长
  Duration get todayTotalWorkDuration => _todayTotalWorkDuration;

  // 获取今日总收入
  double get todayTotalEarnings => _todayTotalEarnings;

  // 设置通知服务
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  // 设置数据提供者
  void setDataProvider(DataProvider provider) {
    _dataProvider = provider;

    // 从数据提供者加载设置
    _hourlyRate = provider.hourlyRate;
    _enableOvertimeCalculation = provider.overtimeEnabled;
    _regularHoursLimit = provider.regularHoursLimit;
    _overtimeRate = provider.overtimeRate;
    _workDays = provider.workDays;
    _autoTimingEnabled = provider.autoTimingEnabled;
    _autoStartTime = provider.autoStartTime;
    _autoEndTime = provider.autoEndTime;

    // 加载今日总计数据
    _loadTodayTotals();

    notifyListeners();
  }

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

  // 加班相关的getter
  bool get enableOvertimeCalculation => _enableOvertimeCalculation;
  int get regularHoursLimit => _regularHoursLimit;
  double get overtimeRate => _overtimeRate;
  double get regularEarnings => _regularEarnings;
  double get overtimeEarnings => _overtimeEarnings;
  Duration get regularTime => _regularTime;
  Duration get overtimeTime => _overtimeTime;

  // 工作时间提醒相关的getter
  bool get enableWorkTimeReminders => _enableWorkTimeReminders;
  List<int> get reminderIntervals => _reminderIntervals;

  // 设置时薪
  set hourlyRate(double rate) {
    final previousRate = _hourlyRate;
    _hourlyRate = rate;
    _saveSettings();

    // 发送时薪更新通知
    if (_notificationService != null && previousRate != rate) {
      _notificationService!.addNotification(
        NotificationItem(
          title: '时薪更新',
          message:
              '你的时薪已从¥${previousRate.toStringAsFixed(2)}更新为¥${rate.toStringAsFixed(2)}。',
          time: DateTime.now(),
          type: NotificationType.update,
          isRead: false,
        ),
      );
    }

    notifyListeners();
  }

  // 设置自动计时开关
  set autoTimingEnabled(bool enabled) {
    _autoTimingEnabled = enabled;
    _saveSettings();

    if (enabled) {
      _checkAutoTiming();
      _startAutoTimingChecker();
    }

    notifyListeners();
  }

  // 设置自动开始时间
  set autoStartTime(TimeOfDay time) {
    _autoStartTime = time;
    _saveSettings();

    if (_autoTimingEnabled) {
      _checkAutoTiming();
    }

    notifyListeners();
  }

  // 设置自动结束时间
  set autoEndTime(TimeOfDay time) {
    _autoEndTime = time;
    _saveSettings();

    if (_autoTimingEnabled) {
      _checkAutoTiming();
    }

    notifyListeners();
  }

  // 设置工作日
  void setWorkDay(int day, bool value) {
    if (day >= 0 && day < 7) {
      _workDays[day] = value;
      if (_autoTimingEnabled) {
        _checkAutoTiming();
      }
      _saveSettings();
      notifyListeners();
    }
  }

  // 设置是否启用加班计算
  set enableOvertimeCalculation(bool enabled) {
    _enableOvertimeCalculation = enabled;
    _saveSettings();
    notifyListeners();
  }

  // 设置正常工作时间上限
  set regularHoursLimit(int hours) {
    if (hours > 0 && hours <= 24) {
      _regularHoursLimit = hours;
      _saveSettings();
      notifyListeners();
    }
  }

  // 设置加班工资倍率
  set overtimeRate(double rate) {
    if (rate > 0) {
      _overtimeRate = rate;
      _saveSettings();
      notifyListeners();
    }
  }

  // 设置工作时间提醒开关
  set enableWorkTimeReminders(bool enabled) {
    _enableWorkTimeReminders = enabled;
    _saveSettings();
    notifyListeners();
  }

  TimerService() {
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载时薪设置
    _hourlyRate = prefs.getDouble('hourly_rate') ?? 50.0;

    // 加载加班设置
    _enableOvertimeCalculation =
        prefs.getBool('enable_overtime_calculation') ?? false;
    _regularHoursLimit = prefs.getInt('regular_hours_limit') ?? 8;
    _overtimeRate = prefs.getDouble('overtime_rate') ?? 1.5;

    // 加载自动计时设置
    _autoTimingEnabled = prefs.getBool('auto_timing_enabled') ?? false;
    final autoStartHour = prefs.getInt('auto_start_hour') ?? 9;
    final autoStartMinute = prefs.getInt('auto_start_minute') ?? 0;
    final autoEndHour = prefs.getInt('auto_end_hour') ?? 18;
    final autoEndMinute = prefs.getInt('auto_end_minute') ?? 0;

    _autoStartTime = TimeOfDay(hour: autoStartHour, minute: autoStartMinute);
    _autoEndTime = TimeOfDay(hour: autoEndHour, minute: autoEndMinute);

    // 加载工作日设置
    for (int i = 0; i < 7; i++) {
      _workDays[i] = prefs.getBool('work_day_$i') ?? (i < 5); // 默认周一至周五为工作日
    }

    // 加载今日总计数据
    await _loadTodayTotals();

    // 如果之前在工作，恢复计时器状态
    final wasWorking = prefs.getBool('is_working') ?? false;
    final startTimeMillis = prefs.getInt('start_time');

    if (wasWorking && startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      _currentSessionStartTime = _startTime;
      _elapsedTime = DateTime.now().difference(_startTime);
      _isWorking = true;

      // 启动计时器
      _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
    }

    notifyListeners();
  }

  // 保存设置到 SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hourly_rate', _hourlyRate);
    await prefs.setBool(
      'enable_overtime_calculation',
      _enableOvertimeCalculation,
    );
    await prefs.setDouble('overtime_rate', _overtimeRate);
    await prefs.setInt('regular_hours_limit', _regularHoursLimit);
    await prefs.setBool('auto_timing_enabled', _autoTimingEnabled);
    await prefs.setInt('auto_start_hour', _autoStartTime.hour);
    await prefs.setInt('auto_start_minute', _autoStartTime.minute);
    await prefs.setInt('auto_end_hour', _autoEndTime.hour);
    await prefs.setInt('auto_end_minute', _autoEndTime.minute);

    // 保存工作日设置
    for (int i = 0; i < 7; i++) {
      await prefs.setBool('work_day_$i', _workDays[i]);
    }
  }

  // 设置自动计时器
  void _setupAutoTimers() {
    // 取消之前的计时器
    _cancelAutoTimers();

    if (!_autoTimingEnabled) return;

    // 检查当前是否在工作时间范围内，如果是，则自动开始计时
    if (isWithinWorkingHours() && !_isWorking) {
      toggleTimer();
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
        toggleTimer();
      }

      // 重新设置明天的计时器
      _setupDailyTimers();
    });

    // 设置自动结束计时器
    _autoEndTimer = Timer(endDelay, () {
      // 检查当天是否是工作日
      final endDay = DateTime.now().weekday % 7; // 0-6，0 表示周日
      if (_workDays[endDay]) {
        toggleTimer();
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
    if (_isWorking) {
      // 停止工作，保存记录
      _stopTimer();
      _saveWorkRecord();
    } else {
      // 开始工作，创建新记录
      _startTimer();
      _createWorkRecord();
    }
    notifyListeners();
  }

  // 开始计时器
  void _startTimer() {
    _isWorking = true;
    _startTime = DateTime.now();
    _currentSessionStartTime = _startTime; // 记录当前会话开始时间

    // 发送工作开始通知
    if (_notificationService != null) {
      _notificationService!.addNotification(
        NotificationItem(
          title: '工作开始',
          message: '你已开始工作，计时器已启动。',
          time: _startTime,
          type: NotificationType.reminder,
          isRead: false,
        ),
      );
    }

    // 重置已发送的提醒
    _sentReminders.clear();

    // 启动计时器，每秒更新一次
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);

    // 保存工作状态
    _saveWorkingState(true);
  }

  // 停止计时器
  void _stopTimer() {
    _isWorking = false;
    _timer?.cancel();
    _timer = null;

    // 发送工作结束通知
    if (_notificationService != null) {
      _notificationService!.addNotification(
        NotificationItem(
          title: '工作结束',
          message:
              '你已结束工作，本次工作时长: ${_formatDuration(_elapsedTime)}，收入: ¥${_currentSalary.toStringAsFixed(2)}',
          time: DateTime.now(),
          type: NotificationType.reminder,
          isRead: false,
        ),
      );
    }

    // 保存工作状态
    _saveWorkingState(false);
  }

  // 创建工作记录
  void _createWorkRecord() {
    // 记录开始时间，实际的记录会在工作结束时保存
  }

  // 保存工作记录到数据库
  Future<void> _saveWorkRecord() async {
    if (_currentSessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_currentSessionStartTime!);

    // 计算正常工作时间和加班时间
    Duration regularTime = duration;
    Duration overtimeTime = Duration.zero;
    double regularEarnings = _currentSalary;
    double overtimeEarnings = 0.0;

    // 如果启用了加班计算
    if (_enableOvertimeCalculation) {
      final regularHoursInSeconds = _regularHoursLimit * 3600;
      if (duration.inSeconds > regularHoursInSeconds) {
        regularTime = Duration(seconds: regularHoursInSeconds);
        overtimeTime = Duration(
          seconds: duration.inSeconds - regularHoursInSeconds,
        );

        // 计算正常工作收入和加班收入
        regularEarnings = regularTime.inSeconds / 3600 * _hourlyRate;
        overtimeEarnings =
            overtimeTime.inSeconds / 3600 * _hourlyRate * _overtimeRate;
      }
    }

    // 更新今日总工作时长和总收入
    _todayTotalWorkDuration += duration;
    _todayTotalEarnings += (regularEarnings + overtimeEarnings);

    // 保存今日总计数据
    await _saveTodayTotals();

    // 使用数据提供者保存工作记录
    if (_dataProvider != null) {
      await _dataProvider!.addWorkLog(
        startTime: _currentSessionStartTime!,
        endTime: endTime,
        duration: duration,
        regularTime: regularTime,
        overtimeTime: overtimeTime,
        regularEarnings: regularEarnings,
        overtimeEarnings: overtimeEarnings,
        totalEarnings: regularEarnings + overtimeEarnings,
      );

      // 添加收入记录
      await _dataProvider!.addEarning(
        regularEarnings + overtimeEarnings,
        duration,
      );
    }

    // 重置当前会话
    _currentSessionStartTime = null;
    _elapsedTime = Duration.zero;
    _currentSalary = 0.0;
    _regularEarnings = 0.0;
    _overtimeEarnings = 0.0;
    _regularTime = Duration.zero;
    _overtimeTime = Duration.zero;
  }

  // 保存今日总计数据
  Future<void> _saveTodayTotals() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查是否需要重置（新的一天）
    final lastSavedDate = prefs.getString('last_saved_date');
    final today = DateTime.now().toIso8601String().split('T')[0]; // 只取日期部分

    if (lastSavedDate != today) {
      // 新的一天，重置总计
      _todayTotalWorkDuration = Duration.zero;
      _todayTotalEarnings = 0.0;
    }

    // 保存今日日期、总工作时长和总收入
    await prefs.setString('last_saved_date', today);
    await prefs.setInt(
      'today_total_work_seconds',
      _todayTotalWorkDuration.inSeconds,
    );
    await prefs.setDouble('today_total_earnings', _todayTotalEarnings);
  }

  // 加载今日总计数据
  Future<void> _loadTodayTotals() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查是否是同一天
    final lastSavedDate = prefs.getString('last_saved_date');
    final today = DateTime.now().toIso8601String().split('T')[0]; // 只取日期部分

    if (lastSavedDate == today) {
      // 同一天，加载保存的数据
      final totalSeconds = prefs.getInt('today_total_work_seconds') ?? 0;
      _todayTotalWorkDuration = Duration(seconds: totalSeconds);
      _todayTotalEarnings = prefs.getDouble('today_total_earnings') ?? 0.0;
    } else {
      // 新的一天，重置总计
      _todayTotalWorkDuration = Duration.zero;
      _todayTotalEarnings = 0.0;

      // 保存新的日期
      await prefs.setString('last_saved_date', today);
      await prefs.setInt('today_total_work_seconds', 0);
      await prefs.setDouble('today_total_earnings', 0.0);
    }
  }

  // 格式化时长为字符串
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
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

  // 更新计时器
  void _updateTimer(Timer timer) {
    if (_isWorking) {
      final now = DateTime.now();
      _elapsedTime = now.difference(_startTime);

      // 计算薪资
      _calculateSalary();

      // 检查是否需要发送工作时间提醒
      _checkWorkTimeReminders();

      notifyListeners();
    }
  }

  // 检查是否需要发送工作时间提醒
  void _checkWorkTimeReminders() {
    if (!_enableWorkTimeReminders || _notificationService == null) return;

    final hours = _elapsedTime.inHours;

    // 检查每个提醒间隔
    for (final interval in _reminderIntervals) {
      if (hours == interval && !_sentReminders.containsKey(interval)) {
        _sentReminders[interval] = true;

        String message;
        if (interval >= 8) {
          message = '你已连续工作$interval小时，建议休息一下或结束今天的工作。';
        } else if (interval >= 6) {
          message = '你已连续工作$interval小时，建议适当休息片刻。';
        } else if (interval >= 4) {
          message = '你已连续工作$interval小时，记得适当活动一下身体。';
        } else {
          message = '你已连续工作$interval小时，继续保持！';
        }

        _notificationService!.addNotification(
          NotificationItem(
            title: '工作时间提醒',
            message: message,
            time: DateTime.now(),
            type: NotificationType.reminder,
            isRead: false,
          ),
        );
      }
    }
  }

  // 计算薪资
  void _calculateSalary() {
    // 计算正常工作时间和加班时间
    if (_enableOvertimeCalculation) {
      final regularLimitSeconds = _regularHoursLimit * 3600; // 转换为秒

      if (_elapsedTime.inSeconds <= regularLimitSeconds) {
        // 全部是正常工作时间
        _regularTime = _elapsedTime;
        _overtimeTime = Duration.zero;

        // 计算正常工作收入
        _regularEarnings = _regularTime.inSeconds * (_hourlyRate / 3600);
        _overtimeEarnings = 0.0;
      } else {
        // 部分是正常工作时间，部分是加班时间
        _regularTime = Duration(seconds: regularLimitSeconds);
        _overtimeTime = Duration(
          seconds: _elapsedTime.inSeconds - regularLimitSeconds,
        );

        // 计算正常工作收入和加班收入
        _regularEarnings = _regularTime.inSeconds * (_hourlyRate / 3600);
        _overtimeEarnings =
            _overtimeTime.inSeconds * (_hourlyRate / 3600 * _overtimeRate);
      }

      // 总收入是正常工作收入加上加班收入
      _currentSalary = _regularEarnings + _overtimeEarnings;
    } else {
      // 不计算加班，所有时间都按正常工资计算
      _regularTime = _elapsedTime;
      _overtimeTime = Duration.zero;
      _regularEarnings = _elapsedTime.inSeconds * (_hourlyRate / 3600);
      _overtimeEarnings = 0.0;
      _currentSalary = _regularEarnings;
    }
  }

  // 保存工作状态
  Future<void> _saveWorkingState(bool working) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_working', working);
    if (working) {
      await prefs.setInt('start_time', _startTime.millisecondsSinceEpoch);
    } else {
      await prefs.remove('start_time');
    }
  }

  // 加载工作状态
  Future<void> _loadWorkingState() async {
    final prefs = await SharedPreferences.getInstance();
    _isWorking = prefs.getBool('is_working') ?? false;

    if (_isWorking) {
      final startTimeMillis = prefs.getInt('start_time');
      if (startTimeMillis != null) {
        _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        _currentSessionStartTime = _startTime;
        _elapsedTime = DateTime.now().difference(_startTime);

        // 启动计时器
        _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
      } else {
        // 如果没有开始时间，重置工作状态
        _isWorking = false;
        await prefs.setBool('is_working', false);
      }
    }

    // 加载今日总计数据
    await _loadTodayTotals();
  }

  // 初始化
  Future<void> initialize() async {
    await _loadSettings();
    await _loadWorkingState();

    // 如果启用了自动计时，检查是否需要自动开始/结束工作
    if (_autoTimingEnabled) {
      _checkAutoTiming();
    }

    notifyListeners();
  }

  // 重置计时器
  void resetTimer() {
    _timer?.cancel();
    _isWorking = false;
    _currentSalary = 0.0;
    _regularEarnings = 0.0;
    _overtimeEarnings = 0.0;
    _elapsedTime = Duration.zero;
    _regularTime = Duration.zero;
    _overtimeTime = Duration.zero;
    _startTime = DateTime.now();
    _currentSessionStartTime = null;
    _sentReminders.clear(); // 清除已发送的提醒
    _saveSettings();
    _saveWorkingState(false);
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

  // 检查是否需要自动开始/结束工作
  void _checkAutoTiming() {
    if (!_autoTimingEnabled) return;

    final now = DateTime.now();
    final currentTimeOfDay = TimeOfDay.fromDateTime(now);
    final currentDayOfWeek = now.weekday - 1; // 0 = 周一, 6 = 周日

    // 检查今天是否是工作日
    if (currentDayOfWeek < 0 ||
        currentDayOfWeek >= _workDays.length ||
        !_workDays[currentDayOfWeek]) {
      return;
    }

    // 计算当前时间的分钟数
    final currentMinutes = currentTimeOfDay.hour * 60 + currentTimeOfDay.minute;
    final startMinutes = _autoStartTime.hour * 60 + _autoStartTime.minute;
    final endMinutes = _autoEndTime.hour * 60 + _autoEndTime.minute;

    // 检查是否应该自动开始工作
    if (!_isWorking &&
        currentMinutes >= startMinutes &&
        currentMinutes < endMinutes) {
      toggleTimer(); // 自动开始工作
    }

    // 检查是否应该自动结束工作
    if (_isWorking && currentMinutes >= endMinutes) {
      toggleTimer(); // 自动结束工作
    }
  }

  // 自动计时检查定时器
  void _startAutoTimingChecker() {
    // 每分钟检查一次自动计时
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_autoTimingEnabled) {
        timer.cancel();
        return;
      }
      _checkAutoTiming();
    });
  }

  // 检查是否在工作时间内
  bool _isWithinWorkHours() {
    if (!_autoTimingEnabled) return false;

    final now = DateTime.now();
    final currentTimeOfDay = TimeOfDay.fromDateTime(now);
    final currentDayOfWeek = now.weekday - 1; // 0 = 周一, 6 = 周日

    // 检查今天是否是工作日
    if (currentDayOfWeek < 0 ||
        currentDayOfWeek >= _workDays.length ||
        !_workDays[currentDayOfWeek]) {
      return false;
    }

    // 计算当前时间的分钟数
    final currentMinutes = currentTimeOfDay.hour * 60 + currentTimeOfDay.minute;
    final startMinutes = _autoStartTime.hour * 60 + _autoStartTime.minute;
    final endMinutes = _autoEndTime.hour * 60 + _autoEndTime.minute;

    // 检查是否在工作时间内
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  // 自动开始工作
  void _autoStartWork() {
    if (!_isWorking && _isWithinWorkHours()) {
      toggleTimer();
    }
  }

  // 自动结束工作
  void _autoEndWork() {
    if (_isWorking && !_isWithinWorkHours()) {
      toggleTimer();
    }
  }
}
