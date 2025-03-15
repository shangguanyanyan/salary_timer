import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  double _hourlyRate = 54.30;
  double _monthlySalary = 8688.0; // 新增月薪变量，默认值为时薪*每日工作小时*每月工作日
  double _dailySalary = 434.40; // 新增日薪变量，默认值为时薪*每日工作小时
  int _workHoursPerDay = 8;
  int _workDaysPerWeek = 5;
  bool _includeWeekends = false;
  bool _enableNotifications = true;
  bool _trackAchievements = true;
  String _currency = '¥';

  // 薪资计算方式: 'monthly'=月薪, 'daily'=日薪, 'hourly'=时薪
  String _calculationMode = 'monthly';

  // Text controllers for input fields
  final TextEditingController _monthlyController = TextEditingController();
  final TextEditingController _dailyController = TextEditingController();
  final TextEditingController _hourlyController = TextEditingController();
  final TextEditingController _workHoursController = TextEditingController();
  final TextEditingController _workDaysController = TextEditingController();

  // Currency options
  final List<String> _currencyOptions = ['¥', '\$', '€', '£'];

  @override
  void initState() {
    super.initState();
    // 初始化日薪和月薪 - 基于默认时薪和工作时间
    _calculateDailySalaryFromHourly();
    _calculateMonthlySalaryFromDaily();

    // Initialize controllers with current values
    _monthlyController.text = _monthlySalary.toString();
    _dailyController.text = _dailySalary.toString();
    _hourlyController.text = _hourlyRate.toString();
    _workHoursController.text = _workHoursPerDay.toString();
    _workDaysController.text = _workDaysPerWeek.toString();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _monthlyController.dispose();
    _dailyController.dispose();
    _hourlyController.dispose();
    _workHoursController.dispose();
    _workDaysController.dispose();
    super.dispose();
  }

  // 根据时薪计算日薪
  void _calculateDailySalaryFromHourly() {
    _dailySalary = _hourlyRate * _workHoursPerDay;
    _dailySalary = double.parse(_dailySalary.toStringAsFixed(2)); // 保留两位小数
  }

  // 根据日薪计算时薪
  void _calculateHourlyRateFromDaily() {
    if (_workHoursPerDay > 0) {
      _hourlyRate = _dailySalary / _workHoursPerDay;
      _hourlyRate = double.parse(_hourlyRate.toStringAsFixed(2)); // 保留两位小数
    }
  }

  // 根据日薪计算月薪
  void _calculateMonthlySalaryFromDaily() {
    // 假设一个月平均有 4.345 周 (365 / 12 / 7)
    double averageWeeksPerMonth = 4.345;
    _monthlySalary = _dailySalary * _workDaysPerWeek * averageWeeksPerMonth;
    _monthlySalary = double.parse(_monthlySalary.toStringAsFixed(2)); // 保留两位小数
  }

  // 根据月薪计算日薪
  void _calculateDailySalaryFromMonthly() {
    // 假设一个月平均有 4.345 周
    double averageWeeksPerMonth = 4.345;
    double monthlyWorkDays = _workDaysPerWeek * averageWeeksPerMonth;

    if (monthlyWorkDays > 0) {
      _dailySalary = _monthlySalary / monthlyWorkDays;
      _dailySalary = double.parse(_dailySalary.toStringAsFixed(2)); // 保留两位小数
    }
  }

  // 更新所有薪资数据
  void _updateAllSalaryData() {
    switch (_calculationMode) {
      case 'monthly':
        _calculateDailySalaryFromMonthly();
        _calculateHourlyRateFromDaily();
        break;
      case 'daily':
        _calculateHourlyRateFromDaily();
        _calculateMonthlySalaryFromDaily();
        break;
      case 'hourly':
        _calculateDailySalaryFromHourly();
        _calculateMonthlySalaryFromDaily();
        break;
    }

    // Update controller text values
    _monthlyController.text = _monthlySalary.toString();
    _dailyController.text = _dailySalary.toString();
    _hourlyController.text = _hourlyRate.toString();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final unreadCount = notificationService.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('薪资配置'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                tooltip: '通知',
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB00020),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: '保存设置',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 薪资设置标题
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      '薪资设置',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),

                  // 标题卡片
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '基本薪资信息',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 薪资信息卡片
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Currency Selection
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '货币单位',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: SegmentedButton<String>(
                                  segments:
                                      _currencyOptions
                                          .map(
                                            (currency) => ButtonSegment<String>(
                                              value: currency,
                                              icon: Text(
                                                currency,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  selected: {_currency},
                                  onSelectionChanged: (Set<String> selection) {
                                    setState(() {
                                      _currency = selection.first;
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >((states) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Theme.of(
                                              context,
                                            ).colorScheme.secondary;
                                          }
                                          return Theme.of(
                                            context,
                                          ).colorScheme.surface;
                                        }),
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >((states) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Theme.of(
                                              context,
                                            ).colorScheme.onSecondary;
                                          }
                                          return Theme.of(
                                            context,
                                          ).colorScheme.onSurface;
                                        }),
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                          const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                        ),
                                    iconSize: MaterialStateProperty.all<double>(
                                      14,
                                    ),
                                    minimumSize:
                                        MaterialStateProperty.all<Size>(
                                          const Size(10, 32),
                                        ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  emptySelectionAllowed: false,
                                  showSelectedIcon: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 薪资计算方式选择
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '输入方式',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: SegmentedButton<String>(
                                  segments: [
                                    ButtonSegment<String>(
                                      value: 'monthly',
                                      icon: const Text(
                                        '月薪',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    ButtonSegment<String>(
                                      value: 'daily',
                                      icon: const Text(
                                        '日薪',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    ButtonSegment<String>(
                                      value: 'hourly',
                                      icon: const Text(
                                        '时薪',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                  selected: {_calculationMode},
                                  onSelectionChanged: (Set<String> selection) {
                                    setState(() {
                                      _calculationMode = selection.first;
                                      _updateAllSalaryData();
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >((states) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Theme.of(
                                              context,
                                            ).colorScheme.secondary;
                                          }
                                          return Theme.of(
                                            context,
                                          ).colorScheme.surface;
                                        }),
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >((states) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Theme.of(
                                              context,
                                            ).colorScheme.onSecondary;
                                          }
                                          return Theme.of(
                                            context,
                                          ).colorScheme.onSurface;
                                        }),
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                          const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                    iconSize: MaterialStateProperty.all<double>(
                                      14,
                                    ),
                                    minimumSize:
                                        MaterialStateProperty.all<Size>(
                                          const Size(10, 32),
                                        ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  emptySelectionAllowed: false,
                                  showSelectedIcon: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 月薪输入
                          if (_calculationMode == 'monthly')
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '月薪',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _monthlyController,
                                    decoration: InputDecoration(
                                      prefixText: _currency,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入月薪';
                                      }
                                      final salary = double.tryParse(value);
                                      if (salary == null || salary <= 0) {
                                        return '请输入有效的月薪金额';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        setState(() {
                                          _monthlySalary =
                                              double.tryParse(value) ??
                                              _monthlySalary;
                                          _calculateDailySalaryFromMonthly();
                                          _calculateHourlyRateFromDaily();

                                          // Update other controllers
                                          _dailyController.text =
                                              _dailySalary.toString();
                                          _hourlyController.text =
                                              _hourlyRate.toString();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                          // 日薪输入
                          if (_calculationMode == 'daily')
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '日薪',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _dailyController,
                                    decoration: InputDecoration(
                                      prefixText: _currency,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入日薪';
                                      }
                                      final salary = double.tryParse(value);
                                      if (salary == null || salary <= 0) {
                                        return '请输入有效的日薪金额';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        setState(() {
                                          _dailySalary =
                                              double.tryParse(value) ??
                                              _dailySalary;
                                          _calculateHourlyRateFromDaily();
                                          _calculateMonthlySalaryFromDaily();

                                          // Update other controllers
                                          _monthlyController.text =
                                              _monthlySalary.toString();
                                          _hourlyController.text =
                                              _hourlyRate.toString();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                          // 各种薪资显示区域
                          // 时薪显示/输入
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '小时薪资',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child:
                                    _calculationMode != 'hourly'
                                        ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.surfaceVariant,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant
                                                .withOpacity(0.3),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '$_currency ${_hourlyRate.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '(自动计算)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        : TextFormField(
                                          controller: _hourlyController,
                                          decoration: InputDecoration(
                                            prefixText: _currency,
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return '请输入时薪';
                                            }
                                            final rate = double.tryParse(value);
                                            if (rate == null || rate <= 0) {
                                              return '请输入有效的时薪金额';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            if (value.isNotEmpty) {
                                              setState(() {
                                                _hourlyRate =
                                                    double.tryParse(value) ??
                                                    _hourlyRate;
                                                _calculateDailySalaryFromHourly();
                                                _calculateMonthlySalaryFromDaily();

                                                // Update other controllers
                                                _dailyController.text =
                                                    _dailySalary.toString();
                                                _monthlyController.text =
                                                    _monthlySalary.toString();
                                              });
                                            }
                                          },
                                        ),
                              ),
                            ],
                          ),

                          // 如果是时薪模式，显示日薪估算
                          if (_calculationMode == 'hourly')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildReadOnlySalaryField(
                                  context,
                                  '日薪估算',
                                  _dailySalary,
                                ),
                              ],
                            ),

                          // 如果是日薪模式，显示月薪估算
                          if (_calculationMode == 'daily')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildReadOnlySalaryField(
                                  context,
                                  '月薪估算',
                                  _monthlySalary,
                                ),
                              ],
                            ),

                          // 如果是月薪模式，显示日薪估算
                          if (_calculationMode == 'monthly')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildReadOnlySalaryField(
                                  context,
                                  '日薪估算',
                                  _dailySalary,
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // Work Hours Per Day
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '每日工作小时',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _workHoursController,
                                  decoration: const InputDecoration(
                                    suffixText: '小时',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入每日工作小时';
                                    }
                                    final hours = int.tryParse(value);
                                    if (hours == null ||
                                        hours <= 0 ||
                                        hours > 24) {
                                      return '请输入1-24之间的小时数';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        _workHoursPerDay =
                                            int.tryParse(value) ??
                                            _workHoursPerDay;
                                        _updateAllSalaryData();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Work Days Per Week
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '每周工作天数',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _workDaysController,
                                  decoration: const InputDecoration(
                                    suffixText: '天',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入每周工作天数';
                                    }
                                    final days = int.tryParse(value);
                                    if (days == null || days <= 0 || days > 7) {
                                      return '请输入1-7之间的天数';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        _workDaysPerWeek =
                                            int.tryParse(value) ??
                                            _workDaysPerWeek;
                                        _updateAllSalaryData();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 其他设置标题
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      '其他设置',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),

                  // 其他设置标题卡片
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '偏好设置',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 其他设置卡片
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Enable Notifications Switch
                        SwitchListTile(
                          title: const Text('启用通知'),
                          subtitle: const Text('接收重要的薪资变化提醒'),
                          value: _enableNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableNotifications = value;
                            });
                          },
                          secondary: Icon(
                            Icons.notifications,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const Divider(height: 1, indent: 70),

                        // Track Achievements Switch
                        SwitchListTile(
                          title: const Text('成就系统'),
                          subtitle: const Text('追踪并解锁薪资成就'),
                          value: _trackAchievements,
                          onChanged: (value) {
                            setState(() {
                              _trackAchievements = value;
                            });
                          },
                          secondary: Icon(
                            Icons.emoji_events,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 提示信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '设置会自动保存并应用于收入计算和统计。',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        '保存设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 创建只读薪资字段
  Widget _buildReadOnlySalaryField(
    BuildContext context,
    String label,
    double value,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_currency ${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '(自动计算)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement saving to shared preferences or database
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('设置已保存'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }
}
