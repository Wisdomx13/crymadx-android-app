import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../services/p2p_service.dart';
import '../../services/cache_service.dart';

/// P2P Trading Screen - Bybit-style peer-to-peer trading
class P2PScreen extends StatefulWidget {
  const P2PScreen({super.key});

  @override
  State<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends State<P2PScreen> {
  bool _isBuy = true;
  String _selectedCrypto = 'USDT';
  String _selectedFiat = 'NGN';
  String _selectedPayment = 'All Payment Methods';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final List<String> _cryptoOptions = ['USDT', 'BTC', 'ETH', 'BNB', 'SOL'];
  final List<String> _fiatOptions = ['NGN', 'USD', 'EUR', 'GBP', 'INR', 'PHP', 'VND'];
  final List<String> _paymentOptions = ['All Payment Methods', 'Bank Transfer', 'PalmPay', 'OPay', 'Kuda', 'GTBank'];

  List<P2POrder> _orders = [];
  List<P2PTrade> _myTrades = [];
  bool _isLoading = true;
  String? _error;
  int _bottomTabIndex = 0; // 0 = P2P, 1 = Orders, 2 = Ads, 3 = Profile

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to load from cache first if offline
      if (!cacheService.isOnline) {
        final cachedOrders = cacheService.getCachedP2POrders(
          type: _isBuy ? 'sell' : 'buy',
          currency: _selectedCrypto,
        );
        if (cachedOrders.isNotEmpty) {
          setState(() {
            _orders = cachedOrders.map((json) => P2POrder.fromJson(json)).toList();
            _isLoading = false;
          });
          return;
        }
      }

      // Load from API
      final orders = await p2pService.getOrders(
        type: _isBuy ? 'sell' : 'buy', // If user wants to buy, show sell orders
        currency: _selectedCrypto,
        fiatCurrency: _selectedFiat,
        paymentMethod: _selectedPayment == 'All Payment Methods' ? null : _selectedPayment,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      // Cache the results
      await cacheService.cacheP2POrders(
        orders.map((o) => {
          'id': o.id,
          'type': o.type,
          'currency': o.currency,
          'fiatCurrency': o.fiatCurrency,
          'price': o.price,
          'amount': o.amount,
          'minAmount': o.minAmount,
          'maxAmount': o.maxAmount,
          'paymentMethods': o.paymentMethods,
          'status': o.status,
          'merchantName': o.merchantName,
          'merchantRating': o.merchantRating,
          'merchantTrades': o.merchantTrades,
        }).toList(),
        type: _isBuy ? 'sell' : 'buy',
        currency: _selectedCrypto,
      );

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      // Try cache on error
      final cachedOrders = cacheService.getCachedP2POrders(
        type: _isBuy ? 'sell' : 'buy',
        currency: _selectedCrypto,
      );

      setState(() {
        if (cachedOrders.isNotEmpty) {
          _orders = cachedOrders.map((json) => P2POrder.fromJson(json)).toList();
          _error = 'Using cached data';
        } else {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyTrades() async {
    try {
      final trades = await p2pService.getTrades();
      setState(() {
        _myTrades = trades;
      });
    } catch (e) {
      debugPrint('Error loading trades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false, // Bottom handled by _buildBottomTabs SafeArea
        child: Column(
          children: [
            _buildTopNavigation(),
            _buildBuySellToggle(),
            _buildFilterBar(),
            Expanded(
              child: _buildContent(),
            ),
            _buildBottomTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_bottomTabIndex) {
      case 1:
        return _buildOrdersTab();
      case 2:
        return _buildAdsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildP2PTab();
    }
  }

  Widget _buildP2PTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('No orders available', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Try changing filters or check back later',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _VendorCard(
          order: _orders[index],
          isBuy: _isBuy,
          fiat: _selectedFiat,
          onTrade: () => _showTradeDialog(_orders[index]),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder(
      future: p2pService.getTrades(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trades = snapshot.data ?? [];
        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('No trades yet', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final trade = trades[index];
            return _TradeCard(trade: trade);
          },
        );
      },
    );
  }

  Widget _buildAdsTab() {
    return FutureBuilder(
      future: p2pService.getMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('No ads posted', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showPostAdDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Post Ad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showPostAdDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Post Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _MyAdCard(order: order);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileStats(),
          const SizedBox(height: 24),
          _buildPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('P2P Statistics', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Total Trades', '0'),
              _buildStat('Completion', '0%'),
              _buildStat('Rating', '0.0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Methods', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () => _showAddPaymentMethodDialog(),
                icon: Icon(Icons.add, size: 18, color: AppColors.primary),
                label: Text('Add', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: p2pService.getPaymentMethods(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final methods = snapshot.data ?? [];
              if (methods.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No payment methods added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Column(
                children: methods.map((method) => ListTile(
                  leading: Icon(Icons.account_balance, color: AppColors.primary),
                  title: Text(method.name, style: TextStyle(color: textColor)),
                  subtitle: Text(method.type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  trailing: method.isDefault
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Default', style: TextStyle(color: AppColors.primary, fontSize: 10)),
                        )
                      : null,
                )).toList(),
              );
            },
          ),
        ],
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
          Text(
            'P2P',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSelector('Fiat', _fiatOptions, (v) {
              setState(() => _selectedFiat = v);
              _loadOrders();
            }),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _isBuy = true);
              _loadOrders();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _isBuy ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Buy',
                style: TextStyle(
                  color: _isBuy ? (isDark ? Colors.black : Colors.white) : inactiveColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _isBuy = false);
              _loadOrders();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: !_isBuy ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sell',
                style: TextStyle(
                  color: !_isBuy ? (isDark ? Colors.black : Colors.white) : inactiveColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers, color: isDark ? Colors.teal : Colors.teal[700], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Flexible(
            flex: 0,
            child: GestureDetector(
              onTap: () => _showSelector('Crypto', _cryptoOptions, (v) {
                setState(() => _selectedCrypto = v);
                _loadOrders();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CryptoIcon(symbol: _selectedCrypto, size: 16),
                    const SizedBox(width: 6),
                    Text(_selectedCrypto, style: TextStyle(color: textColor, fontSize: 13)),
                    Icon(Icons.arrow_drop_down, color: subtextColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Amount', style: TextStyle(color: subtextColor, fontSize: 13)),
                  Icon(Icons.arrow_drop_down, color: subtextColor, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showSelector('Payment', _paymentOptions, (v) {
                setState(() => _selectedPayment = v);
                _loadOrders();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedPayment,
                        style: TextStyle(color: subtextColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: subtextColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.filter_list, color: subtextColor, size: 18),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[300]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomTab(
              icon: Icons.swap_horiz,
              label: 'P2P',
              isSelected: _bottomTabIndex == 0,
              onTap: () => setState(() => _bottomTabIndex = 0),
            ),
            _BottomTab(
              icon: Icons.receipt_long,
              label: 'Orders',
              isSelected: _bottomTabIndex == 1,
              onTap: () => setState(() => _bottomTabIndex = 1),
            ),
            _BottomTab(
              icon: Icons.campaign,
              label: 'Ads',
              isSelected: _bottomTabIndex == 2,
              onTap: () => setState(() => _bottomTabIndex = 2),
            ),
            _BottomTab(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: _bottomTabIndex == 3,
              onTap: () => setState(() => _bottomTabIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelector(String title, List<String> options, Function(String) onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select $title', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: TextStyle(color: textColor)),
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

  void _showTradeDialog(P2POrder order) {
    final amountController = TextEditingController();
    bool isLoading = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[600] : Colors.grey[700];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: modalBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        order.merchantName?[0] ?? '?',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.merchantName ?? 'Merchant', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        Text(
                          '${order.merchantTrades ?? 0} Orders | ${order.merchantRating?.toStringAsFixed(0) ?? '0'}%',
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: subtextColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price', style: TextStyle(color: subtextColor)),
                  Text(
                    '${_getCurrencySymbol(_selectedFiat)} ${order.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('I want to ${_isBuy ? 'pay' : 'receive'}', style: TextStyle(color: subtextColor, fontSize: 12)),
                        Text(
                          'Limit: ${order.minAmount.toStringAsFixed(0)} - ${order.maxAmount.toStringAsFixed(0)} $_selectedFiat',
                          style: TextStyle(color: subtextColor, fontSize: 11),
                        ),
                      ],
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 20),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400]),
                        border: InputBorder.none,
                        suffixText: _selectedFiat,
                        suffixStyle: TextStyle(color: subtextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Payment Methods', style: TextStyle(color: subtextColor, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: order.paymentMethods.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p, style: TextStyle(color: textColor, fontSize: 12)),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final amountText = amountController.text.trim();
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an amount')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);
                    if (amount == null || amount < order.minAmount || amount > order.maxAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Amount must be between ${order.minAmount} and ${order.maxAmount}'),
                        ),
                      );
                      return;
                    }

                    setModalState(() => isLoading = true);

                    try {
                      await p2pService.initiateTrade(
                        orderId: order.id,
                        amount: amount,
                        paymentMethodId: order.paymentMethods.first,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Trade initiated with ${order.merchantName}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isBuy ? 'Buy $_selectedCrypto' : 'Sell $_selectedCrypto',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostAdDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post P2P Ad', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Payment Method', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Text('Coming soon...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }
}

class _VendorCard extends StatelessWidget {
  final P2POrder order;
  final bool isBuy;
  final String fiat;
  final VoidCallback onTrade;

  const _VendorCard({
    required this.order,
    required this.isBuy,
    required this.fiat,
    required this.onTrade,
  });

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[600] : Colors.grey[700];
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    order.merchantName?[0] ?? '?',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.merchantName ?? 'Merchant',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: subtextColor, size: 12),
                        const SizedBox(width: 4),
                        Text('15m', style: TextStyle(color: subtextColor, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.merchantTrades ?? 0} Orders (${order.merchantRating?.toStringAsFixed(0) ?? '0'}%)',
                    style: TextStyle(color: subtextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_getCurrencySymbol(fiat)} ${order.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: isBuy ? AppColors.tradingBuy : AppColors.tradingSell,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Limits', style: TextStyle(color: subtextColor, fontSize: 11)),
                  Text(
                    '${order.minAmount.toStringAsFixed(2)} - ${order.maxAmount.toStringAsFixed(2)} $fiat',
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available', style: TextStyle(color: subtextColor, fontSize: 11)),
                  Text(
                    '${order.amount.toStringAsFixed(4)} ${order.currency}',
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...order.paymentMethods.take(2).map((p) => Container(
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
                    Text(p, style: TextStyle(color: subtextColor, fontSize: 11)),
                  ],
                ),
              )),
              const Spacer(),
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

class _TradeCard extends StatelessWidget {
  final P2PTrade trade;

  const _TradeCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    Color statusColor;
    switch (trade.status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'disputed':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${trade.type.toUpperCase()} ${trade.currency}',
                style: TextStyle(
                  color: trade.type == 'buy' ? AppColors.tradingBuy : AppColors.tradingSell,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trade.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount: ${trade.amount} ${trade.currency}', style: TextStyle(color: subtextColor, fontSize: 12)),
              Text('Total: ${trade.total} ${trade.fiatCurrency}', style: TextStyle(color: subtextColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyAdCard extends StatelessWidget {
  final P2POrder order;

  const _MyAdCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.type.toUpperCase()} ${order.currency}',
                style: TextStyle(
                  color: order.type == 'buy' ? AppColors.tradingBuy : AppColors.tradingSell,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: order.status == 'active'
                      ? AppColors.success.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: order.status == 'active' ? AppColors.success : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Price: ${order.price} ${order.fiatCurrency}',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: ${order.amount} ${order.currency}',
            style: TextStyle(color: subtextColor, fontSize: 12),
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
  final VoidCallback onTap;

  const _BottomTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[500];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? selectedColor : unselectedColor, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? selectedColor : unselectedColor, fontSize: 11)),
        ],
      ),
    );
  }
}
