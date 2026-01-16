import 'dart:async';
import 'api_service.dart';
import '../config/api_config.dart';

/// Live cryptocurrency data via CrymadX Binance Proxy API
class CryptoService {
  /// Singleton instance
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final ApiService _api = api;

  /// Cache for ticker data
  Map<String, CryptoTicker> _tickerCache = {};
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(seconds: 10);

  /// Get all USDT trading pairs with 24h stats via backend proxy
  Future<List<CryptoTicker>> getTopCryptos({int limit = 20}) async {
    try {
      // Check cache
      if (_lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheExpiry &&
          _tickerCache.isNotEmpty) {
        return _tickerCache.values.take(limit).toList();
      }

      // Use backend Binance proxy
      final response = await _api.get(ApiConfig.binanceTicker);

      final List<dynamic> data = response is List ? response : (response['data'] ?? []);

      // Filter USDT pairs and sort by volume
      final usdtPairs = data
          .where((t) => t['symbol'].toString().endsWith('USDT'))
          .map((t) => CryptoTicker.fromBinance(t))
          .where((t) => t.price > 0 && t.volume > 0)
          .toList()
        ..sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));

      // Update cache
      _tickerCache = {for (var t in usdtPairs) t.symbol: t};
      _lastFetch = DateTime.now();

      return usdtPairs.take(limit).toList();
    } catch (e) {
      print('Error fetching crypto data: $e');
      // Return cached data or mock data on error
      if (_tickerCache.isNotEmpty) {
        return _tickerCache.values.take(limit).toList();
      }
      return _getMockData();
    }
  }

  /// Get ticker for a specific symbol via backend proxy
  Future<CryptoTicker?> getTicker(String symbol) async {
    try {
      final response = await _api.get(
        ApiConfig.binanceTicker,
        queryParameters: {'symbol': '${symbol}USDT'},
      );

      final data = response is Map ? response : null;
      if (data != null) {
        return CryptoTicker.fromBinance(data);
      }
    } catch (e) {
      print('Error fetching ticker for $symbol: $e');
    }
    return null;
  }

  /// Get order book for a symbol via backend proxy
  Future<OrderBook?> getOrderBook(String symbol, {int limit = 15}) async {
    try {
      final response = await _api.get(
        ApiConfig.binanceDepth,
        queryParameters: {
          'symbol': '${symbol}USDT',
          'limit': limit,
        },
      );

      return OrderBook.fromBinance(response);
    } catch (e) {
      print('Error fetching order book: $e');
    }
    return null;
  }

  /// Get recent trades for a symbol via backend proxy
  Future<List<RecentTrade>> getRecentTrades(String symbol, {int limit = 20}) async {
    try {
      final response = await _api.get(
        ApiConfig.binanceTrades,
        queryParameters: {
          'symbol': '${symbol}USDT',
          'limit': limit,
        },
      );

      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((t) => RecentTrade.fromBinance(t)).toList().reversed.toList();
    } catch (e) {
      print('Error fetching recent trades: $e');
    }
    return [];
  }

  /// Get current price for a symbol
  Future<double?> getPrice(String symbol) async {
    try {
      final ticker = await getTicker(symbol);
      return ticker?.price;
    } catch (e) {
      print('Error fetching price: $e');
    }
    return null;
  }

  /// Get exchange info via backend proxy
  Future<Map<String, dynamic>?> getExchangeInfo({String? symbol}) async {
    try {
      final response = await _api.get(
        ApiConfig.binanceExchangeInfo,
        queryParameters: symbol != null ? {'symbol': symbol} : null,
      );
      return response;
    } catch (e) {
      print('Error fetching exchange info: $e');
    }
    return null;
  }

  /// Clear cache
  void clearCache() {
    _tickerCache.clear();
    _lastFetch = null;
  }

  /// Mock data fallback
  List<CryptoTicker> _getMockData() {
    return [
      CryptoTicker(symbol: 'BTCUSDT', baseAsset: 'BTC', price: 43250.0, change24h: 2.45, high24h: 43890.0, low24h: 42100.0, volume: 12450.5, quoteVolume: 538000000),
      CryptoTicker(symbol: 'ETHUSDT', baseAsset: 'ETH', price: 2280.0, change24h: -1.20, high24h: 2350.0, low24h: 2240.0, volume: 85000.0, quoteVolume: 193800000),
      CryptoTicker(symbol: 'BNBUSDT', baseAsset: 'BNB', price: 312.80, change24h: 1.15, high24h: 318.0, low24h: 308.0, volume: 125000.0, quoteVolume: 39100000),
      CryptoTicker(symbol: 'SOLUSDT', baseAsset: 'SOL', price: 98.50, change24h: 5.67, high24h: 102.0, low24h: 93.0, volume: 450000.0, quoteVolume: 44325000),
      CryptoTicker(symbol: 'XRPUSDT', baseAsset: 'XRP', price: 0.6234, change24h: -0.85, high24h: 0.65, low24h: 0.61, volume: 125000000.0, quoteVolume: 77925000),
      CryptoTicker(symbol: 'ADAUSDT', baseAsset: 'ADA', price: 0.4521, change24h: 0.95, high24h: 0.46, low24h: 0.44, volume: 85000000.0, quoteVolume: 38428500),
      CryptoTicker(symbol: 'DOGEUSDT', baseAsset: 'DOGE', price: 0.0892, change24h: 3.21, high24h: 0.092, low24h: 0.085, volume: 650000000.0, quoteVolume: 57980000),
      CryptoTicker(symbol: 'DOTUSDT', baseAsset: 'DOT', price: 7.25, change24h: -2.10, high24h: 7.50, low24h: 7.10, volume: 3500000.0, quoteVolume: 25375000),
      CryptoTicker(symbol: 'MATICUSDT', baseAsset: 'MATIC', price: 0.8450, change24h: 1.80, high24h: 0.86, low24h: 0.82, volume: 45000000.0, quoteVolume: 38025000),
      CryptoTicker(symbol: 'LTCUSDT', baseAsset: 'LTC', price: 72.50, change24h: -0.45, high24h: 74.0, low24h: 71.0, volume: 280000.0, quoteVolume: 20300000),
    ];
  }
}

/// Crypto ticker data model
class CryptoTicker {
  final String symbol;
  final String baseAsset;
  final double price;
  final double change24h;
  final double high24h;
  final double low24h;
  final double volume;
  final double quoteVolume;

  CryptoTicker({
    required this.symbol,
    required this.baseAsset,
    required this.price,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    required this.volume,
    required this.quoteVolume,
  });

  factory CryptoTicker.fromBinance(Map<String, dynamic> json) {
    final symbol = json['symbol'].toString();
    final baseAsset = symbol.replaceAll('USDT', '');

    return CryptoTicker(
      symbol: symbol,
      baseAsset: baseAsset,
      price: double.tryParse(json['lastPrice']?.toString() ?? '0') ?? 0,
      change24h: double.tryParse(json['priceChangePercent']?.toString() ?? '0') ?? 0,
      high24h: double.tryParse(json['highPrice']?.toString() ?? '0') ?? 0,
      low24h: double.tryParse(json['lowPrice']?.toString() ?? '0') ?? 0,
      volume: double.tryParse(json['volume']?.toString() ?? '0') ?? 0,
      quoteVolume: double.tryParse(json['quoteVolume']?.toString() ?? '0') ?? 0,
    );
  }

  /// Get full name for the crypto
  String get name => _cryptoNames[baseAsset] ?? baseAsset;

  static const Map<String, String> _cryptoNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'BNB': 'BNB',
    'SOL': 'Solana',
    'XRP': 'Ripple',
    'ADA': 'Cardano',
    'DOGE': 'Dogecoin',
    'DOT': 'Polkadot',
    'MATIC': 'Polygon',
    'LTC': 'Litecoin',
    'AVAX': 'Avalanche',
    'LINK': 'Chainlink',
    'ATOM': 'Cosmos',
    'UNI': 'Uniswap',
    'XLM': 'Stellar',
    'TRX': 'Tron',
    'NEAR': 'NEAR Protocol',
    'APT': 'Aptos',
    'ARB': 'Arbitrum',
    'OP': 'Optimism',
    'SHIB': 'Shiba Inu',
    'PEPE': 'Pepe',
    'FIL': 'Filecoin',
    'ICP': 'Internet Computer',
    'VET': 'VeChain',
    'HBAR': 'Hedera',
    'INJ': 'Injective',
    'SUI': 'Sui',
    'SEI': 'Sei',
    'USDT': 'Tether',
    'USDC': 'USD Coin',
  };
}

/// Order book data model
class OrderBook {
  final List<OrderBookEntry> asks;
  final List<OrderBookEntry> bids;

  OrderBook({required this.asks, required this.bids});

  factory OrderBook.fromBinance(Map<String, dynamic> json) {
    final asks = (json['asks'] as List? ?? [])
        .map((a) => OrderBookEntry(
              price: double.tryParse(a[0].toString()) ?? 0,
              amount: double.tryParse(a[1].toString()) ?? 0,
            ))
        .toList()
        .reversed
        .toList();

    final bids = (json['bids'] as List? ?? [])
        .map((b) => OrderBookEntry(
              price: double.tryParse(b[0].toString()) ?? 0,
              amount: double.tryParse(b[1].toString()) ?? 0,
            ))
        .toList();

    return OrderBook(asks: asks, bids: bids);
  }
}

class OrderBookEntry {
  final double price;
  final double amount;
  double get total => price * amount;

  OrderBookEntry({required this.price, required this.amount});
}

/// Recent trade data model
class RecentTrade {
  final double price;
  final double amount;
  final DateTime time;
  final bool isBuyerMaker;

  RecentTrade({
    required this.price,
    required this.amount,
    required this.time,
    required this.isBuyerMaker,
  });

  factory RecentTrade.fromBinance(Map<String, dynamic> json) {
    return RecentTrade(
      price: double.tryParse(json['price'].toString()) ?? 0,
      amount: double.tryParse(json['qty'].toString()) ?? 0,
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      isBuyerMaker: json['isBuyerMaker'] ?? false,
    );
  }

  bool get isBuy => !isBuyerMaker;

  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

/// Global crypto service instance
final cryptoService = CryptoService();
