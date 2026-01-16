import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/app_button.dart';

// Mock balances for withdrawal
class WithdrawableAsset {
  final String symbol;
  final String name;
  final double available;
  final double locked;
  final double usdValue;
  final List<NetworkInfo> networks;

  const WithdrawableAsset({
    required this.symbol,
    required this.name,
    required this.available,
    required this.locked,
    required this.usdValue,
    required this.networks,
  });

  double get total => available + locked;
}

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

final withdrawableAssets = [
  WithdrawableAsset(
    symbol: 'BTC',
    name: 'Bitcoin',
    available: 0.0542,
    locked: 0.0,
    usdValue: 5124.56,
    networks: [
      NetworkInfo(name: 'Bitcoin Network', shortName: 'BTC', fee: 0.0001, minWithdraw: 0.0002, estimatedTime: '~30 min'),
      NetworkInfo(name: 'BNB Smart Chain', shortName: 'BEP20', fee: 0.000001, minWithdraw: 0.00001, estimatedTime: '~5 min'),
    ],
  ),
  WithdrawableAsset(
    symbol: 'ETH',
    name: 'Ethereum',
    available: 1.2450,
    locked: 0.0,
    usdValue: 4234.15,
    networks: [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 0.005, minWithdraw: 0.01, estimatedTime: '~10 min'),
      NetworkInfo(name: 'BNB Smart Chain', shortName: 'BEP20', fee: 0.0001, minWithdraw: 0.001, estimatedTime: '~5 min'),
      NetworkInfo(name: 'Arbitrum One', shortName: 'ARB', fee: 0.0002, minWithdraw: 0.001, estimatedTime: '~2 min'),
    ],
  ),
  WithdrawableAsset(
    symbol: 'USDT',
    name: 'Tether',
    available: 2500.00,
    locked: 500.00,
    usdValue: 2500.00,
    networks: [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 15.0, minWithdraw: 50.0, estimatedTime: '~10 min'),
      NetworkInfo(name: 'Tron Network', shortName: 'TRC20', fee: 1.0, minWithdraw: 10.0, estimatedTime: '~3 min'),
      NetworkInfo(name: 'BNB Smart Chain', shortName: 'BEP20', fee: 0.5, minWithdraw: 10.0, estimatedTime: '~5 min'),
    ],
  ),
  WithdrawableAsset(
    symbol: 'USDC',
    name: 'USD Coin',
    available: 1850.00,
    locked: 0.0,
    usdValue: 1850.00,
    networks: [
      NetworkInfo(name: 'Ethereum Network', shortName: 'ERC20', fee: 12.0, minWithdraw: 50.0, estimatedTime: '~10 min'),
      NetworkInfo(name: 'BNB Smart Chain', shortName: 'BEP20', fee: 0.5, minWithdraw: 10.0, estimatedTime: '~5 min'),
      NetworkInfo(name: 'Polygon Network', shortName: 'MATIC', fee: 0.1, minWithdraw: 5.0, estimatedTime: '~2 min'),
    ],
  ),
  WithdrawableAsset(
    symbol: 'BNB',
    name: 'BNB',
    available: 3.5,
    locked: 0.0,
    usdValue: 2100.00,
    networks: [
      NetworkInfo(name: 'BNB Smart Chain', shortName: 'BEP20', fee: 0.0005, minWithdraw: 0.01, estimatedTime: '~5 min'),
      NetworkInfo(name: 'BNB Beacon Chain', shortName: 'BEP2', fee: 0.001, minWithdraw: 0.01, estimatedTime: '~5 min'),
    ],
  ),
  WithdrawableAsset(
    symbol: 'SOL',
    name: 'Solana',
    available: 25.0,
    locked: 0.0,
    usdValue: 3750.00,
    networks: [
      NetworkInfo(name: 'Solana Network', shortName: 'SOL', fee: 0.01, minWithdraw: 0.1, estimatedTime: '~2 min'),
    ],
  ),
];

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
  WithdrawableAsset? _selectedAsset;
  NetworkInfo? _selectedNetwork;
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isProcessing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set initial asset if provided, otherwise default to first asset
    if (widget.initialSymbol != null) {
      _selectedAsset = withdrawableAssets.firstWhere(
        (asset) => asset.symbol.toUpperCase() == widget.initialSymbol!.toUpperCase(),
        orElse: () => withdrawableAssets.first,
      );
    } else {
      _selectedAsset = withdrawableAssets.first;
    }
    if (_selectedAsset!.networks.isNotEmpty) {
      _selectedNetwork = _selectedAsset!.networks.first;
    }
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
    super.dispose();
  }

  void _selectAsset(WithdrawableAsset asset) {
    setState(() {
      _selectedAsset = asset;
      _selectedNetwork = asset.networks.first;
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

  void _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _addressController.text = data!.text!;
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

    setState(() => _isProcessing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _selectedAsset!.networks.map((network) {
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
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
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          GestureDetector(
            onTap: _pasteAddress,
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
            onTap: () {
              // TODO: Implement QR scanner
            },
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
        final filteredAssets = withdrawableAssets.where((asset) {
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
                child: ListView.builder(
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
                                  '\$${asset.usdValue.toStringAsFixed(2)}',
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
                // TODO: Navigate to transaction history
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
}
