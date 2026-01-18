import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

/// Ticker data from Binance WebSocket
class TickerData {
  final String symbol;
  final double lastPrice;
  final double priceChange;
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;

  TickerData({
    required this.symbol,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
  });

  factory TickerData.fromJson(Map<String, dynamic> json) {
    return TickerData(
      symbol: json['s'] ?? json['symbol'] ?? '',
      lastPrice: double.tryParse(json['c']?.toString() ?? json['lastPrice']?.toString() ?? '0') ?? 0,
      priceChange: double.tryParse(json['p']?.toString() ?? json['priceChange']?.toString() ?? '0') ?? 0,
      priceChangePercent: double.tryParse(json['P']?.toString() ?? json['priceChangePercent']?.toString() ?? '0') ?? 0,
      highPrice: double.tryParse(json['h']?.toString() ?? json['highPrice']?.toString() ?? '0') ?? 0,
      lowPrice: double.tryParse(json['l']?.toString() ?? json['lowPrice']?.toString() ?? '0') ?? 0,
      volume: double.tryParse(json['v']?.toString() ?? json['volume']?.toString() ?? '0') ?? 0,
      quoteVolume: double.tryParse(json['q']?.toString() ?? json['quoteVolume']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'lastPrice': lastPrice,
    'priceChange': priceChange,
    'priceChangePercent': priceChangePercent,
    'highPrice': highPrice,
    'lowPrice': lowPrice,
    'volume': volume,
    'quoteVolume': quoteVolume,
  };
}

/// Trade data from Binance WebSocket
class TradeData {
  final String symbol;
  final int tradeId;
  final double price;
  final double quantity;
  final bool isBuyerMaker;
  final DateTime timestamp;

  TradeData({
    required this.symbol,
    required this.tradeId,
    required this.price,
    required this.quantity,
    required this.isBuyerMaker,
    required this.timestamp,
  });

  factory TradeData.fromJson(Map<String, dynamic> json) {
    return TradeData(
      symbol: json['s'] ?? '',
      tradeId: json['t'] ?? 0,
      price: double.tryParse(json['p']?.toString() ?? '0') ?? 0,
      quantity: double.tryParse(json['q']?.toString() ?? '0') ?? 0,
      isBuyerMaker: json['m'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['T'] ?? 0),
    );
  }
}

/// Order book depth data
class DepthData {
  final String symbol;
  final List<List<dynamic>> bids;
  final List<List<dynamic>> asks;
  final int lastUpdateId;

  DepthData({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.lastUpdateId,
  });

  factory DepthData.fromJson(Map<String, dynamic> json, String symbol) {
    return DepthData(
      symbol: symbol,
      bids: List<List<dynamic>>.from(json['bids'] ?? json['b'] ?? []),
      asks: List<List<dynamic>>.from(json['asks'] ?? json['a'] ?? []),
      lastUpdateId: json['lastUpdateId'] ?? json['u'] ?? 0,
    );
  }
}

/// Kline/Candlestick data
class KlineData {
  final String symbol;
  final DateTime openTime;
  final DateTime closeTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final bool isClosed;

  KlineData({
    required this.symbol,
    required this.openTime,
    required this.closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.isClosed,
  });

  factory KlineData.fromJson(Map<String, dynamic> json, String symbol) {
    final k = json['k'];
    return KlineData(
      symbol: symbol,
      openTime: DateTime.fromMillisecondsSinceEpoch(k['t'] ?? 0),
      closeTime: DateTime.fromMillisecondsSinceEpoch(k['T'] ?? 0),
      open: double.tryParse(k['o']?.toString() ?? '0') ?? 0,
      high: double.tryParse(k['h']?.toString() ?? '0') ?? 0,
      low: double.tryParse(k['l']?.toString() ?? '0') ?? 0,
      close: double.tryParse(k['c']?.toString() ?? '0') ?? 0,
      volume: double.tryParse(k['v']?.toString() ?? '0') ?? 0,
      isClosed: k['x'] ?? false,
    );
  }
}

/// WebSocket Service for real-time Binance data
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  static const String _baseWsUrl = 'wss://stream.binance.com:9443/ws';
  static const String _combinedWsUrl = 'wss://stream.binance.com:9443/stream';

  WebSocketChannel? _tickerChannel;
  WebSocketChannel? _tradeChannel;
  WebSocketChannel? _depthChannel;
  WebSocketChannel? _klineChannel;

  final Map<String, StreamController<TickerData>> _tickerControllers = {};
  final Map<String, StreamController<TradeData>> _tradeControllers = {};
  final Map<String, StreamController<DepthData>> _depthControllers = {};
  final Map<String, StreamController<KlineData>> _klineControllers = {};

  StreamController<Map<String, TickerData>>? _allTickersController;
  StreamController<TickerData>? _tickerStreamController;
  final Map<String, TickerData> _latestTickers = {};

  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get all latest tickers
  Map<String, TickerData> get latestTickers => Map.unmodifiable(_latestTickers);

  /// Get stream of individual ticker updates
  Stream<TickerData> get tickerStream {
    _tickerStreamController ??= StreamController<TickerData>.broadcast();
    return _tickerStreamController!.stream;
  }

  /// Subscribe to all tickers (24hr rolling window)
  void subscribeToAllTickers() {
    _allTickersController ??= StreamController<Map<String, TickerData>>.broadcast();
    _tickerStreamController ??= StreamController<TickerData>.broadcast();
    _connectToAllTickers();
  }

  void _connectToAllTickers() {
    try {
      _tickerChannel?.sink.close();
      _tickerChannel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl/!ticker@arr'),
      );

      _isConnected = true;
      _startPingTimer();

      _tickerChannel!.stream.listen(
        (data) {
          try {
            final List<dynamic> tickers = jsonDecode(data);
            for (var ticker in tickers) {
              final tickerData = TickerData.fromJson(ticker);
              _latestTickers[tickerData.symbol] = tickerData;

              // Emit to individual ticker stream
              _tickerStreamController?.add(tickerData);

              // Notify individual subscribers
              if (_tickerControllers.containsKey(tickerData.symbol)) {
                _tickerControllers[tickerData.symbol]!.add(tickerData);
              }
            }
            _allTickersController?.add(Map.from(_latestTickers));
          } catch (e) {
            debugPrint('Error parsing ticker data: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _scheduleReconnect();
    }
  }

  /// Subscribe to a single ticker
  Stream<TickerData> subscribeToTicker(String symbol) {
    final symbolLower = symbol.toLowerCase();
    if (!_tickerControllers.containsKey(symbol)) {
      _tickerControllers[symbol] = StreamController<TickerData>.broadcast();
    }

    // Connect to individual ticker if not using all tickers stream
    if (_tickerChannel == null) {
      _connectToSingleTicker(symbolLower);
    }

    return _tickerControllers[symbol]!.stream;
  }

  void _connectToSingleTicker(String symbol) {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl/$symbol@ticker'),
      );

      channel.stream.listen(
        (data) {
          try {
            final ticker = TickerData.fromJson(jsonDecode(data));
            _latestTickers[ticker.symbol] = ticker;
            if (_tickerControllers.containsKey(ticker.symbol)) {
              _tickerControllers[ticker.symbol]!.add(ticker);
            }
          } catch (e) {
            debugPrint('Error parsing single ticker: $e');
          }
        },
        onError: (e) => debugPrint('Single ticker error: $e'),
      );
    } catch (e) {
      debugPrint('Error connecting to single ticker: $e');
    }
  }

  /// Subscribe to trades for a symbol
  Stream<TradeData> subscribeToTrades(String symbol) {
    final symbolLower = symbol.toLowerCase();
    if (!_tradeControllers.containsKey(symbol)) {
      _tradeControllers[symbol] = StreamController<TradeData>.broadcast();
      _connectToTrades(symbolLower, symbol);
    }
    return _tradeControllers[symbol]!.stream;
  }

  void _connectToTrades(String symbolLower, String symbol) {
    try {
      _tradeChannel?.sink.close();
      _tradeChannel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl/$symbolLower@trade'),
      );

      _tradeChannel!.stream.listen(
        (data) {
          try {
            final trade = TradeData.fromJson(jsonDecode(data));
            if (_tradeControllers.containsKey(symbol)) {
              _tradeControllers[symbol]!.add(trade);
            }
          } catch (e) {
            debugPrint('Error parsing trade: $e');
          }
        },
        onError: (e) => debugPrint('Trade stream error: $e'),
      );
    } catch (e) {
      debugPrint('Error connecting to trades: $e');
    }
  }

  /// Subscribe to order book depth
  Stream<DepthData> subscribeToDepth(String symbol, {int levels = 20}) {
    final symbolLower = symbol.toLowerCase();
    final key = '$symbol:$levels';
    if (!_depthControllers.containsKey(key)) {
      _depthControllers[key] = StreamController<DepthData>.broadcast();
      _connectToDepth(symbolLower, symbol, levels, key);
    }
    return _depthControllers[key]!.stream;
  }

  void _connectToDepth(String symbolLower, String symbol, int levels, String key) {
    try {
      _depthChannel?.sink.close();
      _depthChannel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl/$symbolLower@depth$levels@100ms'),
      );

      _depthChannel!.stream.listen(
        (data) {
          try {
            final depth = DepthData.fromJson(jsonDecode(data), symbol);
            if (_depthControllers.containsKey(key)) {
              _depthControllers[key]!.add(depth);
            }
          } catch (e) {
            debugPrint('Error parsing depth: $e');
          }
        },
        onError: (e) => debugPrint('Depth stream error: $e'),
      );
    } catch (e) {
      debugPrint('Error connecting to depth: $e');
    }
  }

  /// Subscribe to kline/candlestick data
  Stream<KlineData> subscribeToKline(String symbol, String interval) {
    final symbolLower = symbol.toLowerCase();
    final key = '$symbol:$interval';
    if (!_klineControllers.containsKey(key)) {
      _klineControllers[key] = StreamController<KlineData>.broadcast();
      _connectToKline(symbolLower, symbol, interval, key);
    }
    return _klineControllers[key]!.stream;
  }

  void _connectToKline(String symbolLower, String symbol, String interval, String key) {
    try {
      _klineChannel?.sink.close();
      _klineChannel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl/$symbolLower@kline_$interval'),
      );

      _klineChannel!.stream.listen(
        (data) {
          try {
            final kline = KlineData.fromJson(jsonDecode(data), symbol);
            if (_klineControllers.containsKey(key)) {
              _klineControllers[key]!.add(kline);
            }
          } catch (e) {
            debugPrint('Error parsing kline: $e');
          }
        },
        onError: (e) => debugPrint('Kline stream error: $e'),
      );
    } catch (e) {
      debugPrint('Error connecting to kline: $e');
    }
  }

  /// Subscribe to multiple streams at once
  Stream<dynamic> subscribeToCombinedStreams(List<String> streams) {
    final controller = StreamController<dynamic>.broadcast();

    try {
      final streamNames = streams.join('/');
      final channel = WebSocketChannel.connect(
        Uri.parse('$_combinedWsUrl?streams=$streamNames'),
      );

      channel.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            controller.add(decoded);
          } catch (e) {
            debugPrint('Error parsing combined stream: $e');
          }
        },
        onError: (e) {
          debugPrint('Combined stream error: $e');
          controller.addError(e);
        },
        onDone: () => controller.close(),
      );
    } catch (e) {
      debugPrint('Error connecting to combined streams: $e');
      controller.addError(e);
    }

    return controller.stream;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      // WebSocket ping to keep connection alive
      try {
        _tickerChannel?.sink.add('ping');
      } catch (e) {
        debugPrint('Ping error: $e');
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('Attempting to reconnect...');
        _connectToAllTickers();
      }
    });
  }

  /// Get ticker data for a specific symbol from cache
  TickerData? getTicker(String symbol) => _latestTickers[symbol];

  /// Unsubscribe from a ticker
  void unsubscribeFromTicker(String symbol) {
    _tickerControllers[symbol]?.close();
    _tickerControllers.remove(symbol);
  }

  /// Unsubscribe from trades
  void unsubscribeFromTrades(String symbol) {
    _tradeControllers[symbol]?.close();
    _tradeControllers.remove(symbol);
    _tradeChannel?.sink.close();
    _tradeChannel = null;
  }

  /// Unsubscribe from depth
  void unsubscribeFromDepth(String symbol, {int levels = 20}) {
    final key = '$symbol:$levels';
    _depthControllers[key]?.close();
    _depthControllers.remove(key);
    _depthChannel?.sink.close();
    _depthChannel = null;
  }

  /// Unsubscribe from kline
  void unsubscribeFromKline(String symbol, String interval) {
    final key = '$symbol:$interval';
    _klineControllers[key]?.close();
    _klineControllers.remove(key);
    _klineChannel?.sink.close();
    _klineChannel = null;
  }

  /// Close all connections
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _isConnected = false;

    _tickerChannel?.sink.close();
    _tradeChannel?.sink.close();
    _depthChannel?.sink.close();
    _klineChannel?.sink.close();

    for (var controller in _tickerControllers.values) {
      controller.close();
    }
    for (var controller in _tradeControllers.values) {
      controller.close();
    }
    for (var controller in _depthControllers.values) {
      controller.close();
    }
    for (var controller in _klineControllers.values) {
      controller.close();
    }

    _tickerControllers.clear();
    _tradeControllers.clear();
    _depthControllers.clear();
    _klineControllers.clear();

    _allTickersController?.close();
    _allTickersController = null;
    _latestTickers.clear();
  }
}

/// Global WebSocket service instance
final wsService = WebSocketService();
