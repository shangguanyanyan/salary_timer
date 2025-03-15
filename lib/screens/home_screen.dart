import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../services/vault_service.dart';

// 视图类型枚举
enum ViewType { day, week, month }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // 当前选中的视图类型
  ViewType _currentViewType = ViewType.day;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 切换视图类型
  void _changeViewType(ViewType viewType) {
    if (_currentViewType == viewType) return;

    // 开始动画
    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentViewType = viewType;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final timerService = Provider.of<TimerService>(context);
    final vaultService = Provider.of<VaultService>(context);
    final unreadCount = notificationService.unreadCount;

    // 根据当前视图类型获取相应的数据
    final viewData = _getViewData(_currentViewType, vaultService);

    return Scaffold(
      appBar: AppBar(
        title: const Text('薪时计算器'),
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
      body: GestureDetector(
        // 添加滑动手势支持
        onHorizontalDragEnd: (details) {
          // 检测滑动方向和速度
          if (details.primaryVelocity == null) return;

          // 向左滑动 - 切换到下一个视图
          if (details.primaryVelocity! < -300) {
            _switchToNextView();
          }
          // 向右滑动 - 切换到上一个视图
          else if (details.primaryVelocity! > 300) {
            _switchToPreviousView();
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎区域 - 带有金色边框装饰
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '欢迎使用薪时计算器',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '实时追踪你的薪资增长',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 主卡片 - 当前收入展示
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getViewTitle(_currentViewType),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              // 视图切换下拉菜单
                              _buildViewTypeDropdown(context),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 使用动画效果显示金额
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              '¥ ${viewData.earnings.toStringAsFixed(2)}',
                              key: ValueKey<String>(
                                '${_currentViewType}_${viewData.earnings}',
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 删除视图指示器及相关空白区域
                          const Divider(),
                          const SizedBox(height: 12),
                          // 进度条和标签
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '工作进度',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  // 使用动画效果显示进度百分比
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    child: Text(
                                      '${(viewData.progress * 100).toInt()}%',
                                      key: ValueKey<int>(
                                        (viewData.progress * 100).toInt(),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 使用动画效果显示进度条
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: viewData.progress,
                                ),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.secondary,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 标题行 - 使用动画效果
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      key: ValueKey<ViewType>(_currentViewType),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDataTitle(_currentViewType),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _getFormattedDateRange(_currentViewType),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 数据卡片网格 - 使用动画效果
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: GridView.count(
                      key: ValueKey<String>('grid_${_currentViewType}'),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildDataCard(
                          context,
                          Icons.access_time,
                          '工作时长',
                          _formatDuration(viewData.workDuration),
                        ),
                        _buildDataCard(
                          context,
                          Icons.trending_up,
                          '时薪',
                          '¥${timerService.hourlyRate.toStringAsFixed(2)}/小时',
                        ),
                        _buildDataCard(
                          context,
                          Icons.emoji_events,
                          '解锁成就',
                          '${viewData.achievements}个',
                        ),
                        _buildDataCard(
                          context,
                          Icons.bar_chart,
                          _getTotalLabel(_currentViewType),
                          '¥${viewData.totalEarnings.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 金融统计部分 - 使用动画效果
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      key: ValueKey<String>('trend_${_currentViewType}'),
                      padding: const EdgeInsets.all(16),
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
                            '薪资趋势',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTrendItem(
                                context,
                                _getAverageLabel(_currentViewType),
                                '¥${viewData.averageEarnings.toStringAsFixed(2)}',
                                viewData.isUpTrend,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                              ),
                              _buildTrendItem(
                                context,
                                _getEstimateLabel(_currentViewType),
                                '¥${viewData.estimatedEarnings.toStringAsFixed(2)}',
                                true,
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
        ),
      ),
    );
  }

  // 构建视图类型下拉菜单
  Widget _buildViewTypeDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
      ),
      child: PopupMenuButton<ViewType>(
        initialValue: _currentViewType,
        onSelected: _changeViewType,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: ViewType.day, child: Text('日视图')),
              const PopupMenuItem(value: ViewType.week, child: Text('周视图')),
              const PopupMenuItem(value: ViewType.month, child: Text('月视图')),
            ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getViewTypeText(_currentViewType),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取视图类型文本
  String _getViewTypeText(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '日视图';
      case ViewType.week:
        return '周视图';
      case ViewType.month:
        return '月视图';
    }
  }

  // 获取视图标题
  String _getViewTitle(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '今日已赚取';
      case ViewType.week:
        return '本周已赚取';
      case ViewType.month:
        return '本月已赚取';
    }
  }

  // 获取数据标题
  String _getDataTitle(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '今日数据';
      case ViewType.week:
        return '本周数据';
      case ViewType.month:
        return '本月数据';
    }
  }

  // 获取总计标签
  String _getTotalLabel(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '本周总计';
      case ViewType.week:
        return '本月总计';
      case ViewType.month:
        return '年度总计';
    }
  }

  // 获取平均标签
  String _getAverageLabel(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '日均薪资';
      case ViewType.week:
        return '周均薪资';
      case ViewType.month:
        return '月均薪资';
    }
  }

  // 获取预估标签
  String _getEstimateLabel(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return '月预估';
      case ViewType.week:
        return '月预估';
      case ViewType.month:
        return '年预估';
    }
  }

  // 获取格式化的日期范围
  String _getFormattedDateRange(ViewType viewType) {
    final now = DateTime.now();

    switch (viewType) {
      case ViewType.day:
        return formatDate(now);
      case ViewType.week:
        // 计算本周的开始和结束日期
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${formatShortDate(weekStart)} - ${formatShortDate(weekEnd)}';
      case ViewType.month:
        // 计算本月的天数
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month, daysInMonth);
        return '${formatShortDate(monthStart)} - ${formatShortDate(monthEnd)}';
    }
  }

  // 根据视图类型获取相应的数据
  _ViewData _getViewData(ViewType viewType, VaultService vaultService) {
    switch (viewType) {
      case ViewType.day:
        return _ViewData(
          earnings: vaultService.todayEarnings,
          progress: 0.35,
          workDuration: const Duration(hours: 2, minutes: 45),
          achievements: 2,
          totalEarnings: vaultService.weekEarnings,
          averageEarnings: 432.45,
          estimatedEarnings: 9513.90,
          isUpTrend: true,
        );
      case ViewType.week:
        return _ViewData(
          earnings: vaultService.weekEarnings,
          progress: 0.65,
          workDuration: const Duration(hours: 18, minutes: 30),
          achievements: 5,
          totalEarnings: vaultService.monthEarnings,
          averageEarnings: 2162.25,
          estimatedEarnings: 9513.90,
          isUpTrend: true,
        );
      case ViewType.month:
        return _ViewData(
          earnings: vaultService.monthEarnings,
          progress: 0.80,
          workDuration: const Duration(hours: 80, minutes: 15),
          achievements: 12,
          totalEarnings: vaultService.totalEarnings,
          averageEarnings: 9513.90,
          estimatedEarnings: 114166.80,
          isUpTrend: false,
        );
    }
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分钟' : ''}';
    } else {
      return '$minutes分钟';
    }
  }

  Widget _buildDataCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
    BuildContext context,
    String label,
    String value,
    bool isUp,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isUp ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    final months = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    return '${date.year}年${months[date.month - 1]}${date.day}日';
  }

  String formatShortDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  // 切换到下一个视图
  void _switchToNextView() {
    switch (_currentViewType) {
      case ViewType.day:
        _changeViewType(ViewType.week);
        break;
      case ViewType.week:
        _changeViewType(ViewType.month);
        break;
      case ViewType.month:
        // 已经是最后一个视图，不做任何操作
        break;
    }
  }

  // 切换到上一个视图
  void _switchToPreviousView() {
    switch (_currentViewType) {
      case ViewType.day:
        // 已经是第一个视图，不做任何操作
        break;
      case ViewType.week:
        _changeViewType(ViewType.day);
        break;
      case ViewType.month:
        _changeViewType(ViewType.week);
        break;
    }
  }
}

// 视图数据类
class _ViewData {
  final double earnings;
  final double progress;
  final Duration workDuration;
  final int achievements;
  final double totalEarnings;
  final double averageEarnings;
  final double estimatedEarnings;
  final bool isUpTrend;

  _ViewData({
    required this.earnings,
    required this.progress,
    required this.workDuration,
    required this.achievements,
    required this.totalEarnings,
    required this.averageEarnings,
    required this.estimatedEarnings,
    required this.isUpTrend,
  });
}
