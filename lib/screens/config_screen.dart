import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  double _hourlyRate = 54.30;
  int _workHoursPerDay = 8;
  int _workDaysPerWeek = 5;
  bool _includeWeekends = false;
  bool _enableNotifications = true;
  bool _trackAchievements = true;
  String _currency = '¥';

  // Currency options
  final List<String> _currencyOptions = ['¥', '\$', '€', '£'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('薪资配置'),
        centerTitle: true,
        elevation: 0,
        actions: [
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Text(
                    '薪资设置',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Currency Selection
                  Row(
                    children: [
                      const Expanded(flex: 2, child: Text('货币单位')),
                      Expanded(
                        flex: 3,
                        child: SegmentedButton<String>(
                          segments:
                              _currencyOptions
                                  .map(
                                    (currency) => ButtonSegment<String>(
                                      value: currency,
                                      label: Text(currency),
                                    ),
                                  )
                                  .toList(),
                          selected: {_currency},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _currency = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hourly Rate Input
                  Row(
                    children: [
                      const Expanded(flex: 2, child: Text('小时薪资')),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: _hourlyRate.toString(),
                          decoration: InputDecoration(
                            prefixText: _currency,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
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
                                    double.tryParse(value) ?? _hourlyRate;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Work Hours Per Day
                  Row(
                    children: [
                      const Expanded(flex: 2, child: Text('每日工作小时')),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: _workHoursPerDay.toString(),
                          decoration: const InputDecoration(
                            suffixText: '小时',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
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
                            if (hours == null || hours <= 0 || hours > 24) {
                              return '请输入1-24之间的小时数';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _workHoursPerDay =
                                    int.tryParse(value) ?? _workHoursPerDay;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Work Days Per Week
                  Row(
                    children: [
                      const Expanded(flex: 2, child: Text('每周工作天数')),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: _workDaysPerWeek.toString(),
                          decoration: const InputDecoration(
                            suffixText: '天',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
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
                                    int.tryParse(value) ?? _workDaysPerWeek;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section Header
                  Text(
                    '其他设置',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Include Weekends Switch
                  SwitchListTile(
                    title: const Text('计算周末时间'),
                    subtitle: const Text('在薪资计算中包含周末'),
                    value: _includeWeekends,
                    onChanged: (value) {
                      setState(() {
                        _includeWeekends = value;
                      });
                    },
                    secondary: const Icon(Icons.calendar_today),
                  ),

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
                    secondary: const Icon(Icons.notifications),
                  ),

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
                    secondary: const Icon(Icons.emoji_events),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '保存设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement saving to shared preferences or database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
