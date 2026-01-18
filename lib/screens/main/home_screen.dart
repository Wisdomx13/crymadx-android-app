import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';
import '../../providers/currency_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/balance_provider.dart';
import '../../navigation/app_router.dart';
import '../../services/crypto_service.dart';
import '../../services/websocket_service.dart';
import '../../services/nft_service.dart';

/// Home Screen - Bybit-inspired sleek design with LIVE WebSocket prices
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CryptoService _cryptoService = CryptoService();
  final NFTService _nftService = NFTService();
  List<CryptoTicker> _topCryptos = [];
  List<CryptoTicker> _filteredCryptos = [];
  List<CryptoTicker> _displayCryptos = [];
  List<NFTListing> _featuredNFTs = [];
  bool _isLoading = true;
  bool _nftLoading = true;
  bool _balanceVisible = true;
  final GlobalKey _notificationKey = GlobalKey();
  OverlayEntry? _notificationOverlay;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  int _currentEventIndex = 0;

  // WebSocket subscription for live updates
  StreamSubscription<TickerData>? _tickerSubscription;
  bool _isLive = false;

  // Market tabs
  int _selectedMarketTab = 1; // 0=Favorites, 1=Hot, 2=New, 3=Gainers, 4=Losers, 5=Turnover
  final List<String> _marketTabs = ['Favorites', 'Hot', 'New', 'Gainers', 'Losers', 'Turnover'];
  Set<String> _favorites = {'BTC', 'ETH', 'SOL'};

  // Demo balance - now using BalanceProvider

  // Events data
  final List<Map<String, dynamic>> _events = [
    {'title': 'Join CrymadX Alpha Farm', 'subtitle': 'Earn up to 10 USDT in rewards', 'image': 'farm', 'color': Color(0xFF1E3A5F)},
    {'title': 'Trade & Win Campaign', 'subtitle': 'Share \$50,000 prize pool', 'image': 'trophy', 'color': Color(0xFF3D1E5F)},
    {'title': 'Refer Friends & Earn', 'subtitle': 'Get 20% commission forever', 'image': 'refer', 'color': Color(0xFF1E5F3A)},
  ];

  @override
  void initState() {
    super.initState();
    _loadCryptoData();
    _loadNFTData();
    _connectWebSocket();
    // Load user balances from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceProvider>().loadBalances();
    });
    Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _currentEventIndex = (_currentEventIndex + 1) % _events.length);
    });
  }

  Future<void> _loadNFTData() async {
    try {
      final listings = await _nftService.getMarketplaceListings(limit: 6);
      if (mounted) {
        setState(() {
          _featuredNFTs = listings;
          _nftLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _nftLoading = false);
    }
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    _removeNotificationOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
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
    final index = _topCryptos.indexWhere((c) => c.symbol == data.symbol);
    if (index != -1) {
      setState(() {
        _topCryptos[index] = CryptoTicker(
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
      final cryptos = await _cryptoService.getTopCryptos(limit: 50);
      if (mounted) {
        setState(() {
          _topCryptos = cryptos;
          _isLoading = false;
          _updateDisplayCryptos();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateDisplayCryptos() {
    List<CryptoTicker> result = List.from(_topCryptos);

    switch (_selectedMarketTab) {
      case 0: // Favorites
        result = result.where((c) => _favorites.contains(c.baseAsset)).toList();
        break;
      case 1: // Hot (by volume)
        result.sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));
        break;
      case 2: // New (simulated - show some altcoins)
        result = result.where((c) => ['APT', 'SUI', 'SEI', 'ARB', 'OP', 'INJ', 'TIA', 'JUP'].contains(c.baseAsset)).toList();
        if (result.isEmpty) result = _topCryptos.take(10).toList();
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

    _displayCryptos = result;
  }

  void _searchMarkets(String query) {
    if (query.isEmpty) {
      setState(() { _filteredCryptos = []; _showSearchResults = false; });
      return;
    }
    final results = _topCryptos.where((crypto) =>
      crypto.baseAsset.toLowerCase().contains(query.toLowerCase()) ||
      crypto.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
    setState(() { _filteredCryptos = results; _showSearchResults = true; });
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            width: contentWidth,
            margin: screenWidth > 500 ? const EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero,
            decoration: screenWidth > 500
                ? BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: isDark ? const Color(0xFF151515) : const Color(0xFFE0E0E0), width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  )
                : BoxDecoration(color: bgColor),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth > 500 ? 16 : 0),
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadCryptoData,
                    color: AppColors.primary,
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildBalanceSection(),
                          _buildQuickActions(),
                          _buildEventsCarousel(),
                          _buildMarketSection(),
                          _buildNFTWidget(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  if (_showSearchResults) _buildSearchResultsOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final avatar = profile.selectedAvatar;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoutes.profile),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [avatar.color, avatar.color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      avatar.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search markets',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF333333), fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[600] : const Color(0xFF333333), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _searchMarkets,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.qr_code_scanner_outlined, onTap: () => context.push(AppRoutes.qrScanner)),
              Stack(
                children: [
                  _buildHeaderIcon(Icons.notifications_outlined, key: _notificationKey, onTap: () => _showNotifications(context)),
                  Positioned(right: 4, top: 4, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap, Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(key: key, onTap: onTap, child: Container(width: 36, height: 36, margin: const EdgeInsets.only(left: 6), child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 22)));
  }

  Widget _buildBalanceSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF333333);
    return Consumer2<CurrencyProvider, BalanceProvider>(
      builder: (context, currency, balance, _) {
        final totalBalance = balance.totalBalance;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Total Assets', style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: isDark ? FontWeight.w400 : FontWeight.w500)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                    child: Icon(_balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: subtextColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_balanceVisible ? totalBalance.toStringAsFixed(2) : '******', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            const SizedBox(width: 6),
                            Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Text('USD', style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w500)), Icon(Icons.keyboard_arrow_down, color: subtextColor, size: 16)])),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(children: [Text("Today's P&L", style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(width: 6), Text(_balanceVisible ? '0.00 USD(0%)' : '*** USD', style: TextStyle(color: AppColors.tradingBuy, fontSize: 12, fontWeight: FontWeight.w600)), Icon(Icons.keyboard_arrow_down, color: subtextColor, size: 14)]),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.deposit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Deposit', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _QuickActionButton(icon: Icons.swap_horiz, label: 'P2P', iconBgColor: iconBg, onTap: () => context.push(AppRoutes.p2p)),
            const SizedBox(width: 20),
            _QuickActionButton(icon: Icons.sync_alt, label: 'Convert', iconBgColor: iconBg, onTap: () => context.push(AppRoutes.convert)),
            const SizedBox(width: 20),
            _QuickActionButton(icon: Icons.savings_outlined, label: 'Earn', iconBgColor: iconBg, onTap: () => context.push(AppRoutes.earn)),
            const SizedBox(width: 20),
            _QuickActionButton(icon: Icons.lock_outline, label: 'Stake', iconBgColor: iconBg, onTap: () => context.push(AppRoutes.stake)),
            const SizedBox(width: 20),
            _QuickActionButton(icon: Icons.more_horiz, label: 'More', iconBgColor: iconBg, onTap: () => context.push(AppRoutes.quickActions)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCarousel() {
    final event = _events[_currentEventIndex];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: event['color'] as Color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(event['image'] == 'farm' ? Icons.agriculture : event['image'] == 'trophy' ? Icons.emoji_events : Icons.people, color: AppColors.primary, size: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Events', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 4),
                Text(event['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [Text('Explore Now', style: TextStyle(color: Colors.grey[300], fontSize: 12)), const SizedBox(width: 4), Icon(Icons.arrow_forward, color: Colors.grey[300], size: 14)]),
              ],
            ),
          ),
          Text('${_currentEventIndex + 1}/${_events.length}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildP2PSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.p2p),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('P2P', style: TextStyle(color: Colors.grey[400], fontSize: 12)), Icon(Icons.chevron_right, color: Colors.grey[600], size: 18)]),
              const SizedBox(height: 10),
              Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.tradingBuy.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.attach_money, color: AppColors.tradingBuy, size: 16)), const SizedBox(width: 8), const Text('USDT/ HKD', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))]),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.tradingBuy.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text('Buy', style: TextStyle(color: AppColors.tradingBuy, fontSize: 10))),
              const SizedBox(height: 8),
              Text('7.10', style: TextStyle(color: AppColors.tradingBuy, fontSize: 22, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                // Market tabs (Favorites, Hot, New, etc.)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_marketTabs.length, (i) => GestureDetector(
                      onTap: () => setState(() { _selectedMarketTab = i; _updateDisplayCryptos(); }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 18),
                        child: Text(_marketTabs[i], style: TextStyle(color: _selectedMarketTab == i ? textColor : subtextColor, fontSize: 14, fontWeight: _selectedMarketTab == i ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 10),
                // Spot only (removed Derivatives and TradFi)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Text('Spot', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Scrollable Crypto List
          SizedBox(
            height: 320,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayCryptos.isEmpty
                    ? Center(child: Text(_selectedMarketTab == 0 ? 'No favorites yet' : 'No data', style: TextStyle(color: subtextColor)))
                    : ListView.builder(
                        itemCount: _displayCryptos.length,
                        itemBuilder: (context, index) {
                          final ticker = _displayCryptos[index];
                          return _CryptoListItem(
                            ticker: ticker,
                            isFavorite: _favorites.contains(ticker.baseAsset),
                            onTap: () => context.go('${AppRoutes.trade}?symbol=${ticker.baseAsset}USDT&base=${ticker.baseAsset}'),
                            onFavorite: () => _toggleFavorite(ticker.baseAsset),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNFTWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF333333);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.diamond_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('NFT Marketplace', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.nft),
                child: Row(
                  children: [
                    Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // NFT Cards
          _nftLoading
              ? SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                )
              : _featuredNFTs.isEmpty
                  ? Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.diamond_outlined, size: 48, color: subtextColor),
                            const SizedBox(height: 12),
                            Text('No NFTs available', style: TextStyle(color: subtextColor, fontSize: 14)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.nft),
                              child: Text('Explore Marketplace', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featuredNFTs.length,
                        itemBuilder: (context, index) {
                          final nft = _featuredNFTs[index];
                          return _NFTCard(
                            nft: nft,
                            onTap: () => context.push(AppRoutes.nft),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.grey[400] : const Color(0xFF333333);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.15), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Search Results (${_filteredCryptos.length})', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                    GestureDetector(onTap: () { _searchController.clear(); setState(() => _showSearchResults = false); }, child: Icon(Icons.close, color: textColor, size: 18)),
                  ],
                ),
              ),
              Divider(color: borderColor, height: 1),
              Flexible(
                child: _filteredCryptos.isEmpty
                    ? Padding(padding: const EdgeInsets.all(20), child: Text('No markets found', style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF555555))))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredCryptos.length,
                        itemBuilder: (context, index) {
                          final ticker = _filteredCryptos[index];
                          return _SearchResultItem(
                            ticker: ticker,
                            onTap: () {
                              _searchController.clear();
                              setState(() => _showSearchResults = false);
                              context.go('${AppRoutes.trade}?symbol=${ticker.baseAsset}USDT&base=${ticker.baseAsset}');
                            },
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

  void _showNotifications(BuildContext context) {
    if (_notificationOverlay != null) { _removeNotificationOverlay(); return; }
    final RenderBox? renderBox = _notificationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.1);

    _notificationOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: _removeNotificationOverlay, child: Container(color: Colors.transparent))),
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(ctx).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text('3', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)))])),
                    Divider(color: borderColor, height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _NotificationItem(icon: Icons.trending_up, title: 'BTC Price Alert', message: 'Bitcoin reached \$${_topCryptos.isNotEmpty ? _topCryptos.first.price.toStringAsFixed(0) : "88,000"}', time: '2m', color: AppColors.tradingBuy, isUnread: true, onTap: () { _removeNotificationOverlay(); context.go('${AppRoutes.trade}?symbol=BTCUSDT&base=BTC'); }),
                            _NotificationItem(icon: Icons.check_circle, title: 'Deposit Confirmed', message: 'Your deposit of \$500 has been credited', time: '1h', color: AppColors.success, isUnread: true, onTap: () { _removeNotificationOverlay(); context.push(AppRoutes.deposit); }),
                            _NotificationItem(icon: Icons.card_giftcard, title: 'Welcome Bonus', message: 'Claim your 10 USDT welcome bonus', time: '1d', color: AppColors.warning, isUnread: false, onTap: _removeNotificationOverlay),
                            _NotificationItem(icon: Icons.security, title: 'Security Alert', message: 'New login from Chrome on Windows', time: '3h', color: Colors.orange, isUnread: false, onTap: _removeNotificationOverlay),
                          ],
                        ),
                      ),
                    ),
                    // See All Button
                    Divider(color: borderColor, height: 1),
                    GestureDetector(
                      onTap: () { _removeNotificationOverlay(); context.push(AppRoutes.notifications); },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('See All Notifications', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_notificationOverlay!);
  }

  void _showMoreOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('More Options', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF000000), fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _MoreItem(icon: Icons.savings_outlined, label: 'Earn', onTap: () { Navigator.pop(context); context.push(AppRoutes.earn); }),
            _MoreItem(icon: Icons.history, label: 'Transaction History', onTap: () { Navigator.pop(context); context.push(AppRoutes.transactionHistory); }),
            _MoreItem(icon: Icons.card_giftcard, label: 'Rewards', onTap: () { Navigator.pop(context); context.push(AppRoutes.rewards); }),
            _MoreItem(icon: Icons.people, label: 'Referral', onTap: () { Navigator.pop(context); context.push(AppRoutes.referral); }),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.iconBgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF000000).withOpacity(0.12),
                width: isDark ? 1 : 1.5,
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: isDark ? Colors.white : const Color(0xFF000000), size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF000000), fontSize: 11, fontWeight: FontWeight.w600)),
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

  const _CryptoListItem({required this.ticker, required this.isFavorite, required this.onTap, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[600] : const Color(0xFF555555);
    final isPositive = ticker.change24h >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CryptoIcon(symbol: ticker.baseAsset, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Text(ticker.baseAsset, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)), Text(' / USDT', style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], borderRadius: BorderRadius.circular(2)), child: Text('10x', style: TextStyle(color: subtextColor, fontSize: 9, fontWeight: FontWeight.w500)))]),
                  const SizedBox(height: 2),
                  Text('${(ticker.volume / 1000000).toStringAsFixed(2)}M USDT', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(ticker.price >= 1000 ? ticker.price.toStringAsFixed(1) : ticker.price.toStringAsFixed(4), style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell, borderRadius: BorderRadius.circular(4)), child: Text('${isPositive ? '+' : ''}${ticker.change24h.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: onFavorite, child: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : subtextColor, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final CryptoTicker ticker;
  final VoidCallback onTap;

  const _SearchResultItem({required this.ticker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final isPositive = ticker.change24h >= 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CryptoIcon(symbol: ticker.baseAsset, size: 32),
            const SizedBox(width: 10),
            Expanded(child: Text('${ticker.baseAsset}/USDT', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500))),
            Text('${isPositive ? '+' : ''}${ticker.change24h.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotificationItem({required this.icon, required this.title, required this.message, required this.time, required this.color, required this.isUnread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF555555);
    final timeColor = isDark ? Colors.grey[600] : const Color(0xFF777777);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: textColor, fontSize: 12, fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400)), Text(message, style: TextStyle(color: subtextColor, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)])),
            Text(time, style: TextStyle(color: timeColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
          border: isDark ? null : Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF000000), fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : const Color(0xFF555555)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// NFT Card widget for homepage
class _NFTCard extends StatelessWidget {
  final NFTListing nft;
  final VoidCallback onTap;

  const _NFTCard({required this.nft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? Colors.grey[500] : const Color(0xFF333333);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.3),
                    ],
                  ),
                ),
                child: nft.nft.imageUrl.isNotEmpty
                    ? Image.network(
                        nft.nft.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.diamond, color: AppColors.primary, size: 40),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.diamond, color: AppColors.primary, size: 40),
                      ),
              ),
            ),
            // NFT Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft.nft.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nft.nft.collectionName,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${nft.price?.toStringAsFixed(2) ?? '0.00'} ${nft.currency}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
