import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/user_service.dart';

/// Rewards Screen - Dynamic with API integration
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isLoading = true;
  String? _error;
  RewardsSummary? _summary;
  List<RewardTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await userService.getRewardsSummary();
      setState(() {
        _summary = summary;
        _tasks = summary.tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int get _totalPoints => _summary?.totalPoints ?? 0;
  int get _completedCount => _tasks.where((t) => t.completed).length;

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'kyc':
      case 'welcome':
        return Icons.celebration;
      case 'trade':
      case 'trading':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.account_balance_wallet;
      case 'referral':
        return Icons.people;
      case 'volume':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.stars;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Rewards', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRewards,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRewards,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Points Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.black, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                '$_totalPoints',
                                style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const Text('Total Points', style: TextStyle(color: Colors.black87, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (_summary != null) ...[
                                Text(
                                  'Tier: ${_summary!.currentTier}',
                                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                if (_summary!.nextTier.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_summary!.pointsToNextTier} pts to ${_summary!.nextTier}',
                                    style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 11),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_completedCount/${_tasks.length} Tasks Completed',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Available Rewards',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_tasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.stars_outlined, size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No rewards available yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._tasks.map((task) => _RewardCard(
                            task: task,
                            icon: _getIconForCategory(task.category),
                            onClaim: () {
                              if (!task.completed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Complete "${task.description}" to earn ${task.points} points!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                          )),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardTask task;
  final IconData icon;
  final VoidCallback onClaim;

  const _RewardCard({
    required this.task,
    required this.icon,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: task.completed ? AppColors.tradingBuy.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: task.completed ? AppColors.tradingBuy : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text('+${task.points}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onClaim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.completed ? AppColors.tradingBuy : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.completed ? 'Claimed' : 'Claim',
                    style: TextStyle(
                      color: task.completed ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
