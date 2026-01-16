import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// Rewards Screen - Demo workflow
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<_Reward> _rewards = [
    _Reward(title: 'Welcome Bonus', description: 'Complete KYC verification', points: 100, isCompleted: true, icon: Icons.celebration),
    _Reward(title: 'First Trade', description: 'Make your first spot trade', points: 50, isCompleted: true, icon: Icons.swap_horiz),
    _Reward(title: 'First Deposit', description: 'Deposit \$100 or more', points: 75, isCompleted: false, icon: Icons.account_balance_wallet),
    _Reward(title: 'Referral Bonus', description: 'Invite 3 friends', points: 200, isCompleted: false, icon: Icons.people),
    _Reward(title: 'Volume Milestone', description: 'Trade \$1,000 in volume', points: 150, isCompleted: false, icon: Icons.trending_up),
    _Reward(title: 'Weekly Streak', description: 'Trade 7 days in a row', points: 100, isCompleted: false, icon: Icons.local_fire_department),
  ];

  int get _totalPoints => _rewards.where((r) => r.isCompleted).fold(0, (sum, r) => sum + r.points);
  int get _completedCount => _rewards.where((r) => r.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
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
      body: SingleChildScrollView(
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_completedCount/${_rewards.length} Tasks Completed',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Available Rewards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._rewards.map((reward) => _RewardCard(reward: reward, onClaim: () {
              if (!reward.isCompleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Complete "${reward.description}" to earn ${reward.points} points!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            })),
          ],
        ),
      ),
    );
  }
}

class _Reward {
  final String title;
  final String description;
  final int points;
  final bool isCompleted;
  final IconData icon;

  const _Reward({required this.title, required this.description, required this.points, required this.isCompleted, required this.icon});
}

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  final VoidCallback onClaim;

  const _RewardCard({required this.reward, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: reward.isCompleted ? AppColors.tradingBuy.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reward.icon,
              color: reward.isCompleted ? AppColors.tradingBuy : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(reward.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                  Text('+${reward.points}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onClaim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: reward.isCompleted ? AppColors.tradingBuy : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reward.isCompleted ? 'Claimed' : 'Claim',
                    style: TextStyle(color: reward.isCompleted ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
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
