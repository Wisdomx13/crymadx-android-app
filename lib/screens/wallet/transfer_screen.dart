import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../providers/balance_provider.dart';
import '../../services/wallet_service.dart';

/// Transfer Screen - Full subpage for transferring between accounts
class TransferScreen extends StatefulWidget {
  final String? initialSymbol;
  final String? initialName;

  const TransferScreen({
    super.key,
    this.initialSymbol,
    this.initialName,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String _fromAccount = 'Funding';
  String _toAccount = 'Trading';
  late String _selectedCoin;
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _selectedCoin = widget.initialSymbol ?? 'USDT';
    // Load balances
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceProvider>().loadBalances();
    });
  }

  double _getAvailableBalance(BalanceProvider balanceProvider) {
    // Get assets from the appropriate account
    final assets = _fromAccount == 'Funding'
        ? balanceProvider.fundingAssets
        : balanceProvider.tradingAssets;

    // Find the selected coin's balance
    final asset = assets.where((a) => a.symbol == _selectedCoin).toList();
    if (asset.isNotEmpty) {
      return asset.first.available > 0 ? asset.first.available : asset.first.amount;
    }
    return 0.0;
  }

  List<String> _getAvailableCoins(BalanceProvider balanceProvider) {
    // Only show coins that the user actually has in the selected "from" account
    final Set<String> coins = {};
    final assets = _fromAccount == 'Funding'
        ? balanceProvider.fundingAssets
        : balanceProvider.tradingAssets;

    for (final asset in assets) {
      // Only add coins with balance > 0
      final balance = asset.available > 0 ? asset.available : asset.amount;
      if (balance > 0) {
        coins.add(asset.symbol);
      }
    }

    return coins.toList()..sort();
  }

  double _getCoinBalance(BalanceProvider balanceProvider, String coin, String account) {
    final assets = account == 'Funding'
        ? balanceProvider.fundingAssets
        : balanceProvider.tradingAssets;

    final asset = assets.where((a) => a.symbol == coin).toList();
    if (asset.isNotEmpty) {
      return asset.first.available > 0 ? asset.first.available : asset.first.amount;
    }
    return 0.0;
  }

  void _swapAccounts() {
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
    });
  }

  void _setMaxAmount(BalanceProvider balanceProvider) {
    final balance = _getAvailableBalance(balanceProvider);
    _amountController.text = balance.toStringAsFixed(_selectedCoin == 'USDT' ? 2 : 6);
  }

  Future<void> _handleTransfer(BalanceProvider balanceProvider) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final availableBalance = _getAvailableBalance(balanceProvider);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter an amount'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (amount > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Available: ${availableBalance.toStringAsFixed(_selectedCoin == 'USDT' ? 2 : 6)} $_selectedCoin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isTransferring = true);

    try {
      // Call the actual API to transfer
      await walletService.transfer(TransferRequest(
        fromWallet: _fromAccount.toLowerCase(),
        toWallet: _toAccount.toLowerCase(),
        currency: _selectedCoin,
        amount: amount,
      ));

      // Refresh balances after successful transfer
      await balanceProvider.loadBalances();

      if (!mounted) return;

      setState(() => _isTransferring = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Transfer Successful', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '${_amountController.text} $_selectedCoin transferred from $_fromAccount to $_toAccount',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

      // Clear the amount
      _amountController.clear();
    } catch (e) {
      setState(() => _isTransferring = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfer failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCoinSelector(BalanceProvider balanceProvider) {
    final coins = _getAvailableCoins(balanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Coin', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...coins.map((coin) {
              final balance = _getCoinBalance(balanceProvider, coin, _fromAccount);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CryptoIcon(symbol: coin, size: 36),
                title: Text(coin, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                trailing: Text(
                  '${balance.toStringAsFixed(coin == 'USDT' ? 2 : 6)} $coin',
                  style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12),
                ),
                onTap: () {
                  setState(() => _selectedCoin = coin);
                  Navigator.pop(context);
                },
              );
            }),
            if (coins.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text('No assets available', style: TextStyle(color: Colors.grey[500])),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[300]!;
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);

    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, _) {
        final availableBalance = _getAvailableBalance(balanceProvider);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => context.pop(),
            ),
            title: Text('Transfer', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From / To Account Cards
                Row(
                  children: [
                    Expanded(child: _buildAccountCard('From', _fromAccount, true, isDark, cardColor, textColor, subtextColor, borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: _swapAccounts,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                    Expanded(child: _buildAccountCard('To', _toAccount, false, isDark, cardColor, textColor, subtextColor, borderColor)),
                  ],
                ),

                const SizedBox(height: 24),

                // Coin Selector
                GestureDetector(
                  onTap: () => _showCoinSelector(balanceProvider),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        CryptoIcon(symbol: _selectedCoin, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedCoin, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(
                                'Available: ${availableBalance.toStringAsFixed(_selectedCoin == 'USDT' ? 2 : 6)}',
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: subtextColor),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount', style: TextStyle(color: subtextColor, fontSize: 12)),
                          GestureDetector(
                            onTap: () => _setMaxAmount(balanceProvider),
                            child: Text('Max', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Info text
                const SizedBox(height: 12),
                Text(
                  _fromAccount == 'Funding'
                      ? 'Transfer to Trading account to start trading'
                      : 'Transfer to Funding account for withdrawals',
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),

                const Spacer(),

                // Transfer Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isTransferring ? null : () => _handleTransfer(balanceProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isTransferring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Transfer', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountCard(String label, String account, bool isFrom, bool isDark, Color cardColor, Color textColor, Color? subtextColor, Color borderColor) {
    final IconData icon = account == 'Funding' ? Icons.account_balance_wallet_outlined : Icons.candlestick_chart_outlined;
    final Color accentColor = account == 'Funding' ? AppColors.primary : AppColors.tradingBuy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: subtextColor, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const SizedBox(width: 8),
              Text(account, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
