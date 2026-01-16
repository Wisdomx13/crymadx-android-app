import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import 'dart:math';

/// P2P Trading Screen - Bybit-style with Express/P2P/Block Trade tabs
class P2PScreen extends StatefulWidget {
  const P2PScreen({super.key});

  @override
  State<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends State<P2PScreen> {
  int _topTabIndex = 1; // 0 = Express, 1 = P2P, 2 = Block Trade
  bool _isBuy = true;
  String _selectedCrypto = 'USDT';
  String _selectedFiat = 'NGN';
  String _selectedPayment = 'All Payment Methods';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final List<String> _topTabs = ['Express', 'P2P', 'Block Trade'];
  final List<String> _cryptoOptions = ['USDT', 'BTC', 'ETH', 'BNB', 'SOL'];
  final List<String> _fiatOptions = ['NGN', 'USD', 'EUR', 'GBP', 'INR', 'PHP', 'VND'];
  final List<String> _paymentOptions = ['All Payment Methods', 'Bank Transfer', 'PalmPay', 'OPay', 'Kuda', 'GTBank'];

  late List<P2PVendor> _allVendors;

  @override
  void initState() {
    super.initState();
    _allVendors = _generateVendors();
  }

  List<P2PVendor> _generateVendors() {
    final random = Random();
    final names = [
      'AbuJamal', 'Dashen⭐⭐Allah', 'AYwabba 🌐', 'IBSON-WASE', 'CryptoKing💎',
      'FastTrader', 'TrustTrade✓', 'SecureSwap', 'CoinMaster🔥', 'BitPro',
      'SwiftCoin', 'ReliableTrade', 'GlobalExchange', 'InstantCrypto', 'PowerTrade',
      'EliteTrader', 'CryptoNinja', 'MoneyMover', 'FlashTrade', 'CoinVault',
      'TradeGenius', 'CryptoExpert', 'SafeCoin', 'FastMoney', 'TopTrader',
      'CoinHero', 'BitMaster', 'CryptoStar', 'TradeLord', 'SwapKing',
    ];

    final paymentMethods = ['Bank Transfer', 'PalmPay', 'OPay', 'Kuda', 'GTBank', 'Access Bank'];
    final colors = [Colors.orange, Colors.green, Colors.blue, Colors.purple, Colors.red, Colors.teal];

    List<P2PVendor> vendors = [];
    for (int i = 0; i < 120; i++) {
      final name = names[i % names.length] + (i >= 30 ? '${i ~/ 30}' : '');
      final orders = 100 + random.nextInt(3500);
      final completion = 95 + random.nextDouble() * 5;
      // NGN prices around 1,465
      final price = _isBuy
          ? 1460.0 + random.nextDouble() * 10
          : 1468.0 + random.nextDouble() * 10;
      final minAmount = (4500 + random.nextInt(500)).toDouble();
      final maxAmount = (5000 + random.nextInt(5000)).toDouble();
      final available = (50 + random.nextDouble() * 100);
      final timeLimit = [15, 30][random.nextInt(2)];
      final numPayments = 1 + random.nextInt(2);
      final payments = List.generate(numPayments, (_) => paymentMethods[random.nextInt(paymentMethods.length)]).toSet().toList();
      final avatarColor = colors[random.nextInt(colors.length)];

      vendors.add(P2PVendor(
        name: name,
        orders: orders,
        completion: completion,
        price: price,
        minAmount: minAmount,
        maxAmount: maxAmount,
        available: available,
        paymentMethods: payments,
        timeLimit: timeLimit,
        avatarColor: avatarColor,
      ));
    }

    vendors.sort((a, b) => b.orders.compareTo(a.orders));
    return vendors;
  }

  List<P2PVendor> get _paginatedVendors {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _allVendors.sublist(start, end > _allVendors.length ? _allVendors.length : end);
  }

  int get _totalPages => (_allVendors.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation with tabs
            _buildTopNavigation(),

            // Buy/Sell Toggle
            _buildBuySellToggle(),

            // Filter Bar
            _buildFilterBar(),

            // Vendor List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _paginatedVendors.length,
                itemBuilder: (context, index) => _VendorCard(
                  vendor: _paginatedVendors[index],
                  isBuy: _isBuy,
                  fiat: _selectedFiat,
                  onTrade: () => _showTradeDialog(_paginatedVendors[index]),
                ),
              ),
            ),

            // Bottom Navigation Tabs
            _buildBottomTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, color: textColor, size: 22),
          ),
          const SizedBox(width: 20),
          // Tab Pills
          ...List.generate(_topTabs.length, (i) {
            final isSelected = _topTabIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _topTabIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Text(
                  _topTabs[i],
                  style: TextStyle(
                    color: isSelected ? textColor : subtextColor,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Currency Selector
          GestureDetector(
            onTap: () => _showSelector('Fiat', _fiatOptions, (v) => setState(() => _selectedFiat = v)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(_selectedFiat, style: TextStyle(color: textColor, fontSize: 13)),
                  Icon(Icons.arrow_drop_down, color: subtextColor, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuySellToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Buy Tab
          GestureDetector(
            onTap: () => setState(() {
              _isBuy = true;
              _allVendors = _generateVendors();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _isBuy ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Buy',
                style: TextStyle(
                  color: _isBuy ? Colors.black : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sell Tab
          GestureDetector(
            onTap: () => setState(() {
              _isBuy = false;
              _allVendors = _generateVendors();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: !_isBuy ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sell',
                style: TextStyle(
                  color: !_isBuy ? Colors.black : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Spacer(),
          // SOL Icon (like Bybit)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers, color: Colors.teal, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Crypto Selector
          GestureDetector(
            onTap: () => _showSelector('Crypto', _cryptoOptions, (v) => setState(() => _selectedCrypto = v)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  CryptoIcon(symbol: _selectedCrypto, size: 16),
                  const SizedBox(width: 6),
                  Text(_selectedCrypto, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[500], size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Amount Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text('Amount', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                Icon(Icons.arrow_drop_down, color: Colors.grey[500], size: 18),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Payment Method Filter
          Expanded(
            child: GestureDetector(
              onTap: () => _showSelector('Payment', _paymentOptions, (v) => setState(() => _selectedPayment = v)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedPayment,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[500], size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Icon with badge
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.filter_list, color: Colors.grey[500], size: 18),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.tradingSell,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomTab(icon: Icons.swap_horiz, label: 'P2P', isSelected: true),
          _BottomTab(icon: Icons.receipt_long, label: 'Orders', isSelected: false),
          _BottomTab(icon: Icons.campaign, label: 'Ads', isSelected: false),
          _BottomTab(icon: Icons.person_outline, label: 'Profile', isSelected: false),
        ],
      ),
    );
  }

  void _showSelector(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select $title', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onSelect(opt);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showTradeDialog(P2PVendor vendor) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: vendor.avatarColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(vendor.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text('${vendor.orders} Orders | ${vendor.completion.toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price', style: TextStyle(color: Colors.grey[600])),
                Text('₦ ${vendor.price.toStringAsFixed(2)}', style: TextStyle(color: _isBuy ? AppColors.tradingBuy : AppColors.tradingSell, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            // Amount Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('I want to ${_isBuy ? 'pay' : 'receive'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text('Limit: ${vendor.minAmount.toStringAsFixed(0)} - ${vendor.maxAmount.toStringAsFixed(0)} $_selectedFiat',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      border: InputBorder.none,
                      suffixText: _selectedFiat,
                      suffixStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Payment Methods
            Text('Payment Methods', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: vendor.paymentMethods.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12)),
              )).toList(),
            ),
            const SizedBox(height: 20),
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order placed with ${vendor.name}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isBuy ? 'Buy USDT' : 'Sell USDT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final P2PVendor vendor;
  final bool isBuy;
  final String fiat;
  final VoidCallback onTrade;

  const _VendorCard({
    required this.vendor,
    required this.isBuy,
    required this.fiat,
    required this.onTrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Name and Orders
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: vendor.avatarColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(vendor.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[600], size: 12),
                        const SizedBox(width: 4),
                        Text('${vendor.timeLimit}m', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${vendor.orders} Orders (${vendor.completion.toStringAsFixed(0)}%)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price Row
          Text(
            '₦ ${vendor.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Limits and Quantity
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Limits', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  Text('${vendor.minAmount.toStringAsFixed(2)} - ${vendor.maxAmount.toStringAsFixed(2)} $fiat',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  Text('${vendor.available.toStringAsFixed(4)} USDT',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment Methods and Buy Button
          Row(
            children: [
              // Payment method indicators
              ...vendor.paymentMethods.take(2).map((p) => Container(
                margin: const EdgeInsets.only(right: 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: p.contains('Palm') ? Colors.purple : (p.contains('Bank') ? Colors.green : Colors.orange),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(p, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              )).toList(),
              const Spacer(),
              // Buy/Sell Button
              GestureDetector(
                onTap: onTrade,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isBuy ? 'Buy' : 'Sell',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _BottomTab({required this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}

class P2PVendor {
  final String name;
  final int orders;
  final double completion;
  final double price;
  final double minAmount;
  final double maxAmount;
  final double available;
  final List<String> paymentMethods;
  final int timeLimit;
  final Color avatarColor;

  P2PVendor({
    required this.name,
    required this.orders,
    required this.completion,
    required this.price,
    required this.minAmount,
    required this.maxAmount,
    required this.available,
    required this.paymentMethods,
    required this.timeLimit,
    required this.avatarColor,
  });
}
