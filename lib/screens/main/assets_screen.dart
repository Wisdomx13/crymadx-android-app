import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../providers/currency_provider.dart';
import '../../providers/balance_provider.dart';
import '../../navigation/app_router.dart';
import '../../services/wallet_service.dart';

/// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Assets Screen - Bybit-style wallet
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _hideBalance = false;
  List<dynamic> _recentTransactions = [];
  bool _loadingTransactions = false;
  int _selectedAccountTab = 0; // 0 = All, 1 = Funding, 2 = Trading

  @override
  void initState() {
    super.initState();
    // Load balances from backend API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceProvider>().loadBalances();
    });
    _loadRecentTransactions();
  }

  /// Get assets based on selected tab
  List<AssetBalance> _getFilteredAssets(BalanceProvider balanceProvider) {
    switch (_selectedAccountTab) {
      case 1: // Funding
        return balanceProvider.fundingAssets;
      case 2: // Trading
        return balanceProvider.tradingAssets;
      default: // All (Combined)
        return _getCombinedAssets(balanceProvider);
    }
  }

  /// Combine funding and trading assets into a single list
  List<AssetBalance> _getCombinedAssets(BalanceProvider balanceProvider) {
    final Map<String, AssetBalance> combined = {};

    // Add funding assets
    for (final asset in balanceProvider.fundingAssets) {
      combined[asset.symbol] = asset;
    }

    // Add/merge trading assets
    for (final asset in balanceProvider.tradingAssets) {
      if (combined.containsKey(asset.symbol)) {
        // Combine amounts
        final existing = combined[asset.symbol]!;
        combined[asset.symbol] = AssetBalance(
          symbol: asset.symbol,
          name: asset.name,
          amount: existing.amount + asset.amount,
          price: asset.price, // Use same price
          available: existing.available + asset.available,
        );
      } else {
        combined[asset.symbol] = asset;
      }
    }

    return combined.values.toList();
  }

  /// Get balance based on selected tab
  double _getDisplayBalance(BalanceProvider balanceProvider) {
    switch (_selectedAccountTab) {
      case 1: // Funding
        return balanceProvider.fundingAssets.fold(0.0, (sum, asset) => sum + (asset.amount * asset.price));
      case 2: // Trading
        return balanceProvider.tradingAssets.fold(0.0, (sum, asset) => sum + (asset.amount * asset.price));
      default: // All (Total)
        return balanceProvider.totalBalance;
    }
  }

  Future<void> _loadRecentTransactions() async {
    setState(() => _loadingTransactions = true);
    try {
      final transactions = await walletService.getTransfers(limit: 3);
      if (mounted) {
        setState(() {
          _recentTransactions = transactions;
          _loadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTransactions = false);
      }
    }
  }

  String _formatTransactionTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final cardBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, _) {
        // Get balance based on selected tab
        final displayBalance = _getDisplayBalance(balanceProvider);

        return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Assets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey[isDark ? 400 : 600], size: 24),
            onPressed: () => context.push(AppRoutes.transactionHistory),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance Section
                Consumer<CurrencyProvider>(
                  builder: (context, currency, _) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Total Balance', style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF333333), fontSize: 14)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _hideBalance = !_hideBalance),
                                child: Icon(
                                  _hideBalance ? Icons.visibility_off : Icons.visibility,
                                  color: isDark ? Colors.grey[500] : const Color(0xFF333333),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _hideBalance ? '****' : currency.formatAmount(displayBalance),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hideBalance ? '≈ **** BTC' : '≈ ${(displayBalance / 91000).toStringAsFixed(4)} BTC',
                            style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF333333), fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Action Buttons Row - Bybit Style (Deposit, Withdraw, Transfer, Convert)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.south_west_rounded,
                          label: 'Deposit',
                          isHighlighted: true,
                          onTap: () => context.push(AppRoutes.deposit),
                        ),
                      ),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.north_east_rounded,
                          label: 'Withdraw',
                          onTap: () => context.push(AppRoutes.withdraw),
                        ),
                      ),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Transfer',
                          onTap: () => context.push(AppRoutes.transfer),
                        ),
                      ),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Convert',
                          onTap: () => context.push(AppRoutes.convert),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // My Assets Header with Tabs
                Text(
                  'My Assets',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 16),

                // Account Tabs
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAccountTab('All', 0, isDark),
                      ),
                      Expanded(
                        child: _buildAccountTab('Funding', 1, isDark),
                      ),
                      Expanded(
                        child: _buildAccountTab('Trading', 2, isDark),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Asset List - Show filtered assets
                ..._getFilteredAssets(balanceProvider).map((asset) => _buildAssetCardFromProvider(asset)),

                // Show empty state if no assets
                if (_getFilteredAssets(balanceProvider).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48, color: isDark ? Colors.grey[600] : const Color(0xFF333333)),
                        const SizedBox(height: 12),
                        Text(
                          'No assets yet',
                          style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF333333), fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deposit crypto to get started',
                          style: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF444444), fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.transactionHistory),
                      child: Row(
                        children: [
                          Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Transaction List - Real data
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: isDark ? null : Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _loadingTransactions
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : _recentTransactions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 40, color: isDark ? Colors.grey[600] : const Color(0xFF333333)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF333333), fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: _recentTransactions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tx = entry.value as Transaction;
                                final isDeposit = tx.type.toLowerCase() == 'deposit';
                                final amount = '${isDeposit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${tx.currency}';
                                final time = _formatTransactionTime(tx.createdAt);
                                return Column(
                                  children: [
                                    if (index > 0) Divider(color: isDark ? Colors.grey[900] : Colors.grey[300], height: 1),
                                    _buildTransactionRow(tx.type.capitalize(), amount, time, isDeposit),
                                  ],
                                );
                              }).toList(),
                            ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.tradingBuy  // Green for Deposit
                  : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : (isDark ? Colors.grey[400] : const Color(0xFF333333)),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : const Color(0xFF333333),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(String label, int index, bool isDark) {
    final isSelected = _selectedAccountTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.grey[400] : const Color(0xFF666666)),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCardFromProvider(AssetBalance asset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.coinDetail,
          extra: {
            'symbol': asset.symbol,
            'name': asset.name,
            'amount': asset.amount,
            'valueUsd': asset.valueUsd,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CryptoIcon(symbol: asset.symbol, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF333333), fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _hideBalance ? '****' : asset.amount.toStringAsFixed(asset.amount < 1 ? 4 : 2),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hideBalance ? '****' : '\$${asset.valueUsd.toStringAsFixed(2)}',
                  style: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF333333), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[isDark ? 700 : 500], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String type, String amount, String time, bool isPositive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.tradingBuy : AppColors.tradingSell).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
