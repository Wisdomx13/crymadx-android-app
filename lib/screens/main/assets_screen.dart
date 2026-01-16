import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../providers/currency_provider.dart';
import '../../providers/balance_provider.dart';
import '../../navigation/app_router.dart';

/// Assets Screen - Bybit-style wallet
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  int _selectedAccountTab = 0; // 0 = Funding, 1 = Trading
  bool _hideBalance = false;

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
        // Total balance = funding + trading (same as home page)
        final totalBalance = balanceProvider.totalBalance;

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
                              Text('Total Balance', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _hideBalance = !_hideBalance),
                                child: Icon(
                                  _hideBalance ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[500],
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _hideBalance ? '****' : currency.formatAmount(totalBalance),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hideBalance ? '≈ **** BTC' : '≈ ${(totalBalance / 91000).toStringAsFixed(4)} BTC',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Action Buttons Row - Bybit Style (full width spread)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                const SizedBox(height: 28),

                // Account Type Cards - Crystal Clear Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedAccountTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedAccountTab == 0
                                ? (isDark ? const Color(0xFF0A3D1F) : const Color(0xFFE8F5E9))
                                : (isDark ? const Color(0xFF121212) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedAccountTab == 0
                                  ? AppColors.primary
                                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              width: _selectedAccountTab == 0 ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedAccountTab == 0
                                    ? AppColors.primary.withOpacity(isDark ? 0.3 : 0.2)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: _selectedAccountTab == 0 ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedAccountTab == 0
                                          ? AppColors.primary
                                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: _selectedAccountTab == 0
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      size: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_selectedAccountTab == 0)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Funding',
                                style: TextStyle(
                                  color: _selectedAccountTab == 0
                                      ? (isDark ? Colors.white : const Color(0xFF000000))
                                      : (isDark ? Colors.grey[400] : const Color(0xFF333333)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hideBalance ? '****' : '\$${balanceProvider.fundingBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _selectedAccountTab == 0
                                      ? AppColors.primary
                                      : (isDark ? Colors.grey[500] : const Color(0xFF555555)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedAccountTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedAccountTab == 1
                                ? (isDark ? const Color(0xFF0A3D1F) : const Color(0xFFE8F5E9))
                                : (isDark ? const Color(0xFF121212) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedAccountTab == 1
                                  ? AppColors.primary
                                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              width: _selectedAccountTab == 1 ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedAccountTab == 1
                                    ? AppColors.primary.withOpacity(isDark ? 0.3 : 0.2)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: _selectedAccountTab == 1 ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedAccountTab == 1
                                          ? AppColors.primary
                                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.candlestick_chart_rounded,
                                      color: _selectedAccountTab == 1
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      size: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_selectedAccountTab == 1)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Trading',
                                style: TextStyle(
                                  color: _selectedAccountTab == 1
                                      ? (isDark ? Colors.white : const Color(0xFF000000))
                                      : (isDark ? Colors.grey[400] : const Color(0xFF333333)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hideBalance ? '****' : '\$${balanceProvider.tradingBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _selectedAccountTab == 1
                                      ? AppColors.primary
                                      : (isDark ? Colors.grey[500] : const Color(0xFF555555)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // My Assets Header
                Text(
                  'My Assets',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 16),

                // Asset List
                ..._getAssetsForAccount().map((asset) => _buildAssetCard(asset)),

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

                // Transaction List
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
                  child: Column(
                    children: [
                      _buildTransactionRow('Deposit', '+500.00 USDT', 'Today, 10:30 AM', true),
                      Divider(color: isDark ? Colors.grey[900] : Colors.grey[300], height: 1),
                      _buildTransactionRow('Buy BTC', '-250.00 USDT', 'Yesterday, 2:15 PM', false),
                      Divider(color: isDark ? Colors.grey[900] : Colors.grey[300], height: 1),
                      _buildTransactionRow('Transfer', '-100.00 USDT', 'Dec 28, 9:00 AM', false),
                    ],
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
              color: isHighlighted ? Colors.white : Colors.grey[isDark ? 400 : 600],
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[isDark ? 400 : 600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(_Asset asset) {
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
            'accountType': _selectedAccountTab == 0 ? 'funding' : 'trading',
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

  List<_Asset> _getAssetsForAccount() {
    if (_selectedAccountTab == 0) {
      return [
        _Asset(symbol: 'BTC', name: 'Bitcoin', amount: 0.1500, valueUsd: 6450.00),
        _Asset(symbol: 'ETH', name: 'Ethereum', amount: 1.5, valueUsd: 3420.00),
        _Asset(symbol: 'USDT', name: 'Tether', amount: 800.00, valueUsd: 800.00),
        _Asset(symbol: 'SOL', name: 'Solana', amount: 10.0, valueUsd: 984.50),
      ];
    } else {
      return [
        _Asset(symbol: 'BTC', name: 'Bitcoin', amount: 0.0879, valueUsd: 3782.00),
        _Asset(symbol: 'ETH', name: 'Ethereum', amount: 1.0, valueUsd: 2280.00),
        _Asset(symbol: 'USDT', name: 'Tether', amount: 450.00, valueUsd: 450.00),
        _Asset(symbol: 'SOL', name: 'Solana', amount: 5.5, valueUsd: 542.25),
      ];
    }
  }
}

class _Asset {
  final String symbol;
  final String name;
  final double amount;
  final double valueUsd;

  const _Asset({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.valueUsd,
  });
}
