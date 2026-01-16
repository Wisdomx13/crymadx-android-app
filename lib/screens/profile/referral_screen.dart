import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// Referral Program Screen - Demo workflow
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    const referralCode = 'CRYMADX2024';
    const referralLink = 'https://crymadx.com/ref/CRYMADX2024';

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
      body: SingleChildScrollView(
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
                  const Text('\$240.00', style: TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold)),
                  const Text('Total Earnings', style: TextStyle(color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(value: '12', label: 'Referrals'),
                      Container(width: 1, height: 30, color: Colors.black26),
                      _StatColumn(value: '\$20', label: 'Per Referral'),
                      Container(width: 1, height: 30, color: Colors.black26),
                      _StatColumn(value: '20%', label: 'Commission'),
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
                      referralCode,
                      style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Referral code copied!'), backgroundColor: AppColors.success),
                      );
                    },
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
                  Expanded(child: Text(referralLink, style: TextStyle(color: Colors.grey[isDark ? 500 : 600], fontSize: 13), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Link copied!'), backgroundColor: AppColors.success),
                      );
                    },
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
            _HowItWorksStep(number: '3', title: 'Both Earn Rewards', description: 'You get \$20, they get \$10 bonus', isDark: isDark),
            const SizedBox(height: 24),
            // Recent Referrals
            Text('Recent Referrals', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ReferralItem(name: 'j***@gmail.com', date: 'Dec 28, 2024', amount: '\$20', isDark: isDark),
            _ReferralItem(name: 'm***@yahoo.com', date: 'Dec 25, 2024', amount: '\$20', isDark: isDark),
            _ReferralItem(name: 'a***@outlook.com', date: 'Dec 20, 2024', amount: '\$20', isDark: isDark),
          ],
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
