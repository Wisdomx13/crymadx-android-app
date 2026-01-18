import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/user_service.dart';

/// Referral Program Screen - Dynamic with API integration
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _isLoading = true;
  String? _error;
  ReferralStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadReferralStats();
  }

  Future<void> _loadReferralStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await userService.getReferralStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '***';
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    return '${name[0]}***@$domain';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);

    // Dynamic values from API
    final referralCode = _stats?.referralCode ?? '';
    final referralLink = _stats?.referralLink ?? '';
    final totalEarnings = _stats?.totalEarnings ?? 0.0;
    final totalReferrals = _stats?.totalReferrals ?? 0;
    final commissionRate = (_stats?.commissionRate ?? 0.10) * 100;
    final perReferral = totalReferrals > 0 ? totalEarnings / totalReferrals : 0.0;
    final referrals = _stats?.referrals ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Referral Program', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
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
                        onPressed: _loadReferralStats,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReferralStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Earnings Card
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
                              const Icon(Icons.people_alt, color: Colors.black, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                '\$${totalEarnings.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                              const Text('Total Earnings', style: TextStyle(color: Colors.black87, fontSize: 14)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatColumn(value: '$totalReferrals', label: 'Referrals'),
                                  Container(width: 1, height: 30, color: Colors.black26),
                                  _StatColumn(value: '\$${perReferral.toStringAsFixed(0)}', label: 'Per Referral'),
                                  Container(width: 1, height: 30, color: Colors.black26),
                                  _StatColumn(value: '${commissionRate.toStringAsFixed(0)}%', label: 'Commission'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Referral Code
                        Text('Your Referral Code', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  referralCode.isNotEmpty ? referralCode : 'Loading...',
                                  style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                              ),
                              GestureDetector(
                                onTap: referralCode.isNotEmpty ? () {
                                  Clipboard.setData(ClipboardData(text: referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Referral code copied!'), backgroundColor: AppColors.success),
                                  );
                                } : null,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.copy, color: Colors.black, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Share Link
                        Text('Share Link', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  referralLink.isNotEmpty ? referralLink : 'Loading...',
                                  style: TextStyle(color: Colors.grey[isDark ? 500 : 600], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: referralLink.isNotEmpty ? () {
                                  Clipboard.setData(ClipboardData(text: referralLink));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Link copied!'), backgroundColor: AppColors.success),
                                  );
                                } : null,
                                child: Text('Copy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // How it works
                        Text('How It Works', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _HowItWorksStep(number: '1', title: 'Share Your Code', description: 'Send your unique referral code to friends', isDark: isDark),
                        _HowItWorksStep(number: '2', title: 'Friend Signs Up', description: 'They register using your referral code', isDark: isDark),
                        _HowItWorksStep(number: '3', title: 'Both Earn Rewards', description: 'You get commission, they get bonus', isDark: isDark),
                        const SizedBox(height: 24),
                        // Recent Referrals
                        Text('Recent Referrals', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (referrals.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No referrals yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Share your code to start earning!',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...referrals.take(10).map((ref) => _ReferralItem(
                            name: _maskEmail(ref.email),
                            date: _formatDate(ref.joinedAt),
                            amount: '\$${ref.earnings.toStringAsFixed(2)}',
                            isDark: isDark,
                          )),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isDark;

  const _HowItWorksStep({required this.number, required this.title, required this.description, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralItem extends StatelessWidget {
  final String name;
  final String date;
  final String amount;
  final bool isDark;

  const _ReferralItem({required this.name, required this.date, required this.amount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.tradingBuy.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.person, color: AppColors.tradingBuy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: AppColors.tradingBuy, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
