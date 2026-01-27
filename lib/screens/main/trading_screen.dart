import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/widgets.dart';
import '../../navigation/app_router.dart';
import '../../theme/colors.dart';
import '../../services/crypto_service.dart';
import '../../providers/balance_provider.dart';

/// Professional Bybit-style Spot Trading Screen
class TradingScreen extends StatefulWidget {
  final String symbol;
  final String baseAsset;

  const TradingScreen({
    super.key,
    this.symbol = 'BTCUSDT',
    this.baseAsset = 'BTC',
  });

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> with TickerProviderStateMixin {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();

  // Top navigation
  int _topTabIndex = 1; // Spot selected
  final List<String> _topTabs = ['Convert', 'Spot'];

  // Sub tabs - removed Overview/Data/Feed as they were placeholder
  int _subTabIndex = 0; // Chart only
  final List<String> _subTabs = ['Chart'];

  // Order book tabs
  int _orderBookTabIndex = 0; // Order Book
  final List<String> _orderBookTabs = ['Order Book', 'Trades'];

  // Timeframe
  String _interval = '15';
  final List<String> _intervals = ['1', '5', '15', '60', '240', 'D', 'W'];
  final Map<String, String> _intervalLabels = {
    '1': '1m', '5': '5m', '15': '15m', '60': '1h', '240': '4h', 'D': '1D', 'W': '1W'
  };

  // Trading pair
  late String _symbol;
  late String _baseAsset;
  String _quoteAsset = 'USDT';

  // Market data
  double _lastPrice = 0;
  double _prevPrice = 0;
  double _price24hPcnt = 0;
  double _highPrice24h = 0;
  double _lowPrice24h = 0;
  double _turnover24h = 0;

  // Candlestick data
  List<CandleData> _candles = [];

  // Order book
  List<List<double>> _asks = [];
  List<List<double>> _bids = [];

  // Recent trades
  List<TradeData> _recentTrades = [];

  // All available symbols from Bybit
  List<SymbolInfo> _allSymbols = [];
  List<SymbolInfo> _filteredSymbols = [];
  Set<String> _favoriteSymbols = {};
  final _searchController = TextEditingController();

  // UI state
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _showAnnouncement = true;
  bool _showLineChart = false; // false = candlestick (default), true = line chart

  Timer? _refreshTimer;
  Timer? _candleTimer;

  // Convert section state
  final CryptoService _cryptoService = CryptoService();
  final TextEditingController _fromAmountController = TextEditingController();
  String _fromCrypto = 'USDT';
  String _toCrypto = 'BTC';
  double _fromPrice = 1.0;
  double _toPrice = 91000.0;
  double _toAmount = 0.0;
  bool _isConverting = false;
  double _availableBalance = 0.0;

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
    // Initialize from widget parameters
    _symbol = widget.symbol;
    _baseAsset = widget.baseAsset;
    _loadAllData();
    // Fast refresh for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshLiveData());
    _candleTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchKlines());
  }

  @override
  void didUpdateWidget(TradingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle symbol change from navigation
    if (oldWidget.symbol != widget.symbol) {
      setState(() {
        _symbol = widget.symbol;
        _baseAsset = widget.baseAsset;
        _candles = [];
        _asks = [];
        _bids = [];
        _recentTrades = [];
      });
      _fetchTicker();
      _fetchKlines();
      _fetchOrderBook();
      _fetchRecentTrades();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _candleTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAllSymbols(),
      _fetchTicker(),
      _fetchKlines(),
      _fetchOrderBook(),
      _fetchRecentTrades(),
    ]);
    _loadConvertBalance();
    setState(() => _isLoading = false);
  }

  void _loadConvertBalance() {
    final balanceProvider = context.read<BalanceProvider>();
    final asset = balanceProvider.fundingAssets
        .where((a) => a.symbol.toUpperCase() == _fromCrypto.toUpperCase())
        .firstOrNull;
    setState(() {
      _availableBalance = asset?.available ?? 0.0;
    });
  }

  void _setMaxConvertAmount() {
    if (_availableBalance > 0) {
      _fromAmountController.text = _availableBalance.toString();
      _calculateConvertAmount();
    }
  }

  Future<void> _fetchAllSymbols() async {
    try {
      final response = await _dio.get(
        'https://api.bybit.com/v5/market/tickers',
        queryParameters: {'category': 'spot'},
      );

      if (response.data['retCode'] == 0) {
        final List<dynamic> list = response.data['result']['list'];
        final symbols = <SymbolInfo>[];

        for (var item in list) {
          final symbol = item['symbol'] as String;
          if (symbol.endsWith('USDT')) {
            final base = symbol.replaceAll('USDT', '');
            symbols.add(SymbolInfo(
              symbol: symbol,
              baseAsset: base,
              quoteAsset: 'USDT',
              lastPrice: double.tryParse(item['lastPrice'] ?? '0') ?? 0,
              price24hPcnt: (double.tryParse(item['price24hPcnt'] ?? '0') ?? 0) * 100,
              volume24h: double.tryParse(item['volume24h'] ?? '0') ?? 0,
            ));
          }
        }

        symbols.sort((a, b) => b.volume24h.compareTo(a.volume24h));

        if (mounted) {
          setState(() {
            _allSymbols = symbols;
            _filteredSymbols = symbols;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching symbols: $e');
    }
  }

  Future<void> _fetchTicker() async {
    try {
      final response = await _dio.get(
        'https://api.bybit.com/v5/market/tickers',
        queryParameters: {'category': 'spot', 'symbol': _symbol},
      );

      if (response.data['retCode'] == 0 && mounted) {
        final item = response.data['result']['list'][0];
        setState(() {
          _prevPrice = _lastPrice;
          _lastPrice = double.tryParse(item['lastPrice'] ?? '0') ?? 0;
          _price24hPcnt = (double.tryParse(item['price24hPcnt'] ?? '0') ?? 0) * 100;
          _highPrice24h = double.tryParse(item['highPrice24h'] ?? '0') ?? 0;
          _lowPrice24h = double.tryParse(item['lowPrice24h'] ?? '0') ?? 0;
          _turnover24h = double.tryParse(item['turnover24h'] ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ticker: $e');
    }
  }

  Future<void> _fetchKlines() async {
    try {
      final response = await _dio.get(
        'https://api.bybit.com/v5/market/kline',
        queryParameters: {
          'category': 'spot',
          'symbol': _symbol,
          'interval': _interval,
          'limit': 100,
        },
      );

      if (response.data['retCode'] == 0 && mounted) {
        final List<dynamic> list = response.data['result']['list'];
        setState(() {
          _candles = list.reversed.map((k) => CandleData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(k[0])),
            open: double.parse(k[1]),
            high: double.parse(k[2]),
            low: double.parse(k[3]),
            close: double.parse(k[4]),
            volume: double.parse(k[5]),
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching klines: $e');
    }
  }

  Future<void> _fetchOrderBook() async {
    try {
      final response = await _dio.get(
        'https://api.bybit.com/v5/market/orderbook',
        queryParameters: {'category': 'spot', 'symbol': _symbol, 'limit': 15},
      );

      if (response.data['retCode'] == 0 && mounted) {
        final result = response.data['result'];
        setState(() {
          _asks = (result['a'] as List).map<List<double>>((e) =>
            [double.parse(e[0]), double.parse(e[1])]).toList();
          _bids = (result['b'] as List).map<List<double>>((e) =>
            [double.parse(e[0]), double.parse(e[1])]).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching orderbook: $e');
    }
  }

  Future<void> _fetchRecentTrades() async {
    try {
      final response = await _dio.get(
        'https://api.bybit.com/v5/market/recent-trade',
        queryParameters: {'category': 'spot', 'symbol': _symbol, 'limit': 20},
      );

      if (response.data['retCode'] == 0 && mounted) {
        final List<dynamic> list = response.data['result']['list'];
        setState(() {
          _recentTrades = list.map((t) => TradeData(
            price: double.parse(t['price']),
            qty: double.parse(t['size']),
            time: DateTime.fromMillisecondsSinceEpoch(int.parse(t['time'])),
            isBuy: t['side'] == 'Buy',
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching trades: $e');
    }
  }

  Future<void> _refreshLiveData() async {
    await Future.wait([
      _fetchTicker(),
      _fetchOrderBook(),
    ]);
    // Update last candle
    if (_candles.isNotEmpty && _lastPrice > 0) {
      final last = _candles.last;
      setState(() {
        _candles[_candles.length - 1] = CandleData(
          timestamp: last.timestamp,
          open: last.open,
          high: max(last.high, _lastPrice),
          low: min(last.low, _lastPrice),
          close: _lastPrice,
          volume: last.volume,
        );
      });
    }
  }

  void _changeSymbol(SymbolInfo info) {
    setState(() {
      _symbol = info.symbol;
      _baseAsset = info.baseAsset;
      _quoteAsset = info.quoteAsset;
      _candles = [];
      _asks = [];
      _bids = [];
      _recentTrades = [];
    });
    Navigator.pop(context);
    _fetchTicker();
    _fetchKlines();
    _fetchOrderBook();
    _fetchRecentTrades();
  }

  void _changeInterval(String interval) {
    setState(() => _interval = interval);
    _fetchKlines();
  }

  void _filterSymbols(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSymbols = _allSymbols;
      } else {
        _filteredSymbols = _allSymbols.where((s) =>
          s.baseAsset.toLowerCase().contains(query.toLowerCase()) ||
          s.symbol.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _toggleFavorite(String symbol) {
    setState(() {
      if (_favoriteSymbols.contains(symbol)) {
        _favoriteSymbols.remove(symbol);
      } else {
        _favoriteSymbols.add(symbol);
      }
    });
  }

  String _formatPrice(double price) {
    if (price >= 10000) return price.toStringAsFixed(2);
    if (price >= 100) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    if (price >= 0.0001) return price.toStringAsFixed(6);
    return price.toStringAsFixed(8);
  }

  String _formatVolume(double vol) {
    if (vol >= 1e9) return '${(vol / 1e9).toStringAsFixed(2)}B';
    if (vol >= 1e6) return '${(vol / 1e6).toStringAsFixed(2)}M';
    if (vol >= 1e3) return '${(vol / 1e3).toStringAsFixed(2)}K';
    return vol.toStringAsFixed(2);
  }

  String _formatQty(double qty) {
    if (qty >= 1000) return '${(qty / 1000).toStringAsFixed(3)}K';
    return qty.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final borderColor = isDark ? const Color(0xFF151515) : const Color(0xFFE0E0E0);
    final isPositive = _price24hPcnt >= 0;
    final priceColor = isPositive ? const Color(0xFF00C853) : const Color(0xFFFF5252);
    final priceDirection = _lastPrice >= _prevPrice;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate contained width (max 460px to match other sections)
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: bgColor,
      // Sticky trade buttons at absolute bottom (only for Spot view)
      bottomSheet: _topTabIndex == 1 && !_isLoading ? _buildStickyTradeButtons() : null,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : Center(
                child: Container(
                  width: contentWidth,
                  margin: screenWidth > 500
                      ? const EdgeInsets.symmetric(horizontal: 12)
                      : EdgeInsets.zero,
                  decoration: screenWidth > 500
                      ? BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor, width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        )
                      : BoxDecoration(color: bgColor),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth > 500 ? 16 : 0),
                    child: Column(
                      children: [
                        _buildTopNavigation(),
                        // Show Spot or Convert content with slide transition
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              // Determine slide direction based on tab index
                              final isConvert = child.key == const ValueKey('convert');
                              final slideOffset = isConvert
                                  ? Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                                  : Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);

                              return SlideTransition(
                                position: slideOffset.animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                )),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _topTabIndex == 1
                                ? _buildSpotView(priceColor, isPositive, priceDirection)
                                : _buildConvertView(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00C853)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Loading market data...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  // SPOT TRADING VIEW (extracted for animation)
  Widget _buildSpotView(Color priceColor, bool isPositive, bool priceDirection) {
    // Bottom padding to account for sticky buttons (bottomSheet) + bottom nav bar
    final bottomPadding = 65 + MediaQuery.of(context).padding.bottom + 70;

    return Column(
      key: const ValueKey('spot'),
      children: [
        _buildPairHeader(priceColor, isPositive),
        _buildSubTabs(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _buildPriceSection(priceColor, isPositive, priceDirection),
                  if (_showAnnouncement) _buildAnnouncement(),
                  _buildTimeframeSelector(),
                  _buildMAIndicators(),
                  // Chart container with subtle border
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
                    ),
                    child: SizedBox(height: 200, child: _buildCandlestickChart()),
                  ),
                  _buildVolumeSection(),
                  const SizedBox(height: 8),
                  _buildOrderBookSection(),
                  // Extra padding at bottom to prevent content being hidden behind sticky buttons
                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final elementBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Back arrow to go home
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: elementBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.arrow_back, color: textColor, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          // Toggle between Spot and Convert (inline, no navigation)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: elementBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: List.generate(_topTabs.length, (i) {
                final isSelected = _topTabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _topTabIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tradingBuy : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _topTabs[i],
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[500] : const Color(0xFF555555)),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPairHeader(Color priceColor, bool isPositive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elementBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: elementBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CryptoIcon(symbol: _baseAsset, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_baseAsset/$_quoteAsset',
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: priceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${_price24hPcnt.toStringAsFixed(2)}%',
              style: TextStyle(color: priceColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF7A600), width: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('MM', style: TextStyle(color: Color(0xFFF7A600), fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          Text('0.00%', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
          const SizedBox(width: 8),
          Icon(Icons.tune, color: Colors.grey[500], size: 16),
          const SizedBox(width: 6),
          Icon(Icons.copy_outlined, color: Colors.grey[500], size: 16),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 0.5)),
      ),
      child: Row(
        children: [
          ...List.generate(_subTabs.length, (i) {
            final isSelected = _subTabIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _subTabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _subTabs[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Icon(Icons.auto_awesome, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            child: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? const Color(0xFFF7A600) : Colors.grey[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.notifications_outlined, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Icon(Icons.ios_share_outlined, color: Colors.grey[600], size: 16),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Color priceColor, bool isPositive, bool priceUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(_lastPrice),
                    style: TextStyle(
                      color: priceUp ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    priceUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: priceUp ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                    size: 18,
                  ),
                ],
              ),
              Text(
                '≈${_lastPrice.toStringAsFixed(2)} USD',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatRow('24h High', _formatPrice(_highPrice24h)),
              _buildStatRow('24h Low', _formatPrice(_lowPrice24h)),
              _buildStatRow('24h Turnover', _formatVolume(_turnover24h)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildAnnouncement() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, color: Colors.grey[500], size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Alpha Trading Fiesta Season 5 — Win from 600,000 USDT',
              style: TextStyle(color: Colors.grey[400], fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showAnnouncement = false),
            child: Icon(Icons.close, color: Colors.grey[600], size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Time', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(width: 6),
          ..._intervals.map((tf) {
            final isSelected = _interval == tf;
            return GestureDetector(
              onTap: () => _changeInterval(tf),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF333333) : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _intervalLabels[tf] ?? tf,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          Text('More', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 12),
          Container(width: 1, height: 10, color: Colors.grey[800], margin: const EdgeInsets.symmetric(horizontal: 6)),
          Text('Depth', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const Spacer(),
          Icon(Icons.edit_outlined, color: Colors.grey[600], size: 14),
          const SizedBox(width: 8),
          Icon(Icons.remove_red_eye_outlined, color: Colors.grey[600], size: 14),
        ],
      ),
    );
  }

  Widget _buildMAIndicators() {
    if (_candles.isEmpty) return const SizedBox.shrink();

    double calcMA(int period) {
      if (_candles.length < period) return 0.0;
      final slice = _candles.sublist(_candles.length - period);
      return slice.map((c) => c.close).reduce((a, b) => a + b) / period;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          _buildMABadge('MA7', calcMA(7), const Color(0xFFF7A600)),
          const SizedBox(width: 8),
          _buildMABadge('MA14', calcMA(14), const Color(0xFF9C27B0)),
          const SizedBox(width: 8),
          _buildMABadge('MA28', calcMA(28), const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildMABadge(String label, double value, Color color) {
    return Row(
      children: [
        Text('$label:', style: TextStyle(color: color, fontSize: 8)),
        const SizedBox(width: 2),
        Text(_formatPrice(value), style: TextStyle(color: color, fontSize: 8, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildCandlestickChart() {
    if (_candles.isEmpty) {
      return Center(child: Text('Loading chart...', style: TextStyle(color: Colors.grey[600])));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Chart scrolling/panning is handled by the painter
        },
        child: _showLineChart
            ? CustomPaint(
                size: Size.infinite,
                painter: BybitLineChartPainter(candles: _candles, currentPrice: _lastPrice),
              )
            : CustomPaint(
                size: Size.infinite,
                painter: BybitCandlestickPainter(candles: _candles, currentPrice: _lastPrice),
              ),
      ),
    );
  }

  Widget _buildVolumeSection() {
    if (_candles.isEmpty) return const SizedBox(height: 40);

    double calcVolMA(int period) {
      if (_candles.length < period) return 0.0;
      final slice = _candles.sublist(_candles.length - period);
      return slice.map((c) => c.volume).reduce((a, b) => a + b) / period;
    }

    final double lastVol = _candles.isNotEmpty ? _candles.last.volume : 0.0;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('VOLUME: ${_formatVolume(lastVol)}', style: const TextStyle(color: Color(0xFFF7A600), fontSize: 8)),
              const SizedBox(width: 8),
              Text('MA5: ${_formatVolume(calcVolMA(5))}', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
              const SizedBox(width: 8),
              Text('MA10: ${_formatVolume(calcVolMA(10))}', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
            ],
          ),
          const SizedBox(height: 2),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: BybitVolumePainter(candles: _candles),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBookSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Tabs
          Row(
            children: [
              ...List.generate(_orderBookTabs.length, (i) {
                final isSelected = _orderBookTabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _orderBookTabIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _orderBookTabs[i],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Icon(Icons.bar_chart, color: Colors.grey[600], size: 16),
            ],
          ),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          const SizedBox(height: 8),
          // Content
          _orderBookTabIndex == 0 ? _buildOrderBook() : _buildRecentTrades(),
        ],
      ),
    );
  }

  Widget _buildOrderBook() {
    // Calculate max qty for depth visualization
    double maxQty = 0;
    for (var a in _asks) maxQty = max(maxQty, a[1]);
    for (var b in _bids) maxQty = max(maxQty, b[1]);

    // Calculate bid/ask percentages
    double totalBids = _bids.fold(0.0, (sum, b) => sum + b[1]);
    double totalAsks = _asks.fold(0.0, (sum, a) => sum + a[1]);
    double total = totalBids + totalAsks;
    double bidPct = total > 0 ? (totalBids / total * 100) : 50;
    double askPct = total > 0 ? (totalAsks / total * 100) : 50;

    return Column(
      children: [
        // Bid/Ask bar
        Container(
          height: 20,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('B ${bidPct.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF00C853), fontSize: 9)),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: bidPct.round(),
                child: Container(height: 4, color: const Color(0xFF00C853)),
              ),
              Expanded(
                flex: askPct.round(),
                child: Container(height: 4, color: const Color(0xFFFF5252)),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('${askPct.toStringAsFixed(0)}% S', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Header
        Row(
          children: [
            Expanded(child: Text('Qty (${_baseAsset})', style: TextStyle(color: Colors.grey[600], fontSize: 9))),
            Expanded(child: Center(child: Text('Price (USDT)', style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Qty (${_baseAsset})', style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
          ],
        ),
        const SizedBox(height: 4),
        // Order book rows
        ...List.generate(min(_bids.length, 10), (i) {
          final bid = i < _bids.length ? _bids[i] : [0.0, 0.0];
          final ask = i < _asks.length ? _asks[i] : [0.0, 0.0];
          return _buildOrderBookRow(bid, ask, maxQty);
        }),
      ],
    );
  }

  Widget _buildOrderBookRow(List<double> bid, List<double> ask, double maxQty) {
    return Container(
      height: 22,
      child: Row(
        children: [
          // Bid side
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: maxQty > 0 ? (bid[1] / maxQty).clamp(0, 1) : 0,
                      child: Container(color: const Color(0xFF00C853).withOpacity(0.15)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(_formatQty(bid[1]), style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                      const Spacer(),
                      Text(_formatPrice(bid[0]), style: const TextStyle(color: Color(0xFF00C853), fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ask side
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: maxQty > 0 ? (ask[1] / maxQty).clamp(0, 1) : 0,
                      child: Container(color: const Color(0xFFFF5252).withOpacity(0.15)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(_formatPrice(ask[0]), style: const TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontFamily: 'monospace')),
                      const Spacer(),
                      Text(_formatQty(ask[1]), style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrades() {
    return Column(
      children: [
        // Header
        Row(
          children: [
            Expanded(child: Text('Price (USDT)', style: TextStyle(color: Colors.grey[600], fontSize: 9))),
            Expanded(child: Center(child: Text('Qty (${_baseAsset})', style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Time', style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
          ],
        ),
        const SizedBox(height: 4),
        ...List.generate(min(_recentTrades.length, 15), (i) {
          final trade = _recentTrades[i];
          return Container(
            height: 22,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatPrice(trade.price),
                    style: TextStyle(
                      color: trade.isBuy ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatQty(trade.qty),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${trade.time.hour.toString().padLeft(2, '0')}:${trade.time.minute.toString().padLeft(2, '0')}:${trade.time.second.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStickyTradeButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[300]!;
    final elementBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);

    // Vibrant colors
    const vibrantGreen = Color(0xFF00E676);
    const vibrantRed = Color(0xFFFF1744);

    // Bottom padding: just safe area + small padding (bottomSheet handles positioning)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 8;

    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Line chart toggle
          GestureDetector(
            onTap: () => setState(() => _showLineChart = true),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _showLineChart ? vibrantGreen.withOpacity(0.15) : elementBg,
                borderRadius: BorderRadius.circular(6),
                border: _showLineChart ? Border.all(color: vibrantGreen, width: 1) : null,
              ),
              child: Icon(Icons.show_chart, color: _showLineChart ? vibrantGreen : Colors.grey[500], size: 16),
            ),
          ),
          // Candlestick chart toggle
          GestureDetector(
            onTap: () => setState(() => _showLineChart = false),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: !_showLineChart ? vibrantGreen.withOpacity(0.15) : elementBg,
                borderRadius: BorderRadius.circular(6),
                border: !_showLineChart ? Border.all(color: vibrantGreen, width: 1) : null,
              ),
              child: Icon(Icons.candlestick_chart, color: !_showLineChart ? vibrantGreen : Colors.grey[500], size: 16),
            ),
          ),
          // Buy button - small, vibrant green with glow
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeSheet(true),
              child: Container(
                height: 36,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: vibrantGreen.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Buy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ),
          // Sell button - small, vibrant red with glow
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeSheet(false),
              child: Container(
                height: 36,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: vibrantRed.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Sell', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MODALS ==========

  void _showPairSelector() {
    _searchController.clear();
    _filteredSymbols = _allSymbols;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Select Market', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ],
                ),
              ),
              // Search bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search coin name or symbol',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (q) {
                          _filterSymbols(q);
                          setModalState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Colors.grey, fontSize: 11))),
                    const Expanded(flex: 2, child: Text('Last Price', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.right)),
                    const Expanded(flex: 2, child: Text('24h Chg.', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.right)),
                    const SizedBox(width: 30),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSymbols.length,
                  itemBuilder: (context, i) {
                    final info = _filteredSymbols[i];
                    final isSelected = info.symbol == _symbol;
                    final isUp = info.price24hPcnt >= 0;
                    final isFav = _favoriteSymbols.contains(info.symbol);

                    return GestureDetector(
                      onTap: () => _changeSymbol(info),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            CryptoIcon(symbol: info.baseAsset, size: 32),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.baseAsset,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFF7A600) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '/${info.quoteAsset}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatPrice(info.lastPrice),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isUp ? '+' : ''}${info.price24hPcnt.toStringAsFixed(2)}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _toggleFavorite(info.symbol);
                                setModalState(() {});
                              },
                              child: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color: isFav ? const Color(0xFFF7A600) : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTradeSheet(bool isBuy) {
    // Navigate to full-screen order entry screen (outside ShellRoute)
    context.push('/order-entry', extra: {
      'symbol': _symbol,
      'baseAsset': _baseAsset,
      'quoteAsset': _quoteAsset,
      'isBuy': isBuy,
      'currentPrice': _lastPrice,
    });
  }

  void _showConvertSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Convert', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildConvertField('From', 'USDT', '0.00'),
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Color(0xFFF7A600), shape: BoxShape.circle),
                    child: const Icon(Icons.swap_vert, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  _buildConvertField('To', 'BTC', '0.00'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conversion successful!'), backgroundColor: Color(0xFF00C853), behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tradingBuy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Convert', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertField(String label, String asset, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: amount,
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CryptoIcon(symbol: asset, size: 24),
                    const SizedBox(width: 8),
                    Text(asset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ========== CONVERT VIEW ==========

  Widget _buildConvertView() {
    return SingleChildScrollView(
      key: const ValueKey('convert'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tradingBuy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: AppColors.tradingBuy, size: 16),
                    const SizedBox(width: 4),
                    Text('Instant', style: TextStyle(color: AppColors.tradingBuy, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.history, color: Colors.grey[600], size: 20),
            ],
          ),

          const SizedBox(height: 24),

          // From Section
          _buildConvertFromSection(),

          const SizedBox(height: 8),

          // Swap Button
          Center(
            child: GestureDetector(
              onTap: _swapConvertCurrencies,
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
          _buildConvertToSection(),

          const SizedBox(height: 24),

          // Quote Button (Bybit style - smaller) - Green color
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isConverting ? null : _showQuoteConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tradingBuy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 0,
              ),
              child: const Text('Quote', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 24),

          // Info Section (Rate, Fee, Slippage) - matching standalone Convert screen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildConvertInfoRow('Rate', '1 $_fromCrypto = ${(_fromPrice / _toPrice).toStringAsFixed(8)} $_toCrypto'),
                const SizedBox(height: 8),
                _buildConvertInfoRow('Fee', '0 USDT'),
                const SizedBox(height: 8),
                _buildConvertInfoRow('Slippage', '0.5%'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // One-Click Buy link
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('One-Click Buy', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.grey[500], size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildConvertFromSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('From', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Row(
                children: [
                  Text('Available: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    _availableBalance > 0 ? _availableBalance.toStringAsFixed(8) : '0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _setMaxConvertAmount,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tradingBuy.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Max',
                        style: TextStyle(
                          color: AppColors.tradingBuy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showConvertCryptoSelector(true),
                child: Row(
                  children: [
                    CryptoIcon(symbol: _fromCrypto, size: 28),
                    const SizedBox(width: 8),
                    Text(_fromCrypto, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 20),
                  ],
                ),
              ),
              const Spacer(),
              Expanded(
                child: TextField(
                  controller: _fromAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _calculateConvertAmount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvertToSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showConvertCryptoSelector(false),
                child: Row(
                  children: [
                    CryptoIcon(symbol: _toCrypto, size: 28),
                    const SizedBox(width: 8),
                    Text(_toCrypto, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 20),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _toAmount > 0 ? _toAmount.toStringAsFixed(8) : '--',
                style: TextStyle(color: Colors.grey[400], fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvertInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildConvertInfoRow('Rate', '1 $_fromCrypto = ${(_fromPrice / _toPrice).toStringAsFixed(8)} $_toCrypto'),
          const SizedBox(height: 8),
          _buildConvertInfoRow('Fee', '0 USDT'),
          const SizedBox(height: 8),
          _buildConvertInfoRow('Slippage', '0.5%'),
        ],
      ),
    );
  }

  void _calculateConvertAmount() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    final fromValueUsd = fromAmount * _fromPrice;
    final toAmountCalc = _toPrice > 0 ? fromValueUsd / _toPrice : 0.0;
    setState(() => _toAmount = toAmountCalc);
  }

  void _swapConvertCurrencies() {
    setState(() {
      final tempCrypto = _fromCrypto;
      final tempPrice = _fromPrice;
      _fromCrypto = _toCrypto;
      _fromPrice = _toPrice;
      _toCrypto = tempCrypto;
      _toPrice = tempPrice;
    });
    // Reload balance for the new "From" currency
    _loadConvertBalance();
    _calculateConvertAmount();
  }

  Future<void> _handleConvert() async {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    if (fromAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter an amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isConverting = true);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _isConverting = false);

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
                  color: const Color(0xFF00C853).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF00C853), size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Conversion Successful', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'You converted $fromAmount $_fromCrypto to ${_toAmount.toStringAsFixed(8)} $_toCrypto',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: TextStyle(color: const Color(0xFFF7A600))),
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

    // Balance validation
    if (fromAmount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Available: $_availableBalance $_fromCrypto'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Calculate conversion details
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
                child: const Icon(Icons.arrow_downward, color: Color(0xFF00C853), size: 20),
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
                          style: const TextStyle(color: Color(0xFF00C853), fontSize: 18, fontWeight: FontWeight.w600),
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
                      child: const Text('Confirm', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
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
    setState(() => _isConverting = true);

    // Simulate conversion processing
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _isConverting = false);

    if (mounted) {
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
                  child: const Text('Done', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showConvertCryptoSelector(bool isFrom) {
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
              onTap: () async {
                Navigator.pop(context);
                final price = await _cryptoService.getPrice(crypto['symbol']);
                setState(() {
                  if (isFrom) {
                    _fromCrypto = crypto['symbol'];
                    _fromPrice = price ?? (crypto['symbol'] == 'USDT' ? 1.0 : 1000.0);
                  } else {
                    _toCrypto = crypto['symbol'];
                    _toPrice = price ?? (crypto['symbol'] == 'USDT' ? 1.0 : 1000.0);
                  }
                });
                // Reload balance when "From" crypto changes
                if (isFrom) {
                  _loadConvertBalance();
                }
                _calculateConvertAmount();
              },
            ))),
          ],
        ),
      ),
    );
  }
}

// ========== DATA CLASSES ==========

class SymbolInfo {
  final String symbol, baseAsset, quoteAsset;
  final double lastPrice, price24hPcnt, volume24h;

  SymbolInfo({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.lastPrice,
    required this.price24hPcnt,
    required this.volume24h,
  });
}

class CandleData {
  final DateTime timestamp;
  final double open, high, low, close, volume;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class TradeData {
  final double price, qty;
  final DateTime time;
  final bool isBuy;

  TradeData({required this.price, required this.qty, required this.time, required this.isBuy});
}

// ========== CHART PAINTERS ==========

class BybitCandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double currentPrice;

  BybitCandlestickPainter({required this.candles, required this.currentPrice});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const rightMargin = 45.0;
    final chartWidth = size.width - rightMargin;

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (final c in candles) {
      minPrice = min(minPrice, c.low);
      maxPrice = max(maxPrice, c.high);
    }
    final padding = (maxPrice - minPrice) * 0.08;
    minPrice -= padding;
    maxPrice += padding;
    final range = maxPrice - minPrice;
    if (range == 0) return;

    final candleWidth = chartWidth / candles.length;
    final bodyWidth = candleWidth * 0.75;

    final gridPaint = Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final price = maxPrice - (range * i / 4);
      _drawText(canvas, _formatPriceLabel(price), Offset(chartWidth + 2, y - 5), const Color(0xFF5A5A5A), 8);
    }

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final isGreen = c.close >= c.open;
      final color = isGreen ? const Color(0xFF00C853) : const Color(0xFFFF5252);

      final x = i * candleWidth + candleWidth / 2;
      final highY = size.height * (1 - (c.high - minPrice) / range);
      final lowY = size.height * (1 - (c.low - minPrice) / range);
      final openY = size.height * (1 - (c.open - minPrice) / range);
      final closeY = size.height * (1 - (c.close - minPrice) / range);

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), Paint()..color = color..strokeWidth = 1);

      final bodyTop = min(openY, closeY);
      final bodyBottom = max(openY, closeY);
      final bodyHeight = max(bodyBottom - bodyTop, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        Paint()..color = color,
      );
    }

    // Current price line - Green color
    final priceY = size.height * (1 - (currentPrice - minPrice) / range);
    if (priceY > 0 && priceY < size.height) {
      final linePaint = Paint()..color = const Color(0xFF00C853)..strokeWidth = 1;

      double startX = 0;
      while (startX < chartWidth) {
        canvas.drawLine(Offset(startX, priceY), Offset(startX + 3, priceY), linePaint);
        startX += 6;
      }

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth - 2, priceY - 8, rightMargin + 2, 16),
        const Radius.circular(2),
      );
      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF00C853));
      _drawText(canvas, _formatPriceLabel(currentPrice), Offset(chartWidth + 1, priceY - 4), Colors.white, 8, bold: true);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  String _formatPriceLabel(double price) {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    return price.toStringAsFixed(6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BybitVolumePainter extends CustomPainter {
  final List<CandleData> candles;

  BybitVolumePainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const rightMargin = 45.0;
    final chartWidth = size.width - rightMargin;

    double maxVol = 0;
    for (final c in candles) maxVol = max(maxVol, c.volume);
    if (maxVol == 0) return;

    final barWidth = chartWidth / candles.length;
    final bodyWidth = barWidth * 0.75;

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final isGreen = c.close >= c.open;
      final color = (isGreen ? const Color(0xFF00C853) : const Color(0xFFFF5252)).withOpacity(0.5);

      final x = i * barWidth + barWidth / 2;
      final barHeight = (c.volume / maxVol) * size.height * 0.85;

      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, size.height - barHeight, bodyWidth, barHeight),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Line chart painter for smooth price visualization
class BybitLineChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final double currentPrice;

  BybitLineChartPainter({required this.candles, required this.currentPrice});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const rightMargin = 45.0;
    final chartWidth = size.width - rightMargin;

    // Find price range
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (final c in candles) {
      minPrice = min(minPrice, c.low);
      maxPrice = max(maxPrice, c.high);
    }
    final padding = (maxPrice - minPrice) * 0.08;
    minPrice -= padding;
    maxPrice += padding;
    final range = maxPrice - minPrice;
    if (range == 0) return;

    // Draw grid lines
    final gridPaint = Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final price = maxPrice - (range * i / 4);
      _drawText(canvas, _formatPriceLabel(price), Offset(chartWidth + 2, y - 5), const Color(0xFF5A5A5A), 8);
    }

    // Draw gradient fill under line
    final path = Path();
    final linePoints = <Offset>[];
    final pointWidth = chartWidth / candles.length;

    for (int i = 0; i < candles.length; i++) {
      final x = i * pointWidth + pointWidth / 2;
      final y = size.height * (1 - (candles[i].close - minPrice) / range);
      linePoints.add(Offset(x, y));
    }

    if (linePoints.isNotEmpty) {
      path.moveTo(linePoints.first.dx, size.height);
      path.lineTo(linePoints.first.dx, linePoints.first.dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      path.lineTo(linePoints.last.dx, size.height);
      path.close();

      // Gradient fill - Green color
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00C853).withOpacity(0.3),
          const Color(0xFF00C853).withOpacity(0.05),
        ],
      );
      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, chartWidth, size.height));
      canvas.drawPath(path, fillPaint);

      // Draw the line - Green color
      final linePaint = Paint()
        ..color = const Color(0xFF00C853)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePath = Path();
      linePath.moveTo(linePoints.first.dx, linePoints.first.dy);
      for (int i = 1; i < linePoints.length; i++) {
        linePath.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Draw current price dot - Green color
      if (linePoints.isNotEmpty) {
        final lastPoint = linePoints.last;
        canvas.drawCircle(lastPoint, 4, Paint()..color = const Color(0xFF00C853));
        canvas.drawCircle(lastPoint, 2, Paint()..color = Colors.white);
      }
    }

    // Draw current price line - Green color
    final priceY = size.height * (1 - (currentPrice - minPrice) / range);
    if (priceY > 0 && priceY < size.height) {
      final priceLine = Paint()..color = const Color(0xFF00C853)..strokeWidth = 1;
      double startX = 0;
      while (startX < chartWidth) {
        canvas.drawLine(Offset(startX, priceY), Offset(startX + 3, priceY), priceLine);
        startX += 6;
      }

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth - 2, priceY - 8, rightMargin + 2, 16),
        const Radius.circular(2),
      );
      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF00C853));
      _drawText(canvas, _formatPriceLabel(currentPrice), Offset(chartWidth + 1, priceY - 4), Colors.white, 8, bold: true);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  String _formatPriceLabel(double price) {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    return price.toStringAsFixed(6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
