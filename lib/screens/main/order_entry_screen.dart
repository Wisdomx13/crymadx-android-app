import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../providers/balance_provider.dart';
import '../../services/trading_service.dart';
import '../../widgets/widgets.dart';

/// Full-screen order entry screen - Bybit-style with order book and bottom tabs
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

class _OrderEntryScreenState extends State<OrderEntryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _orderType = 'Market';
  bool _isBuy = true;
  bool _isSubmitting = false;
  double _availableBalance = 0.0;
  double _sliderValue = 0.0;
  bool _maxSlippage = false;

  // Order book data
  List<Map<String, dynamic>> _asks = [];
  List<Map<String, dynamic>> _bids = [];
  double _lastPrice = 0.0;
  double _priceChange = 2.47;
  Timer? _orderBookTimer;

  // Bottom tabs
  late TabController _bottomTabController;
  int _selectedBottomTab = 0;

  // Orders & Positions data
  List<SpotOrder> _openOrders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _isBuy = widget.isBuy;
    _lastPrice = widget.currentPrice;
    _priceController.text = widget.currentPrice.toStringAsFixed(2);
    _bottomTabController = TabController(length: 4, vsync: this);
    _bottomTabController.addListener(() {
      setState(() => _selectedBottomTab = _bottomTabController.index);
    });
    _loadBalance();
    _loadOrderBook();
    _loadOpenOrders();
    _amountController.addListener(_onInputChanged);
    _priceController.addListener(_onInputChanged);

    _orderBookTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadOrderBook();
    });
  }

  @override
  void dispose() {
    _orderBookTimer?.cancel();
    _priceController.dispose();
    _amountController.dispose();
    _bottomTabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderBook() async {
    try {
      final orderBook = await tradingService.getOrderBook(widget.symbol);
      if (mounted) {
        setState(() {
          _asks = List<Map<String, dynamic>>.from(orderBook['asks'] ?? []);
          _bids = List<Map<String, dynamic>>.from(orderBook['bids'] ?? []);
          if (orderBook['lastPrice'] != null) {
            _lastPrice = (orderBook['lastPrice'] as num).toDouble();
          }
        });
      }
    } catch (e) {
      _generateMockOrderBook();
    }
  }

  void _generateMockOrderBook() {
    final basePrice = widget.currentPrice;
    final asks = <Map<String, dynamic>>[];
    final bids = <Map<String, dynamic>>[];

    for (int i = 0; i < 8; i++) {
      final askPrice = basePrice + (i + 1) * (basePrice * 0.00001);
      final bidPrice = basePrice - (i + 1) * (basePrice * 0.00001);
      asks.add({
        'price': askPrice,
        'quantity': (500 + (i * 300)).toDouble() + (i * 50),
      });
      bids.add({
        'price': bidPrice,
        'quantity': (400 + (i * 250)).toDouble() + (i * 40),
      });
    }

    if (mounted) {
      setState(() {
        _asks = asks.reversed.toList();
        _bids = bids;
      });
    }
  }

  Future<void> _loadOpenOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await tradingService.getOpenOrders(symbol: widget.symbol);
      if (mounted) {
        setState(() {
          _openOrders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
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
    setState(() {});
  }

  double _calculateMaxBuy() {
    final price = _orderType == 'Market'
        ? widget.currentPrice
        : (double.tryParse(_priceController.text) ?? widget.currentPrice);
    if (price <= 0) return 0;
    return _isBuy ? _availableBalance / price : _availableBalance;
  }

  String? _validateOrder() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = _orderType == 'Market'
        ? widget.currentPrice
        : (double.tryParse(_priceController.text) ?? 0);

    if (amount <= 0) return 'Please enter an amount';
    if (_orderType == 'Limit' && price <= 0) return 'Please enter a valid price';

    double requiredBalance = _isBuy ? amount * price : amount;
    if (requiredBalance > _availableBalance) {
      return 'Insufficient balance';
    }
    return null;
  }

  Future<void> _submitOrder() async {
    final validationError = _validateOrder();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      final price = _orderType == 'Market' ? null : double.parse(_priceController.text);

      final request = CreateOrderRequest(
        symbol: widget.symbol,
        side: _isBuy ? OrderSide.buy : OrderSide.sell,
        type: _orderType == 'Market' ? OrderType.market : OrderType.limit,
        quantity: amount,
        price: price,
      );

      await tradingService.createOrder(request);

      if (mounted) {
        await context.read<BalanceProvider>().refreshBalances();
        _loadOpenOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isBuy ? 'Buy' : 'Sell'} order placed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _amountController.clear();
        setState(() => _sliderValue = 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatBalance(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    if (value >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(6);
  }

  String _formatQty(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(3)}K';
    return value.toStringAsFixed(2);
  }

  void _onSliderChanged(double value) {
    setState(() => _sliderValue = value);
    final maxAmount = _calculateMaxBuy();
    final amount = maxAmount * value;
    _amountController.text = amount > 0 ? amount.toStringAsFixed(6) : '';
  }

  void _selectPrice(double price) {
    _priceController.text = price.toStringAsFixed(5);
    if (_orderType == 'Market') setState(() => _orderType = 'Limit');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final cardColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[300]!;
    final mutedColor = isDark ? Colors.grey[600]! : Colors.grey[500]!;

    final buyColor = const Color(0xFF00C853);
    final sellColor = const Color(0xFFFF5252);
    final activeColor = _isBuy ? buyColor : sellColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(textColor, mutedColor, bgColor),

            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Trading Area (Order Entry + Order Book)
                  Expanded(
                    flex: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left - Order Entry
                        Expanded(
                          flex: 5,
                          child: _buildOrderEntry(
                            isDark, textColor, cardColor, borderColor, mutedColor, activeColor, buyColor, sellColor,
                          ),
                        ),
                        // Right - Order Book
                        Expanded(
                          flex: 4,
                          child: _buildOrderBook(textColor, mutedColor, buyColor, sellColor),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Tabs Section
                  Expanded(
                    flex: 4,
                    child: _buildBottomSection(isDark, textColor, cardColor, borderColor, mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color mutedColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              CryptoIcon(symbol: widget.baseAsset, size: 24),
              const SizedBox(width: 8),
              Text(
                '${widget.baseAsset}/${widget.quoteAsset}',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '+${_priceChange.toStringAsFixed(2)}%',
            style: TextStyle(color: const Color(0xFF00C853), fontSize: 12),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: mutedColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('MM', style: TextStyle(color: mutedColor, fontSize: 10)),
          ),
          const Spacer(),
          Icon(Icons.tune, color: mutedColor, size: 20),
          const SizedBox(width: 12),
          Icon(Icons.crop_free, color: mutedColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildOrderEntry(
    bool isDark, Color textColor, Color cardColor, Color borderColor,
    Color mutedColor, Color activeColor, Color buyColor, Color sellColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buy/Sell Toggle + Margin
          Row(
            children: [
              // Buy/Sell small toggle
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isBuy = true);
                        _loadBalance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isBuy ? buyColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Buy',
                          style: TextStyle(
                            color: _isBuy ? Colors.white : mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isBuy = false);
                        _loadBalance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isBuy ? sellColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sell',
                          style: TextStyle(
                            color: !_isBuy ? Colors.white : mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('Margin', style: TextStyle(color: mutedColor, fontSize: 11)),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: mutedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Available
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available', style: TextStyle(color: mutedColor, fontSize: 11)),
              Row(
                children: [
                  Consumer<BalanceProvider>(
                    builder: (context, provider, child) {
                      final targetAsset = _isBuy ? widget.quoteAsset : widget.baseAsset;
                      final asset = provider.fundingAssets
                          .where((a) => a.symbol.toUpperCase() == targetAsset.toUpperCase())
                          .firstOrNull;
                      return Text(
                        '${_formatBalance(asset?.available ?? 0)} $targetAsset',
                        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => context.push('/deposit'),
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        border: Border.all(color: activeColor, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: activeColor, size: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Order Type Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: _orderType,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox(),
              dropdownColor: cardColor,
              style: TextStyle(color: textColor, fontSize: 13),
              icon: Icon(Icons.keyboard_arrow_down, color: mutedColor, size: 18),
              items: ['Limit', 'Market', 'Stop'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _orderType = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          // Price (for Limit orders)
          if (_orderType != 'Market') ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final current = double.tryParse(_priceController.text) ?? 0;
                      final step = current > 100 ? 0.01 : 0.00001;
                      _priceController.text = (current - step).toStringAsFixed(current > 100 ? 2 : 5);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.remove, color: mutedColor, size: 16),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: mutedColor),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Text(widget.quoteAsset, style: TextStyle(color: mutedColor, fontSize: 11)),
                  GestureDetector(
                    onTap: () {
                      final current = double.tryParse(_priceController.text) ?? 0;
                      final step = current > 100 ? 0.01 : 0.00001;
                      _priceController.text = (current + step).toStringAsFixed(current > 100 ? 2 : 5);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.add, color: mutedColor, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Order Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Order Value',
                      hintStyle: TextStyle(color: mutedColor, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(widget.quoteAsset, style: TextStyle(color: textColor, fontSize: 11)),
                      Icon(Icons.keyboard_arrow_down, color: mutedColor, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: borderColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 1,
              divisions: 4,
              onChanged: _onSliderChanged,
            ),
          ),

          // Slider labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['0%', '25%', '50%', '75%', '100%'].map((label) {
                return Text(label, style: TextStyle(color: mutedColor, fontSize: 9));
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Max Buy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max. ${_isBuy ? 'Buy' : 'Sell'}', style: TextStyle(color: mutedColor, fontSize: 10)),
              Text(
                '${_formatBalance(_calculateMaxBuy())} ${widget.baseAsset}',
                style: TextStyle(color: textColor, fontSize: 10),
              ),
            ],
          ),

          // Max Slippage
          if (_orderType == 'Market') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: _maxSlippage,
                    onChanged: (value) => setState(() => _maxSlippage = value ?? false),
                    activeColor: activeColor,
                    side: BorderSide(color: mutedColor),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Max. Slippage', style: TextStyle(color: mutedColor, fontSize: 10)),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Buy/Sell Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                disabledBackgroundColor: activeColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isBuy ? 'Buy' : 'Sell',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBook(Color textColor, Color mutedColor, Color buyColor, Color sellColor) {
    return Container(
      padding: const EdgeInsets.only(right: 12, left: 4, top: 4),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text('Price\n(${widget.quoteAsset})', style: TextStyle(color: mutedColor, fontSize: 9, height: 1.2)),
              ),
              Expanded(
                child: Text('Qty\n(${widget.baseAsset})', textAlign: TextAlign.right, style: TextStyle(color: mutedColor, fontSize: 9, height: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Asks (Red)
          Expanded(
            child: ListView.builder(
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _asks.length.clamp(0, 8),
              itemBuilder: (context, index) {
                if (index >= _asks.length) return const SizedBox();
                final ask = _asks[index];
                final price = (ask['price'] as num).toDouble();
                final qty = (ask['quantity'] as num).toDouble();
                return GestureDetector(
                  onTap: () => _selectPrice(price),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      children: [
                        Expanded(child: Text(price.toStringAsFixed(5), style: TextStyle(color: sellColor, fontSize: 10))),
                        Expanded(child: Text(_formatQty(qty), textAlign: TextAlign.right, style: TextStyle(color: textColor, fontSize: 10))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Current Price
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _lastPrice.toStringAsFixed(5),
                  style: TextStyle(color: buyColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_upward, color: buyColor, size: 12),
              ],
            ),
          ),
          Text('≈${_lastPrice.toStringAsFixed(2)} USD', style: TextStyle(color: mutedColor, fontSize: 9)),
          const SizedBox(height: 4),

          // Bids (Green)
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bids.length.clamp(0, 8),
              itemBuilder: (context, index) {
                if (index >= _bids.length) return const SizedBox();
                final bid = _bids[index];
                final price = (bid['price'] as num).toDouble();
                final qty = (bid['quantity'] as num).toDouble();
                return GestureDetector(
                  onTap: () => _selectPrice(price),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      children: [
                        Expanded(child: Text(price.toStringAsFixed(5), style: TextStyle(color: buyColor, fontSize: 10))),
                        Expanded(child: Text(_formatQty(qty), textAlign: TextAlign.right, style: TextStyle(color: textColor, fontSize: 10))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Buy/Sell Ratio
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: buyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
                child: Text('B', style: TextStyle(color: buyColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 3),
              Expanded(
                flex: 29,
                child: Container(height: 5, decoration: BoxDecoration(color: buyColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)))),
              ),
              Expanded(
                flex: 71,
                child: Container(height: 5, decoration: BoxDecoration(color: sellColor, borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)))),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: sellColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
                child: Text('S', style: TextStyle(color: sellColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('29%', style: TextStyle(color: buyColor, fontSize: 9)),
              Text('71%', style: TextStyle(color: sellColor, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark, Color textColor, Color cardColor, Color borderColor, Color mutedColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                _buildBottomTab('Orders(${_openOrders.length})', 0, textColor, mutedColor),
                _buildBottomTab('Positions(0)', 1, textColor, mutedColor),
                _buildBottomTab('Assets', 2, textColor, mutedColor),
                _buildBottomTab('Borrowing', 3, textColor, mutedColor),
                const Spacer(),
                Icon(Icons.visibility_outlined, color: mutedColor, size: 18),
                const SizedBox(width: 12),
                Icon(Icons.description_outlined, color: mutedColor, size: 18),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_box, color: const Color(0xFF00C853), size: 18),
                const SizedBox(width: 6),
                Text('All Markets', style: TextStyle(color: textColor, fontSize: 12)),
                const SizedBox(width: 16),
                Text('All Types', style: TextStyle(color: textColor, fontSize: 12)),
                Icon(Icons.keyboard_arrow_down, color: mutedColor, size: 16),
                const Spacer(),
                Icon(Icons.swap_vert, color: mutedColor, size: 18),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedBottomTab,
              children: [
                _buildOrdersTab(textColor, mutedColor),
                _buildPositionsTab(textColor, mutedColor),
                _buildAssetsTab(textColor, mutedColor),
                _buildBorrowingTab(textColor, mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTab(String label, int index, Color textColor, Color mutedColor) {
    final isSelected = _selectedBottomTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedBottomTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? textColor : mutedColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab(Color textColor, Color mutedColor) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_openOrders.isEmpty) {
      return _buildEmptyState(mutedColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _openOrders.length,
      itemBuilder: (context, index) {
        final order = _openOrders[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.symbol, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(
                    '${order.side == OrderSide.buy ? 'Buy' : 'Sell'} · ${order.type.name}',
                    style: TextStyle(color: order.side == OrderSide.buy ? const Color(0xFF00C853) : const Color(0xFFFF5252), fontSize: 10),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${order.quantity}', style: TextStyle(color: textColor, fontSize: 12)),
                  Text('@ ${order.price}', style: TextStyle(color: mutedColor, fontSize: 10)),
                ],
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await tradingService.cancelOrder(order.id);
                  _loadOpenOrders();
                },
                child: const Icon(Icons.close, color: Color(0xFFFF5252), size: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPositionsTab(Color textColor, Color mutedColor) {
    return _buildEmptyState(mutedColor);
  }

  Widget _buildAssetsTab(Color textColor, Color mutedColor) {
    return Consumer<BalanceProvider>(
      builder: (context, provider, child) {
        final assets = provider.fundingAssets.where((a) => a.available > 0 || a.locked > 0).toList();

        if (assets.isEmpty) {
          return _buildEmptyState(mutedColor);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CryptoIcon(symbol: asset.symbol, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.symbol, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(asset.name, style: TextStyle(color: mutedColor, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatBalance(asset.available), style: TextStyle(color: textColor, fontSize: 12)),
                      Text('≈\$${_formatBalance(asset.valueUsd)}', style: TextStyle(color: mutedColor, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBorrowingTab(Color textColor, Color mutedColor) {
    return _buildEmptyState(mutedColor);
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: mutedColor, size: 48),
          const SizedBox(height: 8),
          Text('No Available Data', style: TextStyle(color: mutedColor, fontSize: 13)),
        ],
      ),
    );
  }
}
