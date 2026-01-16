import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';

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

  @override
  void initState() {
    super.initState();
    // Set initial coin if provided, otherwise default to USDT
    _selectedCoin = widget.initialSymbol ?? 'USDT';
  }

  final Map<String, double> _fundingBalances = {
    'USDT': 800.00,
    'BTC': 0.1500,
    'ETH': 1.5,
    'SOL': 10.0,
  };

  final Map<String, double> _tradingBalances = {
    'USDT': 450.00,
    'BTC': 0.0879,
    'ETH': 1.0,
    'SOL': 5.5,
  };

  double get _availableBalance {
    final balances = _fromAccount == 'Funding' ? _fundingBalances : _tradingBalances;
    return balances[_selectedCoin] ?? 0.0;
  }

  void _swapAccounts() {
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
    });
  }

  void _setMaxAmount() {
    _amountController.text = _availableBalance.toStringAsFixed(_selectedCoin == 'USDT' ? 2 : 4);
  }

  void _handleTransfer() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter an amount'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Insufficient balance'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Show success
    showDialog(
      context: context,
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
  }

  void _showCoinSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Coin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...['USDT', 'BTC', 'ETH', 'SOL'].map((coin) {
              final balance = _fromAccount == 'Funding' ? _fundingBalances[coin] : _tradingBalances[coin];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CryptoIcon(symbol: coin, size: 36),
                title: Text(coin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                trailing: Text('${balance?.toStringAsFixed(coin == 'USDT' ? 2 : 4)} $coin', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                onTap: () {
                  setState(() => _selectedCoin = coin);
                  Navigator.pop(context);
                },
              );
            }),
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
              onTap: _showCoinSelector,
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
                          Text('Available: ${_availableBalance.toStringAsFixed(_selectedCoin == 'USDT' ? 2 : 4)}', style: TextStyle(color: subtextColor, fontSize: 12)),
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
                        onTap: _setMaxAmount,
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

            const Spacer(),

            // Transfer Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Transfer', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(String label, String account, bool isFrom, bool isDark, Color cardColor, Color textColor, Color? subtextColor, Color borderColor) {
    final IconData icon = account == 'Funding' ? Icons.account_balance_wallet_outlined : Icons.candlestick_chart_outlined;

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
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 14),
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
