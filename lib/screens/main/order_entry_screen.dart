import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../providers/balance_provider.dart';
import '../../services/trading_service.dart';
import '../../widgets/widgets.dart';

/// Full-screen order entry screen - Bybit-style
class OrderEntryScreen extends StatefulWidget {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final bool isBuy;
  final double currentPrice;

  const OrderEntryScreen({
    super.key,
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.isBuy,
    required this.currentPrice,
  });

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _stopPriceController = TextEditingController();

  String _orderType = 'Limit'; // Limit, Market, Stop
  bool _isBuy = true;
  bool _isSubmitting = false;
  String? _submitError;
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _isBuy = widget.isBuy;
    _priceController.text = widget.currentPrice.toStringAsFixed(2);
    _loadBalance();
    _amountController.addListener(_onInputChanged);
    _priceController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    _stopPriceController.dispose();
    super.dispose();
  }

  void _loadBalance() {
    final balanceProvider = context.read<BalanceProvider>();
    final targetAsset = _isBuy ? widget.quoteAsset : widget.baseAsset;

    final asset = balanceProvider.fundingAssets
        .where((a) => a.symbol.toUpperCase() == targetAsset.toUpperCase())
        .firstOrNull;

    setState(() {
      _availableBalance = asset?.available ?? 0.0;
    });
  }

  void _onInputChanged() {
    setState(() {}); // Trigger rebuild for total calculation
  }

  double _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = _orderType == 'Market'
        ? widget.currentPrice
        : (double.tryParse(_priceController.text) ?? widget.currentPrice);
    return amount * price;
  }

  String? _validateOrder() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = _orderType == 'Market'
        ? widget.currentPrice
        : (double.tryParse(_priceController.text) ?? 0);

    if (amount <= 0) {
      return 'Please enter an amount';
    }

    if (_orderType == 'Limit' && price <= 0) {
      return 'Please enter a valid price';
    }

    if (_orderType == 'Stop' && (double.tryParse(_stopPriceController.text) ?? 0) <= 0) {
      return 'Please enter a stop price';
    }

    double requiredBalance;
    if (_isBuy) {
      requiredBalance = amount * price;
    } else {
      requiredBalance = amount;
    }

    if (requiredBalance > _availableBalance) {
      final asset = _isBuy ? widget.quoteAsset : widget.baseAsset;
      return 'Insufficient balance. Available: ${_formatBalance(_availableBalance)} $asset';
    }

    return null;
  }

  Future<void> _submitOrder() async {
    final validationError = _validateOrder();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final price = _orderType == 'Market'
          ? null
          : double.parse(_priceController.text);

      OrderType orderType;
      switch (_orderType) {
        case 'Limit':
          orderType = OrderType.limit;
          break;
        case 'Stop':
          orderType = OrderType.stopLimit;
          break;
        default:
          orderType = OrderType.market;
      }

      final request = CreateOrderRequest(
        symbol: widget.symbol,
        side: _isBuy ? OrderSide.buy : OrderSide.sell,
        type: orderType,
        quantity: amount,
        price: price,
        stopPrice: _orderType == 'Stop' ? double.tryParse(_stopPriceController.text) : null,
      );

      final order = await tradingService.createOrder(request);

      // Refresh balances after successful order
      if (mounted) {
        await context.read<BalanceProvider>().refreshBalances();
        _showOrderConfirmation(order);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $_submitError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrderConfirmation(SpotOrder order) {
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
                color: const Color(0xFF00C853).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF00C853), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${_isBuy ? 'Buy' : 'Sell'} ${order.quantity} ${widget.baseAsset}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (order.price > 0) ...[
              const SizedBox(height: 4),
              Text(
                'at ${order.price.toStringAsFixed(2)} ${widget.quoteAsset}',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Order ID: ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to trading screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBalance(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else if (value >= 1) {
      return value.toStringAsFixed(2);
    } else {
      return value.toStringAsFixed(6);
    }
  }

  void _setPercentage(double percent) {
    final price = _orderType == 'Market'
        ? widget.currentPrice
        : (double.tryParse(_priceController.text) ?? widget.currentPrice);

    double maxAmount;
    if (_isBuy) {
      // For buy, calculate max amount based on USDT balance and price
      maxAmount = _availableBalance / price;
    } else {
      // For sell, use the base asset balance directly
      maxAmount = _availableBalance;
    }

    final amount = maxAmount * percent;
    _amountController.text = amount.toStringAsFixed(6);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[400]!;
    final mutedColor = isDark ? Colors.grey[600]! : Colors.grey[500]!;

    final buyColor = const Color(0xFF00C853);
    final sellColor = const Color(0xFFFF5252);
    final activeColor = _isBuy ? buyColor : sellColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CryptoIcon(symbol: widget.baseAsset, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.symbol,
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Text(
            '\$${widget.currentPrice.toStringAsFixed(2)}',
            style: TextStyle(color: mutedColor, fontSize: 14),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Buy/Sell Toggle
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isBuy = true);
                        _loadBalance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isBuy ? buyColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Buy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isBuy ? Colors.white : mutedColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isBuy = false);
                        _loadBalance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isBuy ? sellColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sell',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isBuy ? Colors.white : mutedColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Selector
                    Row(
                      children: ['Limit', 'Market', 'Stop'].map((type) {
                        final isSelected = _orderType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _orderType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? activeColor : borderColor,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? activeColor : mutedColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Price Input (for Limit/Stop orders)
                    if (_orderType != 'Market') ...[
                      Text('Price', style: TextStyle(color: mutedColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: mutedColor, size: 20),
                              onPressed: () {
                                final current = double.tryParse(_priceController.text) ?? 0;
                                _priceController.text = (current - 1).toStringAsFixed(2);
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: textColor, fontSize: 16),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(color: mutedColor),
                                  suffixText: widget.quoteAsset,
                                  suffixStyle: TextStyle(color: mutedColor, fontSize: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: mutedColor, size: 20),
                              onPressed: () {
                                final current = double.tryParse(_priceController.text) ?? 0;
                                _priceController.text = (current + 1).toStringAsFixed(2);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _priceController.text = widget.currentPrice.toStringAsFixed(2);
                        },
                        child: Text(
                          'Market Price: \$${widget.currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: activeColor, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Stop Price (for Stop orders)
                    if (_orderType == 'Stop') ...[
                      Text('Stop Price', style: TextStyle(color: mutedColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _stopPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: mutedColor),
                            suffixText: widget.quoteAsset,
                            suffixStyle: TextStyle(color: mutedColor, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount Input
                    Text('Amount', style: TextStyle(color: mutedColor, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(color: mutedColor),
                          suffixText: widget.baseAsset,
                          suffixStyle: TextStyle(color: mutedColor, fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Percentage Buttons
                    Row(
                      children: [0.25, 0.50, 0.75, 1.0].map((percent) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _setPercentage(percent),
                            child: Container(
                              margin: EdgeInsets.only(right: percent < 1.0 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(percent * 100).toInt()}%',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: mutedColor, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Balance and Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available', style: TextStyle(color: mutedColor, fontSize: 13)),
                              Consumer<BalanceProvider>(
                                builder: (context, provider, child) {
                                  final targetAsset = _isBuy ? widget.quoteAsset : widget.baseAsset;
                                  final asset = provider.fundingAssets
                                      .where((a) => a.symbol.toUpperCase() == targetAsset.toUpperCase())
                                      .firstOrNull;
                                  final balance = asset?.available ?? 0.0;
                                  return Text(
                                    '${_formatBalance(balance)} $targetAsset',
                                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: TextStyle(color: mutedColor, fontSize: 13)),
                              Text(
                                '${_calculateTotal().toStringAsFixed(2)} ${widget.quoteAsset}',
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (_orderType != 'Market') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Est. Fee (0.1%)', style: TextStyle(color: mutedColor, fontSize: 13)),
                                Text(
                                  '${(_calculateTotal() * 0.001).toStringAsFixed(4)} ${widget.quoteAsset}',
                                  style: TextStyle(color: mutedColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    disabledBackgroundColor: activeColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          '${_isBuy ? 'Buy' : 'Sell'} ${widget.baseAsset}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
