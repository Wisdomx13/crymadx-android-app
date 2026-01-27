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

  // Search state
  String _searchQuery = '';
  String? _searchAssetFilter;
  DateTime? _searchDateFrom;

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
    List<Transaction> result = _transactions;

    // Apply type filter
    if (_selectedFilter != 'All') {
      final filterType = _selectedFilter.toLowerCase();
      result = result.where((t) => t.type.toLowerCase() == filterType).toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) =>
        t.currency.toLowerCase().contains(query) ||
        t.id.toLowerCase().contains(query) ||
        t.type.toLowerCase().contains(query) ||
        (t.txHash?.toLowerCase().contains(query) ?? false) ||
        (t.toAddress?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Apply asset filter
    if (_searchAssetFilter != null) {
      result = result.where((t) => t.currency.toUpperCase() == _searchAssetFilter).toList();
    }

    // Apply date filter
    if (_searchDateFrom != null) {
      result = result.where((t) => t.createdAt.isAfter(_searchDateFrom!)).toList();
    }

    return result;
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _applyAssetFilter(String? asset) {
    setState(() {
      _searchAssetFilter = asset;
    });
  }

  void _applyDateFilter(int? days) {
    setState(() {
      if (days != null) {
        _searchDateFrom = DateTime.now().subtract(Duration(days: days));
      } else {
        _searchDateFrom = null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchAssetFilter = null;
      _searchDateFrom = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundPrimary : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final cardColor = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.glassBorder : Colors.grey[300]!;
    final subtextColor = isDark ? AppColors.textSecondary : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Transaction History',
          style: AppTypography.headlineSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor),
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
                          : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.black : subtextColor,
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Deposits', '\$${_totalDeposits.toStringAsFixed(2)}', AppColors.tradingBuy, isDark),
                  Container(width: 1, height: 40, color: borderColor),
                  _buildSummaryItem('Total Withdrawals', '\$${_totalWithdrawals.toStringAsFixed(2)}', AppColors.tradingSell, isDark),
                  Container(width: 1, height: 40, color: borderColor),
                  _buildSummaryItem('Net Flow', '${_totalDeposits - _totalWithdrawals >= 0 ? '+' : ''}\$${(_totalDeposits - _totalWithdrawals).toStringAsFixed(2)}', AppColors.info, isDark),
                ],
              ),
            ),
          ),

          // Transaction list - real data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState(isDark)
                    : _filteredTransactions.isEmpty
                        ? _buildEmptyState(isDark)
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index];
                                return _buildTransactionItem(tx, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;
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
          style: AppTypography.caption.copyWith(color: subtextColor),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx, bool isDark) {
    final cardColor = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.glassBorder : Colors.grey[300]!;
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;

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
        statusColor = subtextColor;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetails(tx, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
                          color: textColor,
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
                    style: AppTypography.caption.copyWith(color: subtextColor),
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
                  style: AppTypography.caption.copyWith(color: subtextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: subtextColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTypography.titleMedium.copyWith(color: subtextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.tradingSell, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to load transactions',
            style: AppTypography.titleMedium.copyWith(color: subtextColor),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
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

  void _showTransactionDetails(Transaction tx, bool isDark) {
    final modalBgColor = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;
    final borderColor = isDark ? AppColors.glassBorder : Colors.grey[300]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBgColor,
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
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: textColor),
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
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tx.fee != null)
                      Text(
                        'Fee: ${tx.fee} ${tx.currency}',
                        style: AppTypography.bodySmall.copyWith(color: subtextColor),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(color: borderColor),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Type', tx.type.toUpperCase(), isDark),
            _buildDetailRow('Status', tx.status.toUpperCase(), isDark),
            _buildDetailRow('Transaction ID', tx.id, isDark),
            _buildDetailRow('Date', _formatDate(tx.createdAt), isDark),
            if (tx.network != null)
              _buildDetailRow('Network', tx.network!, isDark),
            if (tx.txHash != null)
              _buildDetailRow('TX Hash', tx.txHash!, isDark, isCopyable: true),
            if (tx.toAddress != null)
              _buildDetailRow('To Address', tx.toAddress!, isDark, isCopyable: true),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isCopyable = false}) {
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
          ),
          Row(
            children: [
              Text(
                value.length > 20 ? '${value.substring(0, 18)}...' : value,
                style: AppTypography.bodySmall.copyWith(
                  color: textColor,
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
    final searchController = TextEditingController(text: _searchQuery);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBgColor = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final subtextColor = isDark ? AppColors.textMuted : Colors.grey[700]!;
    final cardColor = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search by asset, ID, or description...',
                  hintStyle: TextStyle(color: subtextColor),
                  prefixIcon: Icon(Icons.search, color: subtextColor),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: subtextColor, size: 20),
                          onPressed: () {
                            searchController.clear();
                            setModalState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setModalState(() {}),
                onSubmitted: (value) {
                  _applySearch(value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Quick filters - Assets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickFilterChip('BTC', _searchAssetFilter == 'BTC', () {
                    _applyAssetFilter(_searchAssetFilter == 'BTC' ? null : 'BTC');
                    Navigator.pop(context);
                  }, isDark),
                  _buildQuickFilterChip('ETH', _searchAssetFilter == 'ETH', () {
                    _applyAssetFilter(_searchAssetFilter == 'ETH' ? null : 'ETH');
                    Navigator.pop(context);
                  }, isDark),
                  _buildQuickFilterChip('USDT', _searchAssetFilter == 'USDT', () {
                    _applyAssetFilter(_searchAssetFilter == 'USDT' ? null : 'USDT');
                    Navigator.pop(context);
                  }, isDark),
                  _buildQuickFilterChip('Last 7 days', _searchDateFrom != null && DateTime.now().difference(_searchDateFrom!).inDays <= 7, () {
                    _applyDateFilter(_searchDateFrom != null && DateTime.now().difference(_searchDateFrom!).inDays <= 7 ? null : 7);
                    Navigator.pop(context);
                  }, isDark),
                  _buildQuickFilterChip('Last 30 days', _searchDateFrom != null && DateTime.now().difference(_searchDateFrom!).inDays <= 30, () {
                    _applyDateFilter(_searchDateFrom != null && DateTime.now().difference(_searchDateFrom!).inDays <= 30 ? null : 30);
                    Navigator.pop(context);
                  }, isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Clear filters button
              if (_searchQuery.isNotEmpty || _searchAssetFilter != null || _searchDateFrom != null)
                TextButton.icon(
                  onPressed: () {
                    _clearFilters();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.clear_all, color: AppColors.tradingSell, size: 18),
                  label: Text('Clear all filters', style: TextStyle(color: AppColors.tradingSell)),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    final cardColor = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.glassBorder : Colors.grey[300]!;
    final subtextColor = isDark ? AppColors.textSecondary : Colors.grey[700]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : subtextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
