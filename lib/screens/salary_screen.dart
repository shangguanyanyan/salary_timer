import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifications_screen.dart';
import 'overtime_settings_screen.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../main.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 如果计时器正在运行，启动动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      if (timerService.isWorking) {
        _animationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.toggleTimer();

    if (timerService.isWorking) {
      // 启动动画
      _animationController.repeat(reverse: true);
    } else {
      // 停止动画
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final timerService = Provider.of<TimerService>(context);
    final unreadCount = notificationService.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('实时薪资'),
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Section title with animated indicator when working
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '当前实时薪资',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    if (timerService.isWorking)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                Colors.green.withOpacity(0.5),
                                Colors.green,
                                _animationController.value,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main earnings display
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Earnings label and time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timerService.isWorking ? '正在计时' : '计时已暂停',
                              style: TextStyle(
                                color:
                                    timerService.isWorking
                                        ? Colors.green
                                        : Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(timerService.elapsedTime),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Main amount display
                        timerService.isWorking
                            // 如果计时器正在运行，直接显示当前值，不做动画
                            ? RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '¥ ',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: timerService.currentSalary
                                        .toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            // 如果计时器停止，从0开始动画到当前值
                            : TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: timerService.currentSalary,
                              ),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '¥ ',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: value.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        const SizedBox(height: 32),

                        const Divider(),
                        const SizedBox(height: 16),

                        // 加班信息显示
                        Consumer<TimerService>(
                          builder: (context, timerService, child) {
                            if (timerService.enableOvertimeCalculation &&
                                timerService.overtimeTime.inSeconds > 0) {
                              return Column(
                                children: [
                                  // 加班信息卡片
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_filled,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '加班信息',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '正常工作',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDuration(
                                                    timerService.regularTime,
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '加班时间',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDuration(
                                                    timerService.overtimeTime,
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '加班倍率',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${timerService.overtimeRate.toStringAsFixed(1)}倍',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '正常收入',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '¥${timerService.regularEarnings.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '加班收入',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '¥${timerService.overtimeEarnings.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // 导航到加班设置页面
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const OvertimeSettingsScreen(),
                                                  ),
                                                );
                                              },
                                              child: const Text('设置'),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Rate information with financial styling
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _showHourlyRateExplanation(context);
                                },
                                child: Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '当前时薪率',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${timerService.hourlyRate.toStringAsFixed(2)}/小时',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // 切换到设置tab页面
                                  _navigateToConfigTab();
                                },
                                child: const Text('调整'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Daily stats card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日统计',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            context,
                            '目标进度',
                            '35%',
                            Icons.domain_verification,
                          ),
                          _buildStatItem(
                            context,
                            '预计结束',
                            '18:30',
                            Icons.schedule,
                          ),
                          _buildStatItem(context, '今日目标', '¥435', Icons.flag),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Start/Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          timerService.isWorking
                              ? const Color(0xFFB00020)
                              : Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          timerService.isWorking
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: Icon(
                      timerService.isWorking ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      timerService.isWorking ? '停止工作' : '开始工作',
                      style: const TextStyle(
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
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // 显示时薪率解释弹窗
  void _showHourlyRateExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('时薪率说明'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '时薪率是指您每小时工作可以赚取的薪资金额。',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('应用会根据这个时薪率和您已工作的时间来计算当前已赚取的薪资。'),
                SizedBox(height: 8),
                Text('计算公式为：当前薪资 = 已工作时间（秒）×（时薪率 ÷ 3600）'),
                SizedBox(height: 12),
                Text('您可以在配置页面通过三种方式设置您的薪资：'),
                SizedBox(height: 4),
                Text('• 直接输入时薪'),
                Text('• 输入日薪（应用会根据每日工作小时数计算时薪）'),
                Text('• 输入月薪（应用会根据每月工作天数和每日工作小时数计算时薪）'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('了解了'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToConfigTab();
              },
              child: const Text('去调整'),
            ),
          ],
        );
      },
    );
  }

  // 切换到设置tab页面
  void _navigateToConfigTab() {
    // 使用通知机制切换到设置页面（索引为2）
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // 创建一个自定义通知，让MainScreen监听并处理
      TabChangeNotification(3).dispatch(context);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('无法切换到设置页面，请手动切换')),
      );
    }
  }
}
