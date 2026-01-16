import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/crypto_icon.dart';
import '../../navigation/app_router.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final double amount;
  final double valueUsd;
  final String accountType; // 'funding' or 'trading'

  const CoinDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.valueUsd,
    this.accountType = 'funding',
  });

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  bool _hideBalance = false;

  // Mock data for price change
  double get _priceChange => 2.45;
  double get _price => widget.valueUsd / widget.amount;

  // Mock balance breakdown
  double get _availableBalance => widget.amount * 0.85;
  double get _lockedBalance => widget.amount * 0.15;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CryptoIcon(symbol: widget.symbol, size: 28),
            const SizedBox(width: 10),
            Text(
              widget.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey[400], size: 24),
            onPressed: () => context.push(AppRoutes.transactionHistory),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Balance Card
                      _buildBalanceCard(),
                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // Balance Breakdown
                      _buildBalanceBreakdown(),
                      const SizedBox(height: 24),

                      // Price Info
                      _buildPriceInfo(),
                      const SizedBox(height: 24),

                      // Recent Transactions
                      _buildRecentTransactions(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF121212),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CryptoIcon(symbol: widget.symbol, size: 64),
          const SizedBox(height: 16),
          Text(
            widget.name,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _hideBalance
                    ? '****'
                    : '${widget.amount.toStringAsFixed(widget.amount < 1 ? 6 : 4)} ${widget.symbol}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _hideBalance = !_hideBalance),
                child: Icon(
                  _hideBalance ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[500],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _hideBalance ? '≈ \$****' : '≈ \$${widget.valueUsd.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.south_west_rounded,
              label: 'Deposit',
              isHighlighted: true,
              onTap: () => context.push(AppRoutes.deposit, extra: {'symbol': widget.symbol, 'name': widget.name}),
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.north_east_rounded,
              label: 'Withdraw',
              onTap: () => context.push(AppRoutes.withdraw, extra: {'symbol': widget.symbol, 'name': widget.name}),
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              onTap: () => context.push(AppRoutes.transfer, extra: {'symbol': widget.symbol, 'name': widget.name}),
            ),
          ),
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'Convert',
              onTap: () => context.push(AppRoutes.convert, extra: {'symbol': widget.symbol, 'name': widget.name}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
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
                  : const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isHighlighted ? Colors.white : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Details',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildBalanceRow(
            'Available',
            _hideBalance ? '****' : '${_availableBalance.toStringAsFixed(widget.amount < 1 ? 6 : 4)} ${widget.symbol}',
            _hideBalance ? '' : '\$${(_availableBalance * _price / widget.amount * widget.amount).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[900], height: 1),
          const SizedBox(height: 12),
          _buildBalanceRow(
            'In Orders',
            _hideBalance ? '****' : '${_lockedBalance.toStringAsFixed(widget.amount < 1 ? 6 : 4)} ${widget.symbol}',
            _hideBalance ? '' : '\$${(_lockedBalance * _price / widget.amount * widget.amount).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[900], height: 1),
          const SizedBox(height: 12),
          _buildBalanceRow(
            'Total',
            _hideBalance ? '****' : '${widget.amount.toStringAsFixed(widget.amount < 1 ? 6 : 4)} ${widget.symbol}',
            _hideBalance ? '' : '\$${widget.valueUsd.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, String amount, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey[500],
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: isTotal ? Colors.white : Colors.grey[300],
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    final isPositive = _priceChange >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Info',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Price',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_price.toStringAsFixed(_price < 1 ? 6 : 2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.tradingBuy : AppColors.tradingSell).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMarketInfoItem('24h High', '\$${(_price * 1.05).toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMarketInfoItem('24h Low', '\$${(_price * 0.95).toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMarketInfoItem('24h Vol', '${(widget.valueUsd * 1000).toStringAsFixed(0)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent ${widget.symbol} Transactions',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.transactionHistory),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[900], height: 1),
          _buildTransactionItem('Deposit', '+0.025 ${widget.symbol}', 'Today, 10:30 AM', true),
          Divider(color: Colors.grey[900], height: 1),
          _buildTransactionItem('Transfer Out', '-0.010 ${widget.symbol}', 'Yesterday, 2:15 PM', false),
          Divider(color: Colors.grey[900], height: 1),
          _buildTransactionItem('Buy', '+0.050 ${widget.symbol}', 'Dec 28, 9:00 AM', true),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String type, String amount, String time, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.tradingBuy : AppColors.tradingSell).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
