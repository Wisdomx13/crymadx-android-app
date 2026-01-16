import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/crypto_icon.dart';

// Transaction types
enum TransactionType { deposit, withdraw, trade, transfer, earn, p2p }

// Transaction status
enum TransactionStatus { completed, pending, failed, cancelled }

// Transaction model
class Transaction {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final String asset;
  final double amount;
  final double? usdValue;
  final DateTime timestamp;
  final String? description;
  final String? txHash;

  const Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.asset,
    required this.amount,
    this.usdValue,
    required this.timestamp,
    this.description,
    this.txHash,
  });
}

// Mock transaction data
final List<Transaction> mockTransactions = [
  Transaction(
    id: 'TXN001',
    type: TransactionType.deposit,
    status: TransactionStatus.completed,
    asset: 'USDT',
    amount: 500.00,
    usdValue: 500.00,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    description: 'Deposit via TRC20',
    txHash: '0x1a2b3c4d5e6f7890...',
  ),
  Transaction(
    id: 'TXN002',
    type: TransactionType.trade,
    status: TransactionStatus.completed,
    asset: 'BTC',
    amount: 0.012,
    usdValue: 518.40,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    description: 'Buy BTC/USDT',
  ),
  Transaction(
    id: 'TXN003',
    type: TransactionType.withdraw,
    status: TransactionStatus.pending,
    asset: 'ETH',
    amount: 0.5,
    usdValue: 1140.00,
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    description: 'Withdraw to external wallet',
    txHash: '0xabc123def456...',
  ),
  Transaction(
    id: 'TXN004',
    type: TransactionType.earn,
    status: TransactionStatus.completed,
    asset: 'USDT',
    amount: 12.50,
    usdValue: 12.50,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    description: 'Staking rewards',
  ),
  Transaction(
    id: 'TXN005',
    type: TransactionType.p2p,
    status: TransactionStatus.completed,
    asset: 'USDT',
    amount: 200.00,
    usdValue: 200.00,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    description: 'P2P Buy from User123',
  ),
  Transaction(
    id: 'TXN006',
    type: TransactionType.transfer,
    status: TransactionStatus.completed,
    asset: 'BNB',
    amount: 2.5,
    usdValue: 781.25,
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    description: 'Transfer to Spot Wallet',
  ),
  Transaction(
    id: 'TXN007',
    type: TransactionType.trade,
    status: TransactionStatus.failed,
    asset: 'SOL',
    amount: 10.0,
    usdValue: 985.00,
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    description: 'Sell SOL/USDT - Insufficient balance',
  ),
  Transaction(
    id: 'TXN008',
    type: TransactionType.deposit,
    status: TransactionStatus.completed,
    asset: 'BTC',
    amount: 0.05,
    usdValue: 2160.00,
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    description: 'Deposit via Bitcoin Network',
    txHash: '0x9f8e7d6c5b4a...',
  ),
  Transaction(
    id: 'TXN009',
    type: TransactionType.withdraw,
    status: TransactionStatus.cancelled,
    asset: 'USDT',
    amount: 1000.00,
    usdValue: 1000.00,
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    description: 'Withdraw cancelled by user',
  ),
  Transaction(
    id: 'TXN010',
    type: TransactionType.earn,
    status: TransactionStatus.completed,
    asset: 'ETH',
    amount: 0.008,
    usdValue: 18.24,
    timestamp: DateTime.now().subtract(const Duration(days: 8)),
    description: 'ETH Staking rewards',
  ),
];

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Deposit', 'Withdraw', 'Trade', 'Earn', 'P2P'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedFilter == 'All') return mockTransactions;

    TransactionType? filterType;
    switch (_selectedFilter) {
      case 'Deposit':
        filterType = TransactionType.deposit;
        break;
      case 'Withdraw':
        filterType = TransactionType.withdraw;
        break;
      case 'Trade':
        filterType = TransactionType.trade;
        break;
      case 'Earn':
        filterType = TransactionType.earn;
        break;
      case 'P2P':
        filterType = TransactionType.p2p;
        break;
    }

    if (filterType == null) return mockTransactions;
    return mockTransactions.where((t) => t.type == filterType).toList();
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

          // Summary card
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Deposits', '\$5,160', AppColors.tradingBuy),
                  Container(width: 1, height: 40, color: AppColors.glassBorder),
                  _buildSummaryItem('Total Withdrawals', '\$2,140', AppColors.tradingSell),
                  Container(width: 1, height: 40, color: AppColors.glassBorder),
                  _buildSummaryItem('Net Flow', '+\$3,020', AppColors.info),
                ],
              ),
            ),
          ),

          // Transaction list
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      return _buildTransactionItem(tx);
                    },
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

    switch (tx.type) {
      case TransactionType.deposit:
        icon = Icons.arrow_downward;
        iconColor = AppColors.tradingBuy;
        typeLabel = 'Deposit';
        isIncoming = true;
        break;
      case TransactionType.withdraw:
        icon = Icons.arrow_upward;
        iconColor = AppColors.tradingSell;
        typeLabel = 'Withdraw';
        isIncoming = false;
        break;
      case TransactionType.trade:
        icon = Icons.swap_horiz;
        iconColor = AppColors.info;
        typeLabel = 'Trade';
        isIncoming = tx.amount > 0;
        break;
      case TransactionType.transfer:
        icon = Icons.send;
        iconColor = AppColors.warning;
        typeLabel = 'Transfer';
        isIncoming = false;
        break;
      case TransactionType.earn:
        icon = Icons.savings;
        iconColor = AppColors.tradingBuy;
        typeLabel = 'Earn';
        isIncoming = true;
        break;
      case TransactionType.p2p:
        icon = Icons.people;
        iconColor = AppColors.primary;
        typeLabel = 'P2P';
        isIncoming = tx.amount > 0;
        break;
    }

    Color statusColor;
    switch (tx.status) {
      case TransactionStatus.completed:
        statusColor = AppColors.tradingBuy;
        break;
      case TransactionStatus.pending:
        statusColor = AppColors.warning;
        break;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        statusColor = AppColors.tradingSell;
        break;
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
                          tx.status.name.toUpperCase(),
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
                    tx.description ?? '',
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
                    CryptoIcon(symbol: tx.asset, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${isIncoming ? '+' : '-'}${tx.amount} ${tx.asset}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isIncoming ? AppColors.tradingBuy : AppColors.tradingSell,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (tx.usdValue != null)
                  Text(
                    '\$${tx.usdValue!.toStringAsFixed(2)}',
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
                CryptoIcon(symbol: tx.asset, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.amount} ${tx.asset}',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tx.usdValue != null)
                      Text(
                        '\$${tx.usdValue!.toStringAsFixed(2)} USD',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(color: AppColors.glassBorder),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Type', tx.type.name.toUpperCase()),
            _buildDetailRow('Status', tx.status.name.toUpperCase()),
            _buildDetailRow('Transaction ID', tx.id),
            _buildDetailRow('Date', _formatDate(tx.timestamp)),
            if (tx.txHash != null)
              _buildDetailRow('TX Hash', tx.txHash!, isCopyable: true),
            if (tx.description != null)
              _buildDetailRow('Description', tx.description!),
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
