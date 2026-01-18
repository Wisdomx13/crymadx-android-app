import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../services/crypto_service.dart';
import '../../services/websocket_service.dart';
import '../../navigation/app_router.dart';

/// Markets Screen - Crypto market listings with LIVE WebSocket updates
class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final CryptoService _cryptoService = CryptoService();
  List<CryptoTicker> _allCryptos = [];
  List<CryptoTicker> _displayCryptos = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  // WebSocket stream subscription for live updates
  StreamSubscription<TickerData>? _tickerSubscription;
  bool _isLive = false;

  // Market tabs
  int _selectedMarketTab = 1; // 0=Favorites, 1=Hot, 2=New, 3=Gainers, 4=Losers, 5=Turnover
  final List<String> _marketTabs = ['Favorites', 'Hot', 'New', 'Gainers', 'Losers', 'Turnover'];
  Set<String> _favorites = {'BTC', 'ETH', 'SOL'};

  @override
  void initState() {
    super.initState();
    _loadCryptoData();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Connect to WebSocket for real-time price updates
  void _connectWebSocket() {
    // Subscribe to all tickers stream
    wsService.subscribeToAllTickers();

    // Listen for ticker updates
    _tickerSubscription = wsService.tickerStream.listen((tickerData) {
      if (mounted) {
        _updateTickerData(tickerData);
      }
    });

    setState(() => _isLive = true);
  }

  /// Update ticker data from WebSocket
  void _updateTickerData(TickerData data) {
    final index = _allCryptos.indexWhere((c) => c.symbol == data.symbol);
    if (index != -1) {
      setState(() {
        _allCryptos[index] = CryptoTicker(
          symbol: data.symbol,
          baseAsset: data.symbol.replaceAll('USDT', ''),
          price: data.lastPrice,
          change24h: data.priceChangePercent,
          high24h: data.highPrice,
          low24h: data.lowPrice,
          volume: data.volume,
          quoteVolume: data.quoteVolume,
        );
        _updateDisplayCryptos();
      });
    }
  }

  Future<void> _loadCryptoData() async {
    try {
      final cryptos = await _cryptoService.getTopCryptos(limit: 100);
      if (mounted) {
        setState(() {
          _allCryptos = cryptos;
          _isLoading = false;
          _updateDisplayCryptos();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateDisplayCryptos() {
    List<CryptoTicker> result = List.from(_allCryptos);

    // Apply search filter if searching
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((c) =>
        c.baseAsset.toLowerCase().contains(query) ||
        c.name.toLowerCase().contains(query)
      ).toList();
    } else {
      // Apply tab filter
      switch (_selectedMarketTab) {
        case 0: // Favorites
          result = result.where((c) => _favorites.contains(c.baseAsset)).toList();
          break;
        case 1: // Hot (by volume)
          result.sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));
          break;
        case 2: // New (simulated - show some altcoins)
          result = result.where((c) => ['APT', 'SUI', 'SEI', 'ARB', 'OP', 'INJ', 'TIA', 'JUP', 'WIF', 'BONK'].contains(c.baseAsset)).toList();
          if (result.isEmpty) result = _allCryptos.take(20).toList();
          break;
        case 3: // Gainers
          result.sort((a, b) => b.change24h.compareTo(a.change24h));
          break;
        case 4: // Losers
          result.sort((a, b) => a.change24h.compareTo(b.change24h));
          break;
        case 5: // Turnover
          result.sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));
          break;
      }
    }

    _displayCryptos = result;
  }

  void _toggleFavorite(String symbol) {
    setState(() {
      if (_favorites.contains(symbol)) {
        _favorites.remove(symbol);
      } else {
        _favorites.add(symbol);
      }
      _updateDisplayCryptos();
    });
  }

  void _navigateToTrade(CryptoTicker ticker) {
    // Navigate to trade screen with the selected symbol
    context.go('${AppRoutes.trade}?symbol=${ticker.baseAsset}USDT&base=${ticker.baseAsset}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final borderColor = isDark ? const Color(0xFF151515) : const Color(0xFFE0E0E0);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search markets...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _updateDisplayCryptos()),
              )
            : Text('Markets', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: textColor),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _updateDisplayCryptos();
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          margin: screenWidth > 500 ? const EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero,
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
                // Market Tabs
                _buildMarketTabs(),

                // Spot Tab
                _buildSpotTab(),

                // Crypto List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _displayCryptos.isEmpty
                          ? Center(
                              child: Text(
                                _selectedMarketTab == 0 ? 'No favorites yet' : 'No results',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadCryptoData,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _displayCryptos.length,
                                itemBuilder: (context, index) => _CryptoListItem(
                                  ticker: _displayCryptos[index],
                                  isFavorite: _favorites.contains(_displayCryptos[index].baseAsset),
                                  onTap: () => _navigateToTrade(_displayCryptos[index]),
                                  onFavorite: () => _toggleFavorite(_displayCryptos[index].baseAsset),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_marketTabs.length, (i) => GestureDetector(
            onTap: () => setState(() {
              _selectedMarketTab = i;
              _updateDisplayCryptos();
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _selectedMarketTab == i ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _marketTabs[i],
                style: TextStyle(
                  color: _selectedMarketTab == i ? textColor : subtextColor,
                  fontSize: 14,
                  fontWeight: _selectedMarketTab == i ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildSpotTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Spot',
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Live indicator
          if (_isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tradingBuy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tradingBuy.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.tradingBuy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tradingBuy.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.tradingBuy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
            '${_displayCryptos.length} pairs',
            style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CryptoListItem extends StatelessWidget {
  final CryptoTicker ticker;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _CryptoListItem({
    required this.ticker,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    final borderColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final isPositive = ticker.change24h >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            CryptoIcon(symbol: ticker.baseAsset, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticker.baseAsset,
                        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        ' / USDT',
                        style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vol ${_formatVolume(ticker.quoteVolume)}',
                    style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(ticker.price),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${ticker.change24h.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFavorite,
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : subtextColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '\$${price.toStringAsFixed(2)}';
    if (price >= 1) return '\$${price.toStringAsFixed(4)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) return '${(volume / 1000000000).toStringAsFixed(2)}B';
    if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(2)}M';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(2)}K';
    return volume.toStringAsFixed(2);
  }
}
