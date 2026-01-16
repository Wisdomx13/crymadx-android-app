import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../services/crypto_service.dart';

/// Convert Screen - Bybit-style crypto conversion
class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final CryptoService _cryptoService = CryptoService();
  final TextEditingController _fromAmountController = TextEditingController();

  String _fromCrypto = 'USDT';
  String _toCrypto = 'BTC';
  double _fromPrice = 1.0;
  double _toPrice = 91000.0;
  double _toAmount = 0.0;
  bool _isLoading = false;

  // Conversion history for demo
  final List<Map<String, dynamic>> _conversionHistory = [
    {'from': '100 USDT', 'to': '0.00109 BTC', 'date': 'Jan 5, 2026 10:30', 'status': 'Completed'},
    {'from': '500 USDT', 'to': '0.217 ETH', 'date': 'Jan 4, 2026 15:45', 'status': 'Completed'},
    {'from': '0.05 BTC', 'to': '4,565 USDT', 'date': 'Jan 3, 2026 09:20', 'status': 'Completed'},
    {'from': '2 SOL', 'to': '196.50 USDT', 'date': 'Jan 2, 2026 18:10', 'status': 'Completed'},
  ];

  final List<Map<String, dynamic>> _cryptoOptions = [
    {'symbol': 'BTC', 'name': 'Bitcoin'},
    {'symbol': 'ETH', 'name': 'Ethereum'},
    {'symbol': 'USDT', 'name': 'Tether'},
    {'symbol': 'USDC', 'name': 'USD Coin'},
    {'symbol': 'BNB', 'name': 'BNB'},
    {'symbol': 'SOL', 'name': 'Solana'},
    {'symbol': 'XRP', 'name': 'Ripple'},
    {'symbol': 'ADA', 'name': 'Cardano'},
    {'symbol': 'DOGE', 'name': 'Dogecoin'},
    {'symbol': 'DOT', 'name': 'Polkadot'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    if (_fromCrypto != 'USDT') {
      final fromPrice = await _cryptoService.getPrice(_fromCrypto);
      if (fromPrice != null) setState(() => _fromPrice = fromPrice);
    }
    if (_toCrypto != 'USDT') {
      final toPrice = await _cryptoService.getPrice(_toCrypto);
      if (toPrice != null) setState(() => _toPrice = toPrice);
    }
    _calculateToAmount();
  }

  void _calculateToAmount() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    final fromValueUsd = fromAmount * _fromPrice;
    final toAmountCalc = _toPrice > 0 ? fromValueUsd / _toPrice : 0.0;
    setState(() => _toAmount = toAmountCalc);
  }

  void _swapCurrencies() {
    setState(() {
      final tempCrypto = _fromCrypto;
      final tempPrice = _fromPrice;
      _fromCrypto = _toCrypto;
      _fromPrice = _toPrice;
      _toCrypto = tempCrypto;
      _toPrice = tempPrice;
    });
    _calculateToAmount();
  }

  Future<void> _handleConvert() async {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    if (fromAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter an amount'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate conversion
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Conversion Successful', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You converted $fromAmount $_fromCrypto to ${_toAmount.toStringAsFixed(8)} $_toCrypto',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      _fromAmountController.clear();
      setState(() => _toAmount = 0);
    }
  }

  void _showQuoteConfirmation() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    if (fromAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rate = _fromPrice / _toPrice;
    final estimatedAmount = fromAmount * rate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Text(
              'Confirm Conversion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // From Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CryptoIcon(symbol: _fromCrypto, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '$fromAmount $_fromCrypto',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Arrow
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_downward, color: AppColors.tradingBuy, size: 20),
              ),
            ),

            const SizedBox(height: 8),

            // To Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CryptoIcon(symbol: _toCrypto, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To (estimated)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${estimatedAmount.toStringAsFixed(8)} $_toCrypto',
                          style: TextStyle(color: AppColors.tradingBuy, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildQuoteDetailRow('Exchange Rate', '1 $_fromCrypto = ${rate.toStringAsFixed(8)} $_toCrypto'),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[850], height: 1),
                  const SizedBox(height: 12),
                  _buildQuoteDetailRow('Fee', '0 USDT'),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[850], height: 1),
                  const SizedBox(height: 12),
                  _buildQuoteDetailRow('Slippage Tolerance', '0.5%'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Timer notice
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.grey[500], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Quote valid for 10 seconds',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _executeConversion(fromAmount, estimatedAmount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tradingBuy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  void _executeConversion(double fromAmount, double toAmount) async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tradingBuy.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: AppColors.tradingBuy, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Conversion Successful!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You converted $fromAmount $_fromCrypto to ${toAmount.toStringAsFixed(8)} $_toCrypto',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fromAmountController.clear();
                    setState(() => _toAmount = 0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tradingBuy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showConversionHistory() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Conversion History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_conversionHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: Colors.grey[700], size: 48),
                      const SizedBox(height: 12),
                      Text('No conversions yet', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              ..._conversionHistory.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sync_alt, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['from']} → ${item['to']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(item['date'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item['status'], style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
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
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.sync_alt, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Convert', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: isDark ? Colors.grey[400] : const Color(0xFF555555)),
            onPressed: _showConversionHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs: Instant / Limit
              _buildTabs(),

              const SizedBox(height: 24),

              // From Section
              _buildFromSection(isDark, cardColor, textColor, subtextColor, borderColor),

              const SizedBox(height: 8),

              // Swap Button - Green
              Center(
                child: GestureDetector(
                  onTap: _swapCurrencies,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tradingBuy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert, color: Colors.white, size: 22),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // To Section
              _buildToSection(isDark, cardColor, textColor, subtextColor, borderColor),

              const SizedBox(height: 24),

              // Quote Button - Green color (matching Trade section)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showQuoteConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tradingBuy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Quote', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 24),

              // Info Section
              _buildInfoSection(isDark, cardColor, textColor, subtextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        // Only Instant conversion - no Limit option - Green color
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tradingBuy.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.tradingBuy, size: 16),
              const SizedBox(width: 6),
              Text('Instant', style: TextStyle(color: AppColors.tradingBuy, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.bar_chart, color: Colors.grey[600], size: 20),
        const SizedBox(width: 16),
        Icon(Icons.help_outline, color: Colors.grey[600], size: 20),
        const SizedBox(width: 16),
        Icon(Icons.list_alt, color: Colors.grey[600], size: 20),
      ],
    );
  }

  Widget _buildFromSection(bool isDark, Color cardColor, Color textColor, Color? subtextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('From', style: TextStyle(color: subtextColor, fontSize: 12)),
              Row(
                children: [
                  Text('Available: ', style: TextStyle(color: subtextColor, fontSize: 12)),
                  Text('0', style: TextStyle(color: subtextColor, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: subtextColor, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showCryptoSelector(true),
                child: Row(
                  children: [
                    CryptoIcon(symbol: _fromCrypto, size: 28),
                    const SizedBox(width: 8),
                    Text(_fromCrypto, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: subtextColor, size: 20),
                  ],
                ),
              ),
              const Spacer(),
              Expanded(
                child: TextField(
                  controller: _fromAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: textColor, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 16),
                    border: InputBorder.none,
                    suffixText: 'Max',
                    suffixStyle: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                  onChanged: (_) => _calculateToAmount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToSection(bool isDark, Color cardColor, Color textColor, Color? subtextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To', style: TextStyle(color: subtextColor, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showCryptoSelector(false),
                child: Row(
                  children: [
                    CryptoIcon(symbol: _toCrypto, size: 28),
                    const SizedBox(width: 8),
                    Text(_toCrypto, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: subtextColor, size: 20),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _toAmount > 0 ? _toAmount.toStringAsFixed(8) : '--',
                style: TextStyle(color: subtextColor, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, Color cardColor, Color textColor, Color? subtextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('Rate', '1 $_fromCrypto = ${(_fromPrice / _toPrice).toStringAsFixed(8)} $_toCrypto', textColor, subtextColor),
          const SizedBox(height: 8),
          _buildInfoRow('Fee', '0 USDT', textColor, subtextColor),
          const SizedBox(height: 8),
          _buildInfoRow('Slippage', '0.5%', textColor, subtextColor),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color? subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 13)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13)),
      ],
    );
  }

  void _showCryptoSelector(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select ${isFrom ? 'From' : 'To'} Currency', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...(_cryptoOptions.map((crypto) => ListTile(
              leading: CryptoIcon(symbol: crypto['symbol'], size: 32),
              title: Text(crypto['symbol'], style: const TextStyle(color: Colors.white)),
              subtitle: Text(crypto['name'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  if (isFrom) {
                    _fromCrypto = crypto['symbol'];
                  } else {
                    _toCrypto = crypto['symbol'];
                  }
                });
                _loadPrices();
              },
            ))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    super.dispose();
  }
}
