import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/fiat_service.dart';
import '../../services/crypto_service.dart';

/// Fiat On-Ramp Screen with dynamic API data
class FiatScreen extends StatefulWidget {
  const FiatScreen({super.key});

  @override
  State<FiatScreen> createState() => _FiatScreenState();
}

class _FiatScreenState extends State<FiatScreen> {
  int _selectedTab = 0; // 0 = Buy, 1 = Sell
  String _selectedCrypto = 'BTC';
  String _selectedFiat = 'USD';
  String _amount = '100';
  int _selectedProvider = 0;
  bool _isLoading = true;

  // Dynamic provider data from API
  List<FiatProvider> _providers = [];

  // Crypto prices from API
  Map<String, double> _cryptoPrices = {
    'BTC': 88500.0,
    'ETH': 3150.0,
    'USDT': 1.0,
    'BNB': 620.0,
    'SOL': 195.0,
  };

  // Supported currencies
  List<String> _fiats = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];
  List<Map<String, dynamic>> _cryptos = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 88500.0},
    {'symbol': 'ETH', 'name': 'Ethereum', 'price': 3150.0},
    {'symbol': 'USDT', 'name': 'Tether', 'price': 1.0},
    {'symbol': 'BNB', 'name': 'BNB', 'price': 620.0},
    {'symbol': 'SOL', 'name': 'Solana', 'price': 195.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load providers and currencies in parallel
      final results = await Future.wait([
        fiatService.getProviders(),
        fiatService.getSupportedCurrencies(),
      ]);

      _providers = results[0] as List<FiatProvider>;
      final currencies = results[1] as Map<String, List<String>>;

      // Update supported currencies
      _fiats = currencies['fiat'] ?? _fiats;
      final cryptoList = currencies['crypto'] ?? ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'];

      // Try to get live prices
      try {
        final cryptoService = CryptoService();
        final Map<String, double> prices = {};
        for (final symbol in cryptoList) {
          final price = await cryptoService.getPrice(symbol);
          if (price != null) {
            prices[symbol] = price;
          }
        }
        if (prices.isNotEmpty) {
          _cryptoPrices = {..._cryptoPrices, ...prices};
        }
        _cryptos = cryptoList.map((symbol) => {
          'symbol': symbol,
          'name': _getCryptoName(symbol),
          'price': _cryptoPrices[symbol] ?? 0.0,
        }).toList();
      } catch (e) {
        debugPrint('Error fetching crypto prices: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _providers = FiatService.defaultProviders;
        });
      }
    }
  }

  String _getCryptoName(String symbol) {
    final names = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'USDT': 'Tether',
      'BNB': 'BNB',
      'SOL': 'Solana',
      'USDC': 'USD Coin',
      'XRP': 'Ripple',
      'ADA': 'Cardano',
      'DOGE': 'Dogecoin',
      'MATIC': 'Polygon',
    };
    return names[symbol] ?? symbol;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[300]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Fiat On-Ramp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buy/Sell Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppColors.tradingBuy : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Buy Crypto',
                                style: TextStyle(
                                  color: _selectedTab == 0 ? Colors.white : textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppColors.tradingSell : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Sell Crypto',
                                style: TextStyle(
                                  color: _selectedTab == 1 ? Colors.white : textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Input
                Text(
                  _selectedTab == 0 ? 'I want to spend' : 'I want to sell',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: _amount,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() => _amount = value.isEmpty ? '100' : value),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCurrencyPicker(context, isDark, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(_selectedTab == 0 ? _selectedFiat : _selectedCrypto, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, color: textColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Receive Amount
                Text(
                  _selectedTab == 0 ? 'I will receive' : 'I will receive',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _calculateReceiveAmount(),
                          style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCurrencyPicker(context, isDark, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(_selectedTab == 0 ? _selectedCrypto : _selectedFiat, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, color: textColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Provider Selection
                Text('Select Provider', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else
                  ...List.generate(_providers.length, (index) {
                    final provider = _providers[index];
                    final isSelected = _selectedProvider == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedProvider = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? provider.color : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: provider.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  provider.logo,
                                  style: TextStyle(
                                    color: provider.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(provider.name, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 2),
                                          Text('${provider.rating}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Fee: ${provider.feeString} | ${provider.limitString}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: provider.paymentMethods.map((method) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(method, style: TextStyle(color: textColor, fontSize: 9)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: provider.color, size: 24),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showCheckoutModal(context, isDark),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? AppColors.tradingBuy : AppColors.tradingSell,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selectedTab == 0 ? 'Buy ${_selectedCrypto}' : 'Sell ${_selectedCrypto}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transactions are processed by third-party providers. KYC verification may be required.',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateReceiveAmount() {
    final amount = double.tryParse(_amount) ?? 100;
    final crypto = _cryptos.firstWhere((c) => c['symbol'] == _selectedCrypto, orElse: () => {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 88500.0});
    final price = (crypto['price'] as num).toDouble();
    final fee = _providers.isNotEmpty ? _providers[_selectedProvider].feePercent / 100 : 0.02;

    if (_selectedTab == 0) {
      // Buy: USD -> Crypto
      final netAmount = amount * (1 - fee);
      return (netAmount / price).toStringAsFixed(6);
    } else {
      // Sell: Crypto -> USD
      final grossAmount = amount * price;
      return (grossAmount * (1 - fee)).toStringAsFixed(2);
    }
  }

  void _showCurrencyPicker(BuildContext context, bool isDark, bool isFiat) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isFiat ? 'Select Currency' : 'Select Crypto',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: isFiat ? _fiats.length : _cryptos.length,
                itemBuilder: (context, index) {
                  if (isFiat) {
                    final fiat = _fiats[index];
                    return ListTile(
                      title: Text(fiat, style: TextStyle(color: textColor)),
                      trailing: (_selectedTab == 0 && _selectedFiat == fiat) || (_selectedTab == 1 && _selectedFiat == fiat)
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedFiat = fiat);
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    final crypto = _cryptos[index];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            crypto['symbol'].substring(0, 1),
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      title: Text(crypto['symbol'], style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text(crypto['name'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: _selectedCrypto == crypto['symbol']
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedCrypto = crypto['symbol']);
                        Navigator.pop(context);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutModal(BuildContext context, bool isDark) {
    if (_providers.isEmpty) return;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final provider = _providers[_selectedProvider];
    int currentStep = 0;
    bool isProcessing = false;
    bool isComplete = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        isComplete
                            ? 'Transaction Complete!'
                            : _selectedTab == 0
                                ? 'Buy ${_selectedCrypto}'
                                : 'Sell ${_selectedCrypto}',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Step indicator
                if (!isComplete)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildStepIndicator(0, currentStep, 'Review', isDark),
                        Expanded(child: Container(height: 2, color: currentStep > 0 ? AppColors.primary : Colors.grey[700])),
                        _buildStepIndicator(1, currentStep, 'Verify', isDark),
                        Expanded(child: Container(height: 2, color: currentStep > 1 ? AppColors.primary : Colors.grey[700])),
                        _buildStepIndicator(2, currentStep, 'Complete', isDark),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildSuccessContent(textColor, cardColor)
                        : currentStep == 0
                            ? _buildReviewStep(provider, textColor, cardColor)
                            : currentStep == 1
                                ? _buildVerifyStep(provider, textColor, cardColor, isDark)
                                : _buildProcessingStep(textColor, isProcessing),
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: isComplete
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ),
                        )
                      : Row(
                          children: [
                            if (currentStep > 0 && !isProcessing)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setModalState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Back', style: TextStyle(color: textColor)),
                                ),
                              ),
                            if (currentStep > 0 && !isProcessing) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        if (currentStep < 2) {
                                          setModalState(() => currentStep++);
                                        } else {
                                          setModalState(() => isProcessing = true);
                                          Future.delayed(const Duration(seconds: 3), () {
                                            setModalState(() {
                                              isProcessing = false;
                                              isComplete = true;
                                            });
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedTab == 0 ? AppColors.tradingBuy : AppColors.tradingSell,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        currentStep == 0
                                            ? 'Continue to ${provider.name}'
                                            : currentStep == 1
                                                ? 'Confirm & Pay'
                                                : 'Processing...',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label, bool isDark) {
    final isActive = step <= currentStep;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && step < currentStep
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(FiatProvider provider, Color textColor, Color cardColor) {
    final amount = double.tryParse(_amount) ?? 100;
    final fee = provider.feePercent / 100;
    final crypto = _cryptos.firstWhere((c) => c['symbol'] == _selectedCrypto, orElse: () => {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 88500.0});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedTab == 0 ? 'You Pay' : 'You Sell', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text(
                    _selectedTab == 0 ? '$_amount $_selectedFiat' : '$_amount $_selectedCrypto',
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Provider Fee (${provider.feeString})', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text(
                    _selectedTab == 0 ? '${(amount * fee).toStringAsFixed(2)} $_selectedFiat' : '${(amount * fee).toStringAsFixed(6)} $_selectedCrypto',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rate', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text('1 $_selectedCrypto = \$${crypto['price']}', style: TextStyle(color: textColor, fontSize: 14)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('You Receive', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    _selectedTab == 0
                        ? '${_calculateReceiveAmount()} $_selectedCrypto'
                        : '${_calculateReceiveAmount()} $_selectedFiat',
                    style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Provider info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: provider.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: provider.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    provider.logo,
                    style: TextStyle(color: provider.color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Powered by ${provider.name}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep(FiatProvider provider, Color textColor, Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verification Required', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'You will be redirected to ${provider.name} to complete identity verification.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildVerifyItem(Icons.person_outline, 'Basic Information', 'Name, email, phone', textColor),
              const SizedBox(height: 16),
              _buildVerifyItem(Icons.badge_outlined, 'Identity Document', 'Passport, ID, or Driver\'s License', textColor),
              const SizedBox(height: 16),
              _buildVerifyItem(Icons.camera_alt_outlined, 'Selfie Verification', 'Take a photo for face match', textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification typically takes 2-5 minutes. You may be asked to provide additional documents.',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Payment methods
        Text('Payment Methods', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: provider.paymentMethods.map((method) {
            IconData icon = Icons.credit_card;
            if (method == 'Bank Transfer' || method == 'Bank') icon = Icons.account_balance;
            if (method == 'Apple Pay') icon = Icons.apple;
            if (method == 'PIX') icon = Icons.qr_code;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 6),
                  Text(method, style: TextStyle(color: textColor, fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVerifyItem(IconData icon, String title, String subtitle, Color textColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
      ],
    );
  }

  Widget _buildProcessingStep(Color textColor, bool isProcessing) {
    if (isProcessing) {
      return Column(
        children: [
          const SizedBox(height: 60),
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text('Processing your transaction...', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Please wait while we confirm your payment', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Do not close this window', style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Transaction', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please review your order carefully. This transaction cannot be reversed once confirmed.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(Color textColor, Color cardColor) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.tradingBuy.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: AppColors.tradingBuy, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          _selectedTab == 0 ? 'Purchase Successful!' : 'Sale Successful!',
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedTab == 0
              ? 'Your $_selectedCrypto will be credited shortly'
              : 'Your funds will be transferred shortly',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text(
                    _selectedTab == 0
                        ? '${_calculateReceiveAmount()} $_selectedCrypto'
                        : '${_calculateReceiveAmount()} $_selectedFiat',
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tradingBuy.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Completed', style: TextStyle(color: AppColors.tradingBuy, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction ID', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text('TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', style: TextStyle(color: textColor, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A confirmation email has been sent to your registered email address.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
