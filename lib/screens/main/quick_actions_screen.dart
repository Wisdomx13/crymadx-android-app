import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../navigation/app_router.dart';

/// Quick Actions Screen - Full page with all quick actions
class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Trading Section
                _buildSectionHeader('Trading', isDark),
                const SizedBox(height: 12),
                _buildActionsGrid([
                  _QuickAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'P2P Trading',
                    description: 'Buy & sell with users',
                    color: const Color(0xFF00C853),
                    onTap: () => context.push(AppRoutes.p2p),
                  ),
                  _QuickAction(
                    icon: Icons.sync_alt_rounded,
                    label: 'Convert',
                    description: 'Swap crypto instantly',
                    color: const Color(0xFF2196F3),
                    onTap: () => context.push(AppRoutes.convert),
                  ),
                  _QuickAction(
                    icon: Icons.candlestick_chart_rounded,
                    label: 'Spot Trade',
                    description: 'Trade on spot market',
                    color: const Color(0xFFFF9800),
                    onTap: () => context.go(AppRoutes.trade),
                  ),
                  _QuickAction(
                    icon: Icons.diamond_rounded,
                    label: 'NFT',
                    description: 'Trade digital assets',
                    color: const Color(0xFF9C27B0),
                    onTap: () => context.push(AppRoutes.nft),
                  ),
                ], isDark),

                const SizedBox(height: 16),

                // Earn Section
                _buildSectionHeader('Earn', isDark),
                const SizedBox(height: 12),
                _buildActionsGrid([
                  _QuickAction(
                    icon: Icons.savings_rounded,
                    label: 'Earn',
                    description: 'Grow your crypto',
                    color: const Color(0xFF4CAF50),
                    onTap: () => context.push(AppRoutes.earn),
                  ),
                  _QuickAction(
                    icon: Icons.lock_rounded,
                    label: 'Staking',
                    description: 'Stake & earn rewards',
                    color: const Color(0xFF673AB7),
                    onTap: () => context.push(AppRoutes.stake),
                  ),
                  _QuickAction(
                    icon: Icons.credit_card_rounded,
                    label: 'Fiat On-Ramp',
                    description: 'Buy with card/bank',
                    color: const Color(0xFFE91E63),
                    onTap: () => context.push(AppRoutes.fiat),
                  ),
                  _QuickAction(
                    icon: Icons.emoji_events_rounded,
                    label: 'Rewards',
                    description: 'Claim your rewards',
                    color: const Color(0xFFFFD700),
                    onTap: () => context.push(AppRoutes.rewards),
                  ),
                ], isDark),

                const SizedBox(height: 16),

                // Finance Section
                _buildSectionHeader('Finance', isDark),
                const SizedBox(height: 12),
                _buildActionsGrid([
                  _QuickAction(
                    icon: Icons.add_circle_rounded,
                    label: 'Deposit',
                    description: 'Add funds',
                    color: const Color(0xFF4CAF50),
                    onTap: () => context.push(AppRoutes.deposit),
                  ),
                  _QuickAction(
                    icon: Icons.remove_circle_rounded,
                    label: 'Withdraw',
                    description: 'Withdraw funds',
                    color: const Color(0xFFF44336),
                    onTap: () => context.push(AppRoutes.withdraw),
                  ),
                  _QuickAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transfer',
                    description: 'Move between accounts',
                    color: const Color(0xFF3F51B5),
                    onTap: () => context.push(AppRoutes.transfer),
                  ),
                  _QuickAction(
                    icon: Icons.credit_score_rounded,
                    label: 'Payment',
                    description: 'Manage payment methods',
                    color: const Color(0xFFFF5722),
                    onTap: () => context.push(AppRoutes.paymentMethods),
                  ),
                ], isDark),

                const SizedBox(height: 16),

                // More Section
                _buildSectionHeader('More', isDark),
                const SizedBox(height: 12),
                _buildActionsGrid([
                  _QuickAction(
                    icon: Icons.emoji_events_rounded,
                    label: 'Rewards',
                    description: 'Claim your rewards',
                    color: const Color(0xFFFFD700),
                    onTap: () => context.push(AppRoutes.rewards),
                  ),
                  _QuickAction(
                    icon: Icons.people_rounded,
                    label: 'Referral',
                    description: 'Invite & earn',
                    color: const Color(0xFF00BFA5),
                    onTap: () => context.push(AppRoutes.referral),
                  ),
                  _QuickAction(
                    icon: Icons.history_rounded,
                    label: 'History',
                    description: 'Transaction records',
                    color: const Color(0xFF607D8B),
                    onTap: () => context.push(AppRoutes.transactionHistory),
                  ),
                  _QuickAction(
                    icon: Icons.verified_user_rounded,
                    label: 'Verification',
                    description: 'Complete KYC',
                    color: const Color(0xFF8BC34A),
                    onTap: () => context.push(AppRoutes.kyc),
                  ),
                ], isDark),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.grey[400] : const Color(0xFF555555),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActionsGrid(List<_QuickAction> actions, bool isDark) {
    return Row(
      children: actions.map((action) => Expanded(
        child: _buildActionCard(action, isDark),
      )).toList(),
    );
  }

  Widget _buildActionCard(_QuickAction action, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final iconBgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);

    return Builder(
      builder: (context) => GestureDetector(
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark ? null : Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });
}
