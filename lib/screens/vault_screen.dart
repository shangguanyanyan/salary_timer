import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vault_service.dart';
import '../models/earning_record.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultService = Provider.of<VaultService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的金库'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 金库总额
                _buildTotalEarningsCard(context, vaultService),

                const SizedBox(height: 24),

                // 储蓄目标
                _buildSavingGoalCard(context, vaultService),

                const SizedBox(height: 24),

                // 收入统计
                _buildEarningStatsCard(context, vaultService),

                const SizedBox(height: 24),

                // 收入历史
                _buildEarningHistoryCard(context, vaultService),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSetGoalDialog(context),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: const Icon(Icons.flag),
        tooltip: '设置目标',
      ),
    );
  }

  // 金库总额卡片
  Widget _buildTotalEarningsCard(
    BuildContext context,
    VaultService vaultService,
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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '¥ ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  TextSpan(
                    text: vaultService.totalEarnings.toStringAsFixed(2),
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
  Widget _buildSavingGoalCard(BuildContext context, VaultService vaultService) {
    if (vaultService.savingGoal <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  '设置一个储蓄目标',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showSetGoalDialog(context),
                  child: const Text('设置目标'),
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
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '目标: ${vaultService.goalName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: vaultService.goalProgress / 100,
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
                Text(
                  '¥${vaultService.totalEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  '¥${vaultService.savingGoal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '进度: ${vaultService.goalProgress.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (vaultService.goalDeadline != null) ...[
              const SizedBox(height: 8),
              Text(
                '截止日期: ${_formatDate(vaultService.goalDeadline!)}',
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
                  '¥${vaultService.todayEarnings.toStringAsFixed(2)}',
                ),
                _buildStatItem(
                  context,
                  '本周',
                  '¥${vaultService.weekEarnings.toStringAsFixed(2)}',
                ),
                _buildStatItem(
                  context,
                  '本月',
                  '¥${vaultService.monthEarnings.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 收入历史卡片
  Widget _buildEarningHistoryCard(
    BuildContext context,
    VaultService vaultService,
  ) {
    if (vaultService.earningRecords.isEmpty) {
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
                Text('暂无收入记录', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      );
    }

    // 获取按日期分组的记录
    final groupedRecords = vaultService.getGroupedRecords();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('收入历史', style: Theme.of(context).textTheme.titleMedium),
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
                  Text(
                    _formatDisplayDate(dateStr),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '共 ${records.length} 次工作',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      Text(
                        '¥${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // 统计项
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
      ],
    );
  }

  // 设置目标对话框
  void _showSetGoalDialog(BuildContext context) {
    final vaultService = Provider.of<VaultService>(context, listen: false);
    final goalController = TextEditingController(
      text:
          vaultService.savingGoal > 0 ? vaultService.savingGoal.toString() : '',
    );
    final nameController = TextEditingController(text: vaultService.goalName);
    DateTime? selectedDate = vaultService.goalDeadline;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('设置储蓄目标'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '目标名称',
                          hintText: '例如：新手机',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: goalController,
                        decoration: const InputDecoration(
                          labelText: '目标金额',
                          hintText: '例如：5000',
                          prefixText: '¥',
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
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final amount = double.tryParse(goalController.text) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效的目标金额')),
                        );
                        return;
                      }

                      vaultService.setSavingGoal(
                        amount,
                        nameController.text.trim(),
                        selectedDate,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // 显示所有历史记录对话框
  void _showAllHistoryDialog(BuildContext context, VaultService vaultService) {
    final groupedRecords = vaultService.getGroupedRecords();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
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
                          '收入历史记录',
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
                        final entry = groupedRecords.entries.elementAt(index);
                        final dateStr = entry.key;
                        final records = entry.value;
                        final totalAmount = records.fold<double>(
                          0,
                          (sum, record) => sum + record.amount,
                        );

                        return ExpansionTile(
                          title: Text(_formatDisplayDate(dateStr)),
                          subtitle: Text('¥${totalAmount.toStringAsFixed(2)}'),
                          children:
                              records.map((record) {
                                final duration = _formatDuration(
                                  record.workDuration,
                                );
                                return ListTile(
                                  leading: const Icon(Icons.work),
                                  title: Text(
                                    '¥${record.amount.toStringAsFixed(2)}',
                                  ),
                                  subtitle: Text('工作时长: $duration'),
                                  trailing: Text(
                                    '¥${record.hourlyRate.toStringAsFixed(2)}/小时',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                      fontSize: 12,
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
            ),
          ),
    );
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 格式化显示日期
  String _formatDisplayDate(String dateStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final date = DateTime(year, month, day);

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return '今天';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天';
    } else {
      return dateStr;
    }
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分钟' : ''}';
    } else if (minutes > 0) {
      return '$minutes分钟${seconds > 0 ? ' $seconds秒' : ''}';
    } else {
      return '$seconds秒';
    }
  }
}
