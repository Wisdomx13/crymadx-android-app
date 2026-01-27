import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/app_button.dart';
import '../../providers/balance_provider.dart';
import '../../navigation/app_router.dart';

// Network info for withdrawals (static config - can be fetched from API later)
class NetworkInfo {
  final String name;
  final String shortName;
  final double fee;
  final double minWithdraw;
  final String estimatedTime;

  const NetworkInfo({
    required this.name,
    required this.shortName,
    required this.fee,
    required this.minWithdraw,
    required this.estimatedTime,
  });
}

// Network configurations per currency
List<NetworkInfo> _getNetworksForCurrency(String symbol) {
  const Map<String, List<NetworkInfo>> networkConfigs = {
    'BTC': [
      NetworkInfo(name: 'Bitcoin Network', shortName: 'BTC', fee: 0.0001, minWithdraw: 0.0002, estimatedTime: '~30 min'),
    ],
    'ETH': [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 0.005, minWithdraw: 0.01, estimatedTime: '~10 min'),
      NetworkInfo(name: 'Arbitrum One', shortName: 'ARB', fee: 0.0002, minWithdraw: 0.001, estimatedTime: '~2 min'),
    ],
    'USDT': [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 15.0, minWithdraw: 50.0, estimatedTime: '~10 min'),
      NetworkInfo(name: 'Tron Network', shortName: 'TRC20', fee: 1.0, minWithdraw: 10.0, estimatedTime: '~3 min'),
    ],
    'USDC': [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 12.0, minWithdraw: 50.0, estimatedTime: '~10 min'),
      NetworkInfo(name: 'Polygon Network', shortName: 'MATIC', fee: 0.1, minWithdraw: 5.0, estimatedTime: '~2 min'),
    ],
    'SOL': [
      NetworkInfo(name: 'Solana Network', shortName: 'SOL', fee: 0.01, minWithdraw: 0.1, estimatedTime: '~2 min'),
    ],
  };
  // Default network if currency not in config
  return networkConfigs[symbol.toUpperCase()] ?? [
    NetworkInfo(name: '$symbol Network', shortName: symbol, fee: 0.001, minWithdraw: 0.01, estimatedTime: '~10 min'),
  ];
}

class WithdrawScreen extends StatefulWidget {
  final String? initialSymbol;
  final String? initialName;

  const WithdrawScreen({
    super.key,
    this.initialSymbol,
    this.initialName,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  AssetBalance? _selectedAsset;
  NetworkInfo? _selectedNetwork;
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isProcessing = false;
  String _searchQuery = '';

  // Validation states
  bool _isAddressValid = false;
  String? _addressError;
  bool _isValidatingAddress = false;

  // Verification states
  bool _requiresVerification = true;
  String _verificationMethod = 'email'; // 'email' or '2fa'
  final _verificationCodeController = TextEditingController();
  bool _verificationCodeSent = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Set initial asset after build (to access provider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedAsset();
    });
  }

  void _initializeSelectedAsset() {
    final balanceProvider = context.read<BalanceProvider>();
    final assets = balanceProvider.fundingAssets;

    if (assets.isEmpty) return;

    if (widget.initialSymbol != null) {
      final found = assets.where(
        (asset) => asset.symbol.toUpperCase() == widget.initialSymbol!.toUpperCase(),
      );
      _selectedAsset = found.isNotEmpty ? found.first : assets.first;
    } else {
      _selectedAsset = assets.first;
    }

    final networks = _getNetworksForCurrency(_selectedAsset!.symbol);
    if (networks.isNotEmpty) {
      _selectedNetwork = networks.first;
    }
    setState(() {});
  }

  double get _withdrawAmount {
    return double.tryParse(_amountController.text) ?? 0;
  }

  double get _receiveAmount {
    if (_selectedNetwork == null) return 0;
    final amount = _withdrawAmount - _selectedNetwork!.fee;
    return amount > 0 ? amount : 0;
  }

  bool get _isValid {
    if (_selectedAsset == null || _selectedNetwork == null) return false;
    if (_addressController.text.isEmpty) return false;
    if (!_isAddressValid) return false;
    if (_withdrawAmount <= 0) return false;
    if (_withdrawAmount > _selectedAsset!.available) return false;
    if (_withdrawAmount < _selectedNetwork!.minWithdraw) return false;
    return true;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _verificationCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // Address validation based on network/currency
  void _validateAddress(String address) async {
    if (address.isEmpty) {
      setState(() {
        _isAddressValid = false;
        _addressError = null;
        _isValidatingAddress = false;
      });
      return;
    }

    setState(() => _isValidatingAddress = true);

    // Simulate API validation delay
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Basic address validation based on currency
    bool isValid = false;
    String? error;

    final currency = _selectedAsset?.symbol.toUpperCase() ?? '';
    final network = _selectedNetwork?.shortName.toUpperCase() ?? '';

    if (currency == 'BTC') {
      // Bitcoin address validation (basic)
      isValid = (address.startsWith('1') || address.startsWith('3') || address.startsWith('bc1')) &&
          address.length >= 26 && address.length <= 62;
      if (!isValid) error = 'Invalid Bitcoin address format';
    } else if (currency == 'ETH' || network == 'ERC20' || network == 'ARB') {
      // Ethereum address validation
      isValid = address.startsWith('0x') && address.length == 42;
      if (!isValid) error = 'Invalid Ethereum address format';
    } else if (network == 'TRC20') {
      // Tron address validation
      isValid = address.startsWith('T') && address.length == 34;
      if (!isValid) error = 'Invalid Tron address format';
    } else if (currency == 'SOL') {
      // Solana address validation
      isValid = address.length >= 32 && address.length <= 44;
      if (!isValid) error = 'Invalid Solana address format';
    } else {
      // Generic validation for other currencies
      isValid = address.length >= 20;
      if (!isValid) error = 'Invalid address format';
    }

    setState(() {
      _isAddressValid = isValid;
      _addressError = error;
      _isValidatingAddress = false;
    });
  }

  // Send verification code
  void _sendVerificationCode() async {
    setState(() => _isProcessing = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _verificationCodeSent = true;
        _resendCountdown = 60;
        _isProcessing = false;
      });

      // Start countdown timer
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_verificationMethod == 'email'
              ? 'Verification code sent to your email'
              : 'Enter the code from your authenticator app'),
          backgroundColor: AppColors.tradingBuy,
        ),
      );
    }
  }

  // QR Scanner
  void _openQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQRScannerSheet(),
    );
  }

  void _selectAsset(AssetBalance asset) {
    final networks = _getNetworksForCurrency(asset.symbol);
    setState(() {
      _selectedAsset = asset;
      _selectedNetwork = networks.isNotEmpty ? networks.first : null;
      _amountController.clear();
    });
    Navigator.pop(context);
  }

  void _selectNetwork(NetworkInfo network) {
    setState(() {
      _selectedNetwork = network;
    });
  }

  void _setMaxAmount() {
    if (_selectedAsset == null) return;
    _amountController.text = _selectedAsset!.available.toString();
    setState(() {});
  }

  Future<void> _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _addressController.text = data!.text!.trim();
      setState(() {});
    }
  }

  void _showCoinSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCoinSelectorSheet(),
    );
  }

  void _processWithdraw() async {
    if (!_isValid) return;

    // Show verification modal
    _showVerificationModal();
  }

  void _showVerificationModal() {
    _verificationCodeController.clear();
    setState(() {
      _verificationCodeSent = false;
      _resendCountdown = 0;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildVerificationSheet(),
    );
  }

  void _completeWithdrawal() async {
    final code = _verificationCodeController.text;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit code'),
          backgroundColor: AppColors.tradingSell,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate API call to verify code and process withdrawal
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context); // Close verification modal

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildSuccessDialog(ctx),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Withdraw Crypto',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: AppColors.textSecondary),
            onPressed: () {},
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Coin Selector
                      _buildCoinSelector(),
                      const SizedBox(height: 20),

                      // Network Selection
                      if (_selectedAsset != null) ...[
                        _buildSectionLabel('Network'),
                        const SizedBox(height: 10),
                        _buildNetworkSelector(),
                        const SizedBox(height: 20),
                      ],

                      // Address Input
                      _buildSectionLabel('Withdrawal Address'),
                      const SizedBox(height: 10),
                      _buildAddressInput(),
                      const SizedBox(height: 20),

                      // Amount Input
                      _buildSectionLabel('Amount'),
                      const SizedBox(height: 10),
                      _buildAmountInput(),
                      const SizedBox(height: 24),

                      // Transaction Details
                      if (_selectedNetwork != null) _buildTransactionDetails(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCoinSelector() {
    return GestureDetector(
      onTap: _showCoinSelector,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            if (_selectedAsset != null) ...[
              CryptoIcon(symbol: _selectedAsset!.symbol, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAsset!.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedAsset!.name,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedAsset!.available} ${_selectedAsset!.symbol}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.currency_bitcoin, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 14),
              Text(
                'Select Coin',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    if (_selectedAsset == null) return const SizedBox.shrink();

    final networks = _getNetworksForCurrency(_selectedAsset!.symbol);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: networks.map((network) {
          final isSelected = _selectedNetwork?.name == network.name;
          return GestureDetector(
            onTap: () => _selectNetwork(network),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFF2A2A2A),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.shortName,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fee: ${network.fee} ${_selectedAsset!.symbol}',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    network.estimatedTime,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary.withOpacity(0.8) : AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _addressError != null
                  ? AppColors.tradingSell
                  : _isAddressValid
                      ? AppColors.tradingBuy
                      : const Color(0xFF2A2A2A),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter or paste address',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _isValidatingAddress
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        : _isAddressValid
                            ? Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 20)
                            : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _validateAddress(value);
                  },
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _pasteAddress();
                  _validateAddress(_addressController.text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Paste',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openQRScanner,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 20),
                ),
              ),
            ],
          ),
        ),
        // Error message
        if (_addressError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.tradingSell, size: 14),
                const SizedBox(width: 4),
                Text(
                  _addressError!,
                  style: TextStyle(
                    color: AppColors.tradingSell,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        // Valid address indicator
        if (_isAddressValid && _addressError == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.tradingBuy, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Valid ${_selectedNetwork?.shortName ?? ''} address',
                  style: TextStyle(
                    color: AppColors.tradingBuy,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 20, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_selectedAsset != null) ...[
                Text(
                  _selectedAsset!.symbol,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _setMaxAmount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MAX',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_selectedAsset != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available: ${_selectedAsset!.available} ${_selectedAsset!.symbol}',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                  if (_selectedNetwork != null)
                    Text(
                      'Min: ${_selectedNetwork!.minWithdraw} ${_selectedAsset!.symbol}',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Network', _selectedNetwork!.shortName),
          const SizedBox(height: 12),
          _buildDetailRow('Network Fee', '${_selectedNetwork!.fee} ${_selectedAsset!.symbol}'),
          const SizedBox(height: 12),
          _buildDetailRow('Estimated Time', _selectedNetwork!.estimatedTime),
          const Divider(color: Color(0xFF2A2A2A), height: 24),
          _buildDetailRow(
            'You will receive',
            '${_receiveAmount > 0 ? _receiveAmount.toStringAsFixed(8) : '0.00'} ${_selectedAsset!.symbol}',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? AppColors.primary : Colors.white,
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(top: BorderSide(color: const Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isValid && !_isProcessing ? _processWithdraw : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isValid ? AppColors.primary : const Color(0xFF2A2A2A),
              foregroundColor: _isValid ? Colors.black : AppColors.textTertiary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'Withdraw',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinSelectorSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        final balanceProvider = context.watch<BalanceProvider>();
        final allAssets = balanceProvider.fundingAssets;
        final filteredAssets = allAssets.where((asset) {
          if (_searchQuery.isEmpty) return true;
          return asset.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              asset.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Coin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search coin',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Coin list
              Expanded(
                child: filteredAssets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No assets available',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Deposit crypto to get started',
                              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = filteredAssets[index];
                          final isSelected = _selectedAsset?.symbol == asset.symbol;
                          return GestureDetector(
                            onTap: () => _selectAsset(asset),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: AppColors.primary.withOpacity(0.5))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  CryptoIcon(symbol: asset.symbol, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          asset.symbol,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          asset.name,
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${asset.available}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$${asset.valueUsd.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.tradingBuy.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.tradingBuy,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Withdrawal Submitted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your withdrawal of $_withdrawAmount ${_selectedAsset!.symbol} has been submitted successfully.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated time: ${_selectedNetwork!.estimatedTime}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.transactionHistory);
              },
              child: Text(
                'View Transaction History',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QR Scanner Sheet
  Widget _buildQRScannerSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Scanner
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        String scannedAddress = barcode.rawValue!;

                        // Handle crypto URI schemes (e.g., bitcoin:address, ethereum:address)
                        if (scannedAddress.contains(':')) {
                          final parts = scannedAddress.split(':');
                          if (parts.length > 1) {
                            scannedAddress = parts[1].split('?').first;
                          }
                        }

                        _addressController.text = scannedAddress.trim();
                        _validateAddress(scannedAddress.trim());
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Address scanned successfully'),
                            backgroundColor: AppColors.tradingBuy,
                          ),
                        );
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Position the QR code within the frame to scan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Verification Sheet
  Widget _buildVerificationSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Security Verification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Please verify your identity to complete this withdrawal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Withdrawal Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          Text(
                            '$_withdrawAmount ${_selectedAsset?.symbol ?? ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('To', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          Text(
                            '${_addressController.text.substring(0, 8)}...${_addressController.text.substring(_addressController.text.length - 6)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Verification Method Selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            _verificationMethod = 'email';
                            _verificationCodeSent = false;
                            _verificationCodeController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _verificationMethod == 'email'
                                ? AppColors.primary.withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _verificationMethod == 'email'
                                  ? AppColors.primary
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: _verificationMethod == 'email'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Email',
                                style: TextStyle(
                                  color: _verificationMethod == 'email'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
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
                        onTap: () {
                          setSheetState(() {
                            _verificationMethod = '2fa';
                            _verificationCodeSent = true; // 2FA doesn't need sending
                            _verificationCodeController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _verificationMethod == '2fa'
                                ? AppColors.primary.withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _verificationMethod == '2fa'
                                  ? AppColors.primary
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                color: _verificationMethod == '2fa'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '2FA',
                                style: TextStyle(
                                  color: _verificationMethod == '2fa'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Code Input
                if (_verificationMethod == 'email' && !_verificationCodeSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              _sendVerificationCode();
                              setSheetState(() {});
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Send Verification Code',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ] else ...[
                  // Code entry
                  Text(
                    _verificationMethod == 'email'
                        ? 'Enter the 6-digit code sent to your email'
                        : 'Enter the 6-digit code from your authenticator app',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: TextField(
                      controller: _verificationCodeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Resend button (only for email)
                  if (_verificationMethod == 'email')
                    GestureDetector(
                      onTap: _resendCountdown > 0
                          ? null
                          : () {
                              _sendVerificationCode();
                              setSheetState(() {});
                            },
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend code in ${_resendCountdown}s'
                            : 'Resend code',
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? AppColors.textTertiary
                              : AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _verificationCodeController.text.length == 6 && !_isProcessing
                          ? _completeWithdrawal
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verificationCodeController.text.length == 6
                            ? AppColors.primary
                            : const Color(0xFF2A2A2A),
                        foregroundColor: _verificationCodeController.text.length == 6
                            ? Colors.black
                            : AppColors.textTertiary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Confirm Withdrawal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
