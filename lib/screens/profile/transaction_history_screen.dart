import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/crypto_icon.dart';
import '../../services/wallet_service.dart';

// Use the Transaction model from wallet_service.dart

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Deposit', 'Withdraw', 'Transfer'];

  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  // Summary stats
  double _totalDeposits = 0;
  double _totalWithdrawals = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await walletService.getTransfers(limit: 50);

      // Calculate summaries
      double deposits = 0;
      double withdrawals = 0;

      for (var tx in transactions) {
        if (tx.type.toLowerCase() == 'deposit' && tx.isCompleted) {
          deposits += tx.amount;
        } else if (tx.type.toLowerCase() == 'withdraw' && tx.isCompleted) {
          withdrawals += tx.amount;
        }
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalDeposits = deposits;
          _totalWithdrawals = withdrawals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;

    final filterType = _selectedFilter.toLowerCase();
    return _transactions.where((t) => t.type.toLowerCase() == filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Transaction History',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => _showSearchModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Summary card - real data
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Deposits', '\$${_totalDeposits.toStringAsFixed(2)}', AppColors.tradingBuy),
                  Container(width: 1, height: 40, color: AppColors.glassBorder),
                  _buildSummaryItem('Total Withdrawals', '\$${_totalWithdrawals.toStringAsFixed(2)}', AppColors.tradingSell),
                  Container(width: 1, height: 40, color: AppColors.glassBorder),
                  _buildSummaryItem('Net Flow', '${_totalDeposits - _totalWithdrawals >= 0 ? '+' : ''}\$${(_totalDeposits - _totalWithdrawals).toStringAsFixed(2)}', AppColors.info),
                ],
              ),
            ),
          ),

          // Transaction list - real data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index];
                                return _buildTransactionItem(tx);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    IconData icon;
    Color iconColor;
    String typeLabel;
    bool isIncoming;

    final txType = tx.type.toLowerCase();
    switch (txType) {
      case 'deposit':
        icon = Icons.arrow_downward;
        iconColor = AppColors.tradingBuy;
        typeLabel = 'Deposit';
        isIncoming = true;
        break;
      case 'withdraw':
      case 'withdrawal':
        icon = Icons.arrow_upward;
        iconColor = AppColors.tradingSell;
        typeLabel = 'Withdraw';
        isIncoming = false;
        break;
      case 'transfer':
      case 'internal':
        icon = Icons.swap_horiz;
        iconColor = AppColors.warning;
        typeLabel = 'Transfer';
        isIncoming = false;
        break;
      default:
        icon = Icons.receipt;
        iconColor = AppColors.info;
        typeLabel = tx.type.substring(0, 1).toUpperCase() + tx.type.substring(1);
        isIncoming = tx.amount > 0;
    }

    Color statusColor;
    switch (tx.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.tradingBuy;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = AppColors.tradingSell;
        break;
      default:
        statusColor = AppColors.textMuted;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetails(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.network != null ? 'via ${tx.network}' : _formatDate(tx.createdAt),
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CryptoIcon(symbol: tx.currency, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${isIncoming ? '+' : '-'}${tx.amount} ${tx.currency}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isIncoming ? AppColors.tradingBuy : AppColors.tradingSell,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(tx.createdAt),
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.tradingSell, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to load transactions',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTransactions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Asset and amount
            Row(
              children: [
                CryptoIcon(symbol: tx.currency, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.amount} ${tx.currency}',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tx.fee != null)
                      Text(
                        'Fee: ${tx.fee} ${tx.currency}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(color: AppColors.glassBorder),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Type', tx.type.toUpperCase()),
            _buildDetailRow('Status', tx.status.toUpperCase()),
            _buildDetailRow('Transaction ID', tx.id),
            _buildDetailRow('Date', _formatDate(tx.createdAt)),
            if (tx.network != null)
              _buildDetailRow('Network', tx.network!),
            if (tx.txHash != null)
              _buildDetailRow('TX Hash', tx.txHash!, isCopyable: true),
            if (tx.toAddress != null)
              _buildDetailRow('To Address', tx.toAddress!, isCopyable: true),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          Row(
            children: [
              Text(
                value.length > 20 ? '${value.substring(0, 18)}...' : value,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                Icon(Icons.copy, color: AppColors.primary, size: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Transactions',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by asset, ID, or description...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                // Implement search
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Quick filters
            Wrap(
              spacing: 8,
              children: ['BTC', 'ETH', 'USDT', 'Last 7 days', 'Last 30 days'].map((filter) {
                return ActionChip(
                  label: Text(filter),
                  labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  backgroundColor: AppColors.backgroundCard,
                  onPressed: () {},
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
