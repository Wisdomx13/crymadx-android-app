import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../services/staking_service.dart';

/// Stake Screen - Binance-style crypto staking with real API data
class StakeScreen extends StatefulWidget {
  const StakeScreen({super.key});

  @override
  State<StakeScreen> createState() => _StakeScreenState();
}

class _StakeScreenState extends State<StakeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  String _sortBy = 'APY';

  // API data
  List<StakingProduct> _stakingProducts = [];
  List<StakingPosition> _myPositions = [];
  bool _isLoading = true;
  bool _isPositionsLoading = true;
  String? _error;

  // Summary data
  double _totalStaked = 0;
  double _totalRewards = 0;
  double _avgApy = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProducts(),
      _loadPositions(),
    ]);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await stakingService.getProducts();
      if (mounted) {
        setState(() {
          _stakingProducts = products;
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

  Future<void> _loadPositions() async {
    setState(() => _isPositionsLoading = true);

    try {
      final positions = await stakingService.getPositions();
      final summary = await stakingService.getSummary();
      if (mounted) {
        setState(() {
          _myPositions = positions;
          _totalStaked = summary['totalStaked'] ?? 0;
          _totalRewards = summary['totalRewards'] ?? 0;
          _avgApy = summary['avgApy'] ?? 0;
          _isPositionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPositionsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StakingProduct> get _filteredProducts {
    var products = List<StakingProduct>.from(_stakingProducts);

    // Filter by tab
    if (_selectedTab == 1) {
      products = products.where((p) => p.isLiquid).toList();
    } else if (_selectedTab == 2) {
      products = products.where((p) => !p.isLiquid).toList();
    }

    // Sort
    if (_sortBy == 'APY') {
      products.sort((a, b) => b.apy.compareTo(a.apy));
    } else if (_sortBy == 'TVL') {
      products.sort((a, b) => b.availablePool.compareTo(a.availablePool));
    }

    return products;
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
        title: Text('Staking', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey[isDark ? 400 : 600]),
            onPressed: () => _showStakingHistory(),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[isDark ? 400 : 600]),
            onPressed: () => _showStakingInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(),

          // Tabs
          _buildTabs(),

          // Sort Options
          _buildSortBar(),

          // Products List
          Expanded(
            child: _selectedTab == 3
                ? _buildMyPositions()
                : _buildProductsList(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Staked Value', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_totalStaked.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success, size: 16),
                    const SizedBox(width: 4),
                    Text('+\$${_totalRewards.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Active Stakes',
                  value: '${_myPositions.length}',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.card_giftcard,
                  label: 'Total Rewards',
                  value: '\$${_totalRewards.toStringAsFixed(4)}',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.percent,
                  label: 'Avg APY',
                  value: '${_avgApy.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabButton(label: 'All', isActive: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
          const SizedBox(width: 8),
          _TabButton(label: 'Liquid', isActive: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
          const SizedBox(width: 8),
          _TabButton(label: 'Locked', isActive: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedTab == 3 ? AppColors.primary : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: _selectedTab == 3 ? Colors.black : Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Text('My Stakes', style: TextStyle(color: _selectedTab == 3 ? Colors.black : Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    if (_selectedTab == 3) return const SizedBox(height: 12);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('Sort by:', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(width: 8),
          _SortChip(label: 'APY', isActive: _sortBy == 'APY', onTap: () => setState(() => _sortBy = 'APY')),
          const SizedBox(width: 8),
          _SortChip(label: 'TVL', isActive: _sortBy == 'TVL', onTap: () => setState(() => _sortBy = 'TVL')),
          const Spacer(),
          Text('${_filteredProducts.length} assets', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _stakingProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text('Failed to load staking products', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text('No staking products available', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) => _StakeProductCard(
          product: _filteredProducts[index],
          onStake: () => _showStakeDialog(_filteredProducts[index]),
        ),
      ),
    );
  }

  Widget _buildMyPositions() {
    if (_myPositions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text('No active stakes', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Start staking to earn rewards', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _selectedTab = 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Explore Staking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPositions.length,
      itemBuilder: (context, index) => _MyPositionCard(
        position: _myPositions[index],
        onUnstake: () => _showUnstakeDialog(_myPositions[index]),
        onClaim: () => _claimRewards(_myPositions[index]),
      ),
    );
  }

  void _showStakeDialog(StakingProduct product) {
    final amountController = TextEditingController();
    bool isProcessing = false;
    int step = 1;
    double estimatedRewards = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CryptoIcon(symbol: product.token, size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stake ${product.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${product.apy}% APY', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                if (product.isLiquid) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Liquid', style: TextStyle(color: AppColors.info, fontSize: 10)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (step == 1) ...[
                    // Amount Input
                    Text('Amount to Stake', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: Colors.grey[700]),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) {
                                    final amount = double.tryParse(v) ?? 0;
                                    setModalState(() {
                                      estimatedRewards = amount * (product.apy / 100) / 365 * 30;
                                    });
                                  },
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(product.token, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text('Balance: 10.00', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QuickAmountButton(label: '25%', onTap: () => setModalState(() => amountController.text = '2.5')),
                              const SizedBox(width: 8),
                              _QuickAmountButton(label: '50%', onTap: () => setModalState(() => amountController.text = '5.0')),
                              const SizedBox(width: 8),
                              _QuickAmountButton(label: '75%', onTap: () => setModalState(() => amountController.text = '7.5')),
                              const SizedBox(width: 8),
                              _QuickAmountButton(label: 'MAX', onTap: () => setModalState(() => amountController.text = '10.0')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Staking Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(label: 'APY', value: '${product.apy}%', valueColor: AppColors.success),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Min. Stake', value: '${product.minDeposit} ${product.token}'),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Lock Period', value: product.lockPeriodDays == 0 ? 'None (Liquid)' : '${product.lockPeriodDays} days'),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Est. Monthly Rewards', value: '${estimatedRewards.toStringAsFixed(6)} ${product.token}', valueColor: AppColors.primary),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stake Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount >= product.minDeposit) {
                            setModalState(() => step = 2);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Minimum stake is ${product.minDeposit} ${product.token}'), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Continue', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else if (step == 2) ...[
                    // Confirmation
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock_outline, color: AppColors.primary, size: 48),
                          const SizedBox(height: 16),
                          const Text('Confirm Staking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          _ConfirmRow(label: 'Amount', value: '${amountController.text} ${product.token}'),
                          _ConfirmRow(label: 'APY', value: '${product.apy}%'),
                          _ConfirmRow(label: 'Lock Period', value: product.lockPeriodDays == 0 ? 'None' : '${product.lockPeriodDays} days'),
                          _ConfirmRow(label: 'Est. Monthly', value: '${estimatedRewards.toStringAsFixed(6)} ${product.token}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Warning
                    if (product.lockPeriodDays > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your funds will be locked for ${product.lockPeriodDays} days. Early unstaking may result in penalties.',
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Back', style: TextStyle(color: Colors.grey[400])),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () async {
                              setModalState(() => isProcessing = true);
                              await Future.delayed(const Duration(milliseconds: 300));
                              setModalState(() {
                                isProcessing = false;
                                step = 3;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isProcessing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Confirm Stake', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: AppColors.success, size: 48),
                          ),
                          const SizedBox(height: 24),
                          const Text('Staking Successful!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Text(
                            'You have successfully staked ${amountController.text} ${product.token}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start earning ${product.apy}% APY rewards',
                            style: TextStyle(color: AppColors.success, fontSize: 13),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _selectedTab = 3);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('View My Stakes', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Done', style: TextStyle(color: Colors.grey[400])),
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

  void _showUnstakeDialog(StakingPosition position) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            const Text('Unstake Funds?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'You are about to unstake ${position.amount} ${position.token}. You will stop earning rewards on this amount.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unstaked ${position.amount} ${position.token}'), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Unstake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _claimRewards(StakingPosition position) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed ${position.accruedInterest.toStringAsFixed(6)} ${position.token} rewards!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showStakingHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staking History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _HistoryItem(action: 'Staked', symbol: 'ETH', amount: 2.5, date: '2024-12-05'),
                  _HistoryItem(action: 'Claimed', symbol: 'ETH', amount: 0.0045, date: '2024-12-20'),
                  _HistoryItem(action: 'Staked', symbol: 'SOL', amount: 50, date: '2024-12-20'),
                  _HistoryItem(action: 'Claimed', symbol: 'SOL', amount: 0.074, date: '2025-01-03'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStakingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About Staking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _InfoItem(icon: Icons.lock, title: 'Secure', desc: 'Your funds are secured by blockchain validators'),
            _InfoItem(icon: Icons.card_giftcard, title: 'Earn Rewards', desc: 'Earn passive income by staking your crypto'),
            _InfoItem(icon: Icons.water_drop, title: 'Liquid Staking', desc: 'Unstake anytime with liquid staking options'),
            _InfoItem(icon: Icons.trending_up, title: 'Compound', desc: 'Rewards are automatically compounded'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}

// Helper Widgets
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey[800]!),
        ),
        child: Text(label, style: TextStyle(color: isActive ? AppColors.primary : Colors.grey[400], fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _StakeProductCard extends StatelessWidget {
  final StakingProduct product;
  final VoidCallback onStake;

  const _StakeProductCard({required this.product, required this.onStake});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CryptoIcon(symbol: product.token, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(product.token, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (product.isLiquid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Liquid', style: TextStyle(color: AppColors.info, fontSize: 9)),
                          ),
                      ],
                    ),
                    Text(product.name, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${product.apy}%', style: TextStyle(color: AppColors.success, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('APY', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: 'TVL', value: '\$${(product.availablePool / 1000000).toStringAsFixed(1)}M'),
              _StatItem(label: 'Validators', value: '${product.validators}'),
              _StatItem(label: 'Min Stake', value: '${product.minDeposit}'),
              _StatItem(label: 'Lock', value: product.lockPeriodDays == 0 ? 'None' : '${product.lockPeriodDays}d'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStake,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Stake Now', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }
}

class _MyPositionCard extends StatelessWidget {
  final StakingPosition position;
  final VoidCallback onUnstake;
  final VoidCallback onClaim;

  const _MyPositionCard({required this.position, required this.onUnstake, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(position.depositedAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CryptoIcon(symbol: position.token, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(position.token, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('Staked $days days ago', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${position.apy}% APY', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Staked Amount', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${position.amount} ${position.token}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rewards Earned', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('+${position.accruedInterest.toStringAsFixed(6)} ${position.token}', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUnstake,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Unstake', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Claim Rewards', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String action;
  final String symbol;
  final double amount;
  final String date;

  const _HistoryItem({required this.action, required this.symbol, required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    final isStake = action == 'Staked';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isStake ? AppColors.primary : AppColors.success).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isStake ? Icons.arrow_downward : Icons.card_giftcard, color: isStake ? AppColors.primary : AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Text('$amount $symbol', style: TextStyle(color: isStake ? Colors.white : AppColors.success, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
