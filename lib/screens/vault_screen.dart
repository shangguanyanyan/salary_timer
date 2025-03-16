import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vault_service.dart';
import '../models/earning_record.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import '../providers/data_provider.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  String _currency = '¥';
  bool _isFirstLoad = true; // 标记是否是首次加载

  @override
  void initState() {
    super.initState();
    _loadCurrencySetting();
  }

  Future<void> _loadCurrencySetting() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    setState(() {
      _currency = dataProvider.currency;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里设置首次加载标记，确保在页面切换回来时不会再次触发动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultService = Provider.of<VaultService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final unreadCount = notificationService.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的金库'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 金库总额
                _buildTotalEarningsCard(context, vaultService, dataProvider),

                const SizedBox(height: 24),

                // 储蓄目标
                _buildSavingGoalCard(context, vaultService, dataProvider),

                const SizedBox(height: 24),

                // 收入统计
                _buildEarningStatsCard(context, vaultService, dataProvider),

                const SizedBox(height: 24),

                // 收入历史
                _buildEarningHistoryCard(context, vaultService, dataProvider),

                // 底部空间，防止内容被底部按钮遮挡
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _showSetGoalDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.flag),
          label: const Text(
            '设置储蓄目标',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 金库总额卡片
  Widget _buildTotalEarningsCard(
    BuildContext context,
    VaultService vaultService,
    DataProvider dataProvider,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('金库总额', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _isFirstLoad
                ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: dataProvider.totalEarnings,
                  ),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$_currency ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          TextSpan(
                            text: value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                : RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_currency ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      TextSpan(
                        text: dataProvider.totalEarnings.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // 储蓄目标卡片
  Widget _buildSavingGoalCard(
    BuildContext context,
    VaultService vaultService,
    DataProvider dataProvider,
  ) {
    // 如果没有设置目标，显示设置目标的卡片
    if (dataProvider.savingGoal <= 0) {
      return Card(
        child: InkWell(
          onTap: () => _showSetGoalDialog(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                Text('设置储蓄目标', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '设置一个储蓄目标，追踪你的进度',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 计算进度值
    final progressValue =
        dataProvider.savingGoal > 0
            ? (dataProvider.totalEarnings / dataProvider.savingGoal).clamp(
              0.0,
              1.0,
            )
            : 0.0;

    // 计算进度百分比
    final progressPercent = (progressValue * 100).toStringAsFixed(1);

    // 显示目标进度卡片
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '目标: ${dataProvider.goalName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isFirstLoad
                ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progressValue),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                )
                : LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isFirstLoad
                    ? TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: dataProvider.totalEarnings,
                      ),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '$_currency${value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        );
                      },
                    )
                    : Text(
                      '$_currency${dataProvider.totalEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                Text(
                  '$_currency${dataProvider.savingGoal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isFirstLoad
                ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: double.parse(progressPercent),
                  ),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '进度: ${value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                )
                : Text(
                  '进度: $progressPercent%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            if (dataProvider.goalDeadline != null) ...[
              const SizedBox(height: 8),
              Text(
                '截止日期: ${_formatDate(dataProvider.goalDeadline!)}',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 收入统计卡片
  Widget _buildEarningStatsCard(
    BuildContext context,
    VaultService vaultService,
    DataProvider dataProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收入统计', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  '今日',
                  '$_currency${dataProvider.todayEarnings.toStringAsFixed(2)}',
                  dataProvider.todayEarnings,
                ),
                _buildStatItem(
                  context,
                  '本周',
                  '$_currency${dataProvider.weekEarnings.toStringAsFixed(2)}',
                  dataProvider.weekEarnings,
                ),
                _buildStatItem(
                  context,
                  '本月',
                  '$_currency${dataProvider.monthEarnings.toStringAsFixed(2)}',
                  dataProvider.monthEarnings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 统计项目
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, [
    double? animatedValue,
  ]) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        if (_isFirstLoad && animatedValue != null)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: animatedValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '$_currency${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              );
            },
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
      ],
    );
  }

  // 收入历史卡片
  Widget _buildEarningHistoryCard(
    BuildContext context,
    VaultService vaultService,
    DataProvider dataProvider,
  ) {
    // 使用 FutureBuilder 来处理异步数据
    return FutureBuilder<Map<String, List<EarningRecord>>>(
      future: dataProvider.getGroupedEarnings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('加载数据时出错')),
            ),
          );
        }

        final groupedRecords = snapshot.data ?? {};

        if (groupedRecords.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无收入记录',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '收入历史',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // 查看更多历史记录
                        _showAllHistoryDialog(context, vaultService);
                      },
                      child: const Text('查看更多'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...groupedRecords.entries.take(5).map((entry) {
                  final dateStr = entry.key;
                  final records = entry.value;
                  final totalAmount = records.fold<double>(
                    0,
                    (sum, record) => sum + record.amount,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '$_currency${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...records.take(3).map((record) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(record.date),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$_currency${record.amount.toStringAsFixed(2)} (${_formatDuration(record.workDuration)})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (records.length > 3)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '还有 ${records.length - 3} 条记录',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 设置目标对话框
  void _showSetGoalDialog(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final goalController = TextEditingController(
      text:
          dataProvider.savingGoal > 0 ? dataProvider.savingGoal.toString() : '',
    );
    final nameController = TextEditingController(text: dataProvider.goalName);
    DateTime? selectedDate = dataProvider.goalDeadline;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      // 关闭所有输入框焦点
                      FocusScope.of(context).unfocus();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            '设置储蓄目标',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '目标名称',
                            hintText: '例如：新手机',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: goalController,
                          decoration: InputDecoration(
                            labelText: '目标金额',
                            hintText: '例如：5000',
                            prefixText: _currency,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDate != null
                                    ? '截止日期: ${_formatDate(selectedDate!)}'
                                    : '设置截止日期（可选）',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      selectedDate ??
                                      DateTime.now().add(
                                        const Duration(days: 30),
                                      ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365 * 5),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              child: Text(selectedDate != null ? '修改' : '选择'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final amount =
                                      double.tryParse(goalController.text) ?? 0;
                                  if (amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('请输入有效的目标金额'),
                                      ),
                                    );
                                    return;
                                  }

                                  dataProvider.saveSavingGoal(
                                    amount: amount,
                                    name: nameController.text.trim(),
                                    deadline: selectedDate,
                                  );
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                child: const Text('保存'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // 显示所有历史记录对话框
  void _showAllHistoryDialog(BuildContext context, VaultService vaultService) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: FutureBuilder<Map<String, List<EarningRecord>>>(
              future: dataProvider.getGroupedEarnings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('加载数据时出错: ${snapshot.error}'));
                }

                final groupedRecords = snapshot.data ?? {};

                if (groupedRecords.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无收入记录',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  width: double.maxFinite,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '收入历史',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: groupedRecords.length,
                          itemBuilder: (context, index) {
                            final entry = groupedRecords.entries.elementAt(
                              index,
                            );
                            final dateStr = entry.key;
                            final records = entry.value;
                            final totalAmount = records.fold<double>(
                              0,
                              (sum, record) => sum + record.amount,
                            );

                            return ExpansionTile(
                              title: Text(dateStr),
                              subtitle: Text(
                                '$_currency${totalAmount.toStringAsFixed(2)}',
                              ),
                              children:
                                  records.map((record) {
                                    return ListTile(
                                      title: Text(
                                        '$_currency${record.amount.toStringAsFixed(2)}',
                                      ),
                                      subtitle: Text(
                                        '工作时长: ${_formatDuration(record.workDuration)}',
                                      ),
                                      trailing: Text(
                                        _formatTime(record.date),
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.tertiary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
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

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  // 格式化时间
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
