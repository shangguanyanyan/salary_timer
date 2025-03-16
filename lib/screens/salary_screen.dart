import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';
import 'notifications_screen.dart';
import 'overtime_settings_screen.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../providers/data_provider.dart';
import '../main.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _currency = '¥';
  double _lastSalary = 0.0;
  bool _showMilestoneAnimation = false;

  // 音频播放器
  final AudioPlayer _milestoneAudioPlayer = AudioPlayer();

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

      // 初始化上次金额，防止切换tab时触发动画
      _lastSalary = timerService.currentSalary;
    });

    _loadCurrencySetting();
    _initAudio();
  }

  // 初始化音频
  Future<void> _initAudio() async {
    try {
      // 初始化里程碑音效
      await _milestoneAudioPlayer.setAsset('assets/audio/milestone_sound.wav');
      await _milestoneAudioPlayer.setVolume(0.8);
    } catch (e) {
      debugPrint('音频初始化失败: $e');
    }
  }

  // 播放里程碑音效
  void _playMilestoneSound() async {
    try {
      await _milestoneAudioPlayer.seek(Duration.zero);
      await _milestoneAudioPlayer.play();
    } catch (e) {
      debugPrint('里程碑音效播放失败: $e');
    }
  }

  Future<void> _loadCurrencySetting() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    setState(() {
      _currency = dataProvider.currency;
    });
  }

  @override
  void dispose() {
    _milestoneAudioPlayer.dispose();
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

  // 检查是否达到里程碑（每10元）
  void _checkMilestone(double currentSalary) {
    // 如果金额为0，重置上次金额并返回
    if (currentSalary == 0) {
      _lastSalary = 0;
      return;
    }

    // 如果是首次加载页面，只记录金额，不触发动画
    if (_lastSalary == 0) {
      _lastSalary = currentSalary;
      return;
    }

    // 获取当前和上次金额的10元区间
    int currentMilestone = (currentSalary / 10).floor();
    int lastMilestone = (_lastSalary / 10).floor();

    // 如果跨越了一个新的10元区间，且当前金额大于上次金额（确保是在增长）
    if (currentMilestone > lastMilestone && currentSalary > _lastSalary) {
      setState(() {
        _showMilestoneAnimation = true;
      });

      // 播放里程碑音效
      _playMilestoneSound();

      // 1.5秒后隐藏动画
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showMilestoneAnimation = false;
          });
        }
      });
    }

    _lastSalary = currentSalary;
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final unreadCount = notificationService.unreadCount;

    // 检查里程碑
    _checkMilestone(timerService.currentSalary);

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
      body: Stack(
        children: [
          // 主要内容
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

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
                                  timerService.isWorking ? '已赚' : '准备好开始赚钱了吗？',
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
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(
                                          timerService.elapsedTime,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Main amount display
                            Stack(
                              children: [
                                SizedBox(
                                  height: 72,
                                  child: AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale:
                                            1.0 +
                                            (_animationController.value * 0.1),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _currency,
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
                                              TextSpan(
                                                text:
                                                    ' ${timerService.currentSalary.toStringAsFixed(2)}',
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
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // 里程碑动画层
                                if (_showMilestoneAnimation)
                                  Positioned.fill(
                                    child: Center(
                                      child: SizedBox(
                                        width: double.infinity, // 增大宽度
                                        // 增大高度
                                        child: Lottie.asset(
                                          'assets/animations/coin_milestone.json',
                                          repeat: false,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // 工作状态卡片
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                height: 180,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    // 背景动画层
                                    Positioned.fill(
                                      child:
                                          timerService.isWorking
                                              ? Center(
                                                child: SizedBox(
                                                  width: 300, // 固定宽度
                                                  height: 150, // 固定高度
                                                  child: Lottie.asset(
                                                    'assets/animations/money_background.json',
                                                    fit: BoxFit.contain,
                                                    repeat: true,
                                                  ),
                                                ),
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                    // 内容层
                                    Column(
                                      children: [
                                        // 状态标题
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              timerService.isWorking
                                                  ? Icons.work
                                                  : Icons.coffee,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              timerService.isWorking
                                                  ? '正在工作'
                                                  : '休息中',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // 主要动画
                                        Expanded(
                                          child:
                                              timerService.isWorking
                                                  ? Lottie.asset(
                                                    'assets/animations/working.json',
                                                    fit: BoxFit.contain,
                                                    repeat: true,
                                                  )
                                                  : Lottie.asset(
                                                    'assets/animations/resting.json',
                                                    fit: BoxFit.contain,
                                                    repeat: true,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Statistics section
                    _buildStatisticsSection(context, dataProvider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleTimer,
        backgroundColor:
            timerService.isWorking
                ? Colors.orange
                : Theme.of(context).colorScheme.secondary,
        child: Icon(
          timerService.isWorking ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    DataProvider dataProvider,
  ) {
    final timerService = Provider.of<TimerService>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('今日统计', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                '累计时长',
                _formatDuration(timerService.todayTotalWorkDuration),
                Icons.access_time,
                null,
              ),
              _buildStatItem(
                context,
                '累计收入',
                '$_currency${timerService.todayTotalEarnings.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                null,
              ),
              _buildStatItem(
                context,
                '时薪',
                '$_currency${timerService.hourlyRate.toStringAsFixed(2)}',
                Icons.trending_up,
                () => _showHourlyRateExplanation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == '时薪') ...[
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
              ],
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
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
