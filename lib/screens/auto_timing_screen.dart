import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';

class AutoTimingScreen extends StatefulWidget {
  const AutoTimingScreen({super.key});

  @override
  State<AutoTimingScreen> createState() => _AutoTimingScreenState();
}

class _AutoTimingScreenState extends State<AutoTimingScreen> {
  final List<String> _weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动计时设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                    '自动计时设置',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),

                // 自动计时开关
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
                              Icons.schedule,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '自动计时',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('启用自动计时'),
                          subtitle: const Text('按照设定的时间自动开始和结束计时'),
                          value: timerService.autoTimingEnabled,
                          onChanged: (value) {
                            timerService.autoTimingEnabled = value;
                          },
                          secondary: Icon(
                            Icons.access_time,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 工作时间设置
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
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '工作时间',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('开始时间'),
                          subtitle: Text(
                            timerService.formatTimeOfDay(
                              timerService.autoStartTime,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectTime(context, true),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('结束时间'),
                          subtitle: Text(
                            timerService.formatTimeOfDay(
                              timerService.autoEndTime,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectTime(context, false),
                        ),
                      ],
                    ),
                  ),
                ),

                // 工作日设置
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
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '工作日',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(7, (index) {
                          return CheckboxListTile(
                            title: Text(_weekDays[index]),
                            value: timerService.workDays[index],
                            onChanged: (value) {
                              if (value != null) {
                                timerService.setWorkDay(index, value);
                              }
                            },
                            secondary: Icon(
                              Icons.calendar_today,
                              color:
                                  timerService.workDays[index]
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.tertiary,
                            ),
                          );
                        }),
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
                          '自动计时将在设定的时间自动开始和结束计时，即使应用在后台运行或关闭。',
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
    );
  }

  // 选择时间
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final timerService = Provider.of<TimerService>(context, listen: false);
    final initialTime =
        isStartTime ? timerService.autoStartTime : timerService.autoEndTime;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.primary,
              dayPeriodTextColor: Theme.of(context).colorScheme.primary,
              dayPeriodColor: Theme.of(context).colorScheme.surfaceVariant,
              dialHandColor: Theme.of(context).colorScheme.secondary,
              dialBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              hourMinuteColor: Theme.of(context).colorScheme.surfaceVariant,
              dialTextColor: Theme.of(context).colorScheme.onSurface,
              entryModeIconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      if (isStartTime) {
        timerService.autoStartTime = pickedTime;
      } else {
        timerService.autoEndTime = pickedTime;
      }
    }
  }
}
