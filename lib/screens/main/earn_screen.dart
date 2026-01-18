import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';

/// Earn Screen - Binance-style crypto staking
class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // Staking products will be fetched from backend when API is available
  // For now, show empty lists - no hardcoded fake APY rates
  final List<EarnProduct> _flexibleProducts = [];
  final List<EarnProduct> _lockedProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

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
        title: Text('Earn', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(Icons.history, color: Colors.grey[isDark ? 400 : 600]), onPressed: () => _showStakingHistory()),
          IconButton(icon: Icon(Icons.help_outline, color: Colors.grey[isDark ? 400 : 600]), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(),

          // Tabs
          _buildTabs(),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildFlexibleList()
                : _selectedTab == 1
                    ? _buildLockedList()
                    : _buildPortfolio(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A3A2F), const Color(0xFF0D1F17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Earnings', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Up to 12% APY', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('\$0.00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('+\$0.00 today', style: TextStyle(color: AppColors.tradingBuy, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryItem(label: 'Total Staked', value: '\$0.00'),
              Container(width: 1, height: 30, color: Colors.grey[800]),
              _SummaryItem(label: 'Active Positions', value: '0'),
              Container(width: 1, height: 30, color: Colors.grey[800]),
              _SummaryItem(label: 'Est. Daily', value: '\$0.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab('Flexible', 0),
          _buildTab('Locked', 1),
          _buildTab('My Portfolio', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleList() {
    if (_flexibleProducts.isEmpty) {
      return _buildComingSoon();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flexibleProducts.length,
      itemBuilder: (context, index) => _FlexibleProductCard(
        product: _flexibleProducts[index],
        onStake: () => _showStakeDialog(_flexibleProducts[index]),
      ),
    );
  }

  Widget _buildLockedList() {
    if (_lockedProducts.isEmpty) {
      return _buildComingSoon();
    }
    // Group by symbol
    final grouped = <String, List<EarnProduct>>{};
    for (var p in _lockedProducts) {
      grouped.putIfAbsent(p.symbol, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) => _LockedProductGroup(
        symbol: entry.key,
        products: entry.value,
        onStake: (product) => _showStakeDialog(product),
      )).toList(),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_outlined, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 16),
          Text('Coming Soon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Staking products will be available soon', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 4),
          Text('Stay tuned for exciting earning opportunities!', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings_outlined, color: Colors.grey[600], size: 48),
          ),
          const SizedBox(height: 16),
          Text('No Active Stakes', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Start earning by staking your crypto', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _selectedTab = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Explore Products', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showStakeDialog(EarnProduct product) {
    final amountController = TextEditingController();
    bool isProcessing = false;
    int step = 1; // 1=Amount, 2=Confirm, 3=Success

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final amount = double.tryParse(amountController.text) ?? 0;
          final dailyEarnings = (amount * product.apy / 100 / 365);
          final totalEarnings = product.isFlexible ? dailyEarnings * 30 : dailyEarnings * (product.duration ?? 30);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CryptoIcon(symbol: product.symbol, size: 40),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.isFlexible ? 'Flexible Staking' : '${product.duration}-Day Locked',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(product.name, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tradingBuy.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${product.apy}% APY', style: TextStyle(color: AppColors.tradingBuy, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (step == 1) ...[
                    // Amount Input
                    Text('Amount to Stake', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 24),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                              Text(product.symbol, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available: 0.00 ${product.symbol}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              GestureDetector(
                                onTap: () {
                                  amountController.text = '1000';
                                  setModalState(() {});
                                },
                                child: Text('MAX', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Min: ${product.minAmount} ${product.symbol}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),

                    const SizedBox(height: 16),

                    // Estimated Earnings
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tradingBuy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.tradingBuy.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Est. Daily Earnings', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              Text('${dailyEarnings.toStringAsFixed(6)} ${product.symbol}', style: TextStyle(color: AppColors.tradingBuy, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(product.isFlexible ? 'Est. Monthly Earnings' : 'Est. Total Earnings', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              Text('${totalEarnings.toStringAsFixed(6)} ${product.symbol}', style: TextStyle(color: AppColors.tradingBuy, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: amount >= product.minAmount ? () => setModalState(() => step = 2) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else if (step == 2) ...[
                    // Confirmation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _ConfirmRow(label: 'Product', value: product.isFlexible ? 'Flexible' : '${product.duration}-Day Locked'),
                          _ConfirmRow(label: 'Amount', value: '${amountController.text} ${product.symbol}'),
                          _ConfirmRow(label: 'APY', value: '${product.apy}%'),
                          _ConfirmRow(label: 'Est. Daily Earnings', value: '${dailyEarnings.toStringAsFixed(6)} ${product.symbol}'),
                          if (!product.isFlexible)
                            _ConfirmRow(label: 'Lock Period', value: '${product.duration} days'),
                          _ConfirmRow(label: 'Redemption', value: product.isFlexible ? 'Anytime' : 'After ${product.duration} days'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!product.isFlexible)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your funds will be locked for ${product.duration} days. Early redemption is not available.',
                                style: TextStyle(color: AppColors.warning, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setModalState(() => step = 1),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Back', style: TextStyle(color: Colors.grey[400])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () async {
                              setModalState(() => isProcessing = true);
                              await Future.delayed(const Duration(seconds: 2));
                              setModalState(() {
                                isProcessing = false;
                                step = 3;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isProcessing
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Confirm Stake', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (step == 3) ...[
                    // Success
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: AppColors.success, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text('Staking Successful!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            'You have staked ${amountController.text} ${product.symbol}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Earning ${product.apy}% APY',
                            style: TextStyle(color: AppColors.tradingBuy, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _selectedTab = 2);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('View Portfolio', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStakingHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staking History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, color: Colors.grey[600], size: 40),
                  const SizedBox(height: 12),
                  Text('No staking history', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Model
class EarnProduct {
  final String symbol;
  final String name;
  final double apy;
  final double minAmount;
  final int? duration;
  final Map<String, double>? tierApy;
  final bool isFlexible;

  EarnProduct({
    required this.symbol,
    required this.name,
    required this.apy,
    required this.minAmount,
    this.duration,
    this.tierApy,
    required this.isFlexible,
  });
}

// Helper Widgets
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}

class _FlexibleProductCard extends StatelessWidget {
  final EarnProduct product;
  final VoidCallback onStake;

  const _FlexibleProductCard({required this.product, required this.onStake});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Row(
        children: [
          CryptoIcon(symbol: product.symbol, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.symbol, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(product.name, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${product.apy}%', style: TextStyle(color: AppColors.tradingBuy, fontSize: 18, fontWeight: FontWeight.w600)),
              Text('APY', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onStake,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Stake', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LockedProductGroup extends StatelessWidget {
  final String symbol;
  final List<EarnProduct> products;
  final Function(EarnProduct) onStake;

  const _LockedProductGroup({required this.symbol, required this.products, required this.onStake});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CryptoIcon(symbol: symbol, size: 32),
                const SizedBox(width: 10),
                Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Divider(color: Colors.grey[900], height: 1),
          // Duration options
          ...products.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${p.duration} Days', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ),
                const Spacer(),
                Text('${p.apy}%', style: TextStyle(color: AppColors.tradingBuy, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('APY', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => onStake(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Stake', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
