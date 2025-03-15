import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';

class OvertimeSettingsScreen extends StatefulWidget {
  const OvertimeSettingsScreen({super.key});

  @override
  State<OvertimeSettingsScreen> createState() => _OvertimeSettingsScreenState();
}

class _OvertimeSettingsScreenState extends State<OvertimeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // 控制器
  final TextEditingController _regularHoursController = TextEditingController();
  final TextEditingController _overtimeRateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    final timerService = Provider.of<TimerService>(context, listen: false);
    _regularHoursController.text = timerService.regularHoursLimit.toString();
    _overtimeRateController.text = timerService.overtimeRate.toString();
  }

  @override
  void dispose() {
    _regularHoursController.dispose();
    _overtimeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('加班设置'),
        centerTitle: true,
        elevation: 0,
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
                  // 标题
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
                      '加班设置',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),

                  // 加班计算开关
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '加班计算',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('启用加班计算'),
                            subtitle: const Text('超过正常工作时间的部分将按加班工资计算'),
                            value: timerService.enableOvertimeCalculation,
                            onChanged: (value) {
                              timerService.enableOvertimeCalculation = value;
                            },
                            secondary: Icon(
                              Icons.calculate,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 加班参数设置
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '加班参数',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 正常工作时间上限
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '正常工作时间上限',
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
                                  controller: _regularHoursController,
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
                                      return '请输入正常工作时间上限';
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
                                      final hours = int.tryParse(value);
                                      if (hours != null &&
                                          hours > 0 &&
                                          hours <= 24) {
                                        timerService.regularHoursLimit = hours;
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 加班工资倍率
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '加班工资倍率',
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
                                  controller: _overtimeRateController,
                                  decoration: const InputDecoration(
                                    suffixText: '倍',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
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
                                      return '请输入加班工资倍率';
                                    }
                                    final rate = double.tryParse(value);
                                    if (rate == null || rate <= 0) {
                                      return '请输入大于0的倍率';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      final rate = double.tryParse(value);
                                      if (rate != null && rate > 0) {
                                        timerService.overtimeRate = rate;
                                      }
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

                  // 加班说明
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '加班说明',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '加班计算功能会自动将超过正常工作时间上限的部分按照加班工资倍率计算。'
                            '例如，如果正常工作时间上限为8小时，加班工资倍率为1.5倍，'
                            '那么工作10小时后，前8小时按正常工资计算，后2小时按1.5倍工资计算。',
                          ),
                          const SizedBox(height: 12),
                          const Text('加班收入和正常收入都会被记录到金库中，并计入当日总收入。'),
                        ],
                      ),
                    ),
                  ),

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
                            '所有设置会实时自动保存并应用于收入计算。如果您正在计时，更改设置将立即影响当前的收入计算。',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
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
}
