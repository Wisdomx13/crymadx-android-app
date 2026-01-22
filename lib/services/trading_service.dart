import 'api_service.dart';
import '../config/api_config.dart';

/// Market Ticker model
class MarketTicker {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final double quoteVolume24h;

  MarketTicker({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.quoteVolume24h,
  });

  bool get isPositive => changePercent24h >= 0;

  factory MarketTicker.fromJson(Map<String, dynamic> json) {
    return MarketTicker(
      symbol: json['symbol'] ?? '',
      baseAsset: json['baseAsset'] ?? json['base_asset'] ?? '',
      quoteAsset: json['quoteAsset'] ?? json['quote_asset'] ?? 'USDT',
      price: (json['price'] ?? json['lastPrice'] ?? 0).toDouble(),
      change24h: (json['change24h'] ?? json['priceChange'] ?? 0).toDouble(),
      changePercent24h: (json['changePercent24h'] ?? json['priceChangePercent'] ?? 0).toDouble(),
      high24h: (json['high24h'] ?? json['highPrice'] ?? 0).toDouble(),
      low24h: (json['low24h'] ?? json['lowPrice'] ?? 0).toDouble(),
      volume24h: (json['volume24h'] ?? json['volume'] ?? 0).toDouble(),
      quoteVolume24h: (json['quoteVolume24h'] ?? json['quoteVolume'] ?? 0).toDouble(),
    );
  }
}

/// Trading Pair model - matches backend /api/spot/pairs
class TradingPair {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final double minQuantity;
  final double maxQuantity;
  final double minNotional;
  final double tickSize;
  final double stepSize;
  final int pricePrecision;
  final int quantityPrecision;
  final bool isActive;

  TradingPair({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.minQuantity,
    required this.maxQuantity,
    required this.minNotional,
    required this.tickSize,
    required this.stepSize,
    required this.pricePrecision,
    required this.quantityPrecision,
    required this.isActive,
  });

  factory TradingPair.fromJson(Map<String, dynamic> json) {
    return TradingPair(
      symbol: json['symbol'] ?? '',
      baseAsset: json['baseAsset'] ?? json['base'] ?? '',
      quoteAsset: json['quoteAsset'] ?? json['quote'] ?? 'USDT',
      minQuantity: (json['minQuantity'] ?? json['minQty'] ?? 0).toDouble(),
      maxQuantity: (json['maxQuantity'] ?? json['maxQty'] ?? 0).toDouble(),
      minNotional: (json['minNotional'] ?? 0).toDouble(),
      tickSize: (json['tickSize'] ?? 0.00000001).toDouble(),
      stepSize: (json['stepSize'] ?? 0.00000001).toDouble(),
      pricePrecision: json['pricePrecision'] ?? 8,
      quantityPrecision: json['quantityPrecision'] ?? json['qtyPrecision'] ?? 8,
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }
}

/// Quote model - matches backend /api/spot/quote
class SpotQuote {
  final String symbol;
  final String side;
  final double price;
  final double quantity;
  final double total;
  final double fee;
  final String feeCurrency;
  final DateTime expiresAt;

  SpotQuote({
    required this.symbol,
    required this.side,
    required this.price,
    required this.quantity,
    required this.total,
    required this.fee,
    required this.feeCurrency,
    required this.expiresAt,
  });

  factory SpotQuote.fromJson(Map<String, dynamic> json) {
    return SpotQuote(
      symbol: json['symbol'] ?? '',
      side: json['side'] ?? 'buy',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? json['amount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      feeCurrency: json['feeCurrency'] ?? json['feeAsset'] ?? 'USDT',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(seconds: 30)),
    );
  }
}

/// Order Book model
class OrderBook {
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;
  final DateTime timestamp;

  OrderBook({
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    return OrderBook(
      bids: (json['bids'] as List? ?? [])
          .map((e) => OrderBookEntry.fromJson(e))
          .toList(),
      asks: (json['asks'] as List? ?? [])
          .map((e) => OrderBookEntry.fromJson(e))
          .toList(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class OrderBookEntry {
  final double price;
  final double quantity;

  OrderBookEntry({required this.price, required this.quantity});

  double get total => price * quantity;

  factory OrderBookEntry.fromJson(dynamic json) {
    if (json is List) {
      return OrderBookEntry(
        price: double.tryParse(json[0].toString()) ?? 0,
        quantity: double.tryParse(json[1].toString()) ?? 0,
      );
    }
    return OrderBookEntry(
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? json['qty'] ?? 0).toDouble(),
    );
  }
}

/// Kline/Candlestick model
class Kline {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime closeTime;

  Kline({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
  });

  factory Kline.fromJson(dynamic json) {
    if (json is List) {
      return Kline(
        openTime: DateTime.fromMillisecondsSinceEpoch(json[0]),
        open: double.tryParse(json[1].toString()) ?? 0,
        high: double.tryParse(json[2].toString()) ?? 0,
        low: double.tryParse(json[3].toString()) ?? 0,
        close: double.tryParse(json[4].toString()) ?? 0,
        volume: double.tryParse(json[5].toString()) ?? 0,
        closeTime: DateTime.fromMillisecondsSinceEpoch(json[6]),
      );
    }
    return Kline(
      openTime: DateTime.parse(json['openTime'] ?? json['open_time']),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      closeTime: DateTime.parse(json['closeTime'] ?? json['close_time']),
    );
  }
}

enum OrderSide { buy, sell }
enum OrderType { market, limit, stopLimit }
enum OrderStatus { pending, open, filled, partiallyFilled, cancelled, expired }

/// Spot Order model - matches backend /api/spot/orders
class SpotOrder {
  final String id;
  final String symbol;
  final OrderSide side;
  final OrderType type;
  final OrderStatus status;
  final double price;
  final double quantity;
  final double filledQuantity;
  final double total;
  final double? fee;
  final String? feeCurrency;
  final double? stopPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SpotOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.type,
    required this.status,
    required this.price,
    required this.quantity,
    required this.filledQuantity,
    required this.total,
    this.fee,
    this.feeCurrency,
    this.stopPrice,
    required this.createdAt,
    this.updatedAt,
  });

  double get filledPercent => quantity > 0 ? (filledQuantity / quantity) * 100 : 0;

  factory SpotOrder.fromJson(Map<String, dynamic> json) {
    return SpotOrder(
      id: json['id'] ?? json['orderId'] ?? '',
      symbol: json['symbol'] ?? '',
      side: (json['side'] ?? '').toString().toLowerCase() == 'buy' ? OrderSide.buy : OrderSide.sell,
      type: _parseOrderType(json['type']),
      status: _parseOrderStatus(json['status']),
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? json['amount'] ?? 0).toDouble(),
      filledQuantity: (json['filledQuantity'] ?? json['executedQty'] ?? 0).toDouble(),
      total: (json['total'] ?? json['cummulativeQuoteQty'] ?? 0).toDouble(),
      fee: json['fee'] != null ? (json['fee']).toDouble() : null,
      feeCurrency: json['feeCurrency'] ?? json['feeAsset'],
      stopPrice: json['stopPrice'] != null ? (json['stopPrice']).toDouble() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static OrderType _parseOrderType(String? type) {
    switch (type?.toLowerCase()) {
      case 'limit':
        return OrderType.limit;
      case 'stop_limit':
      case 'stoplimit':
        return OrderType.stopLimit;
      default:
        return OrderType.market;
    }
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
      case 'new':
        return OrderStatus.open;
      case 'filled':
        return OrderStatus.filled;
      case 'partially_filled':
      case 'partiallyfilled':
        return OrderStatus.partiallyFilled;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'expired':
        return OrderStatus.expired;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Trade history entry
class TradeEntry {
  final String id;
  final String orderId;
  final String symbol;
  final OrderSide side;
  final double price;
  final double quantity;
  final double fee;
  final String feeCurrency;
  final DateTime timestamp;

  TradeEntry({
    required this.id,
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.price,
    required this.quantity,
    required this.fee,
    required this.feeCurrency,
    required this.timestamp,
  });

  double get total => price * quantity;

  factory TradeEntry.fromJson(Map<String, dynamic> json) {
    return TradeEntry(
      id: json['id'] ?? json['tradeId'] ?? '',
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      symbol: json['symbol'] ?? '',
      side: (json['side'] ?? '').toString().toLowerCase() == 'buy' ? OrderSide.buy : OrderSide.sell,
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? json['qty'] ?? 0).toDouble(),
      fee: (json['fee'] ?? json['commission'] ?? 0).toDouble(),
      feeCurrency: json['feeCurrency'] ?? json['commissionAsset'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : json['time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['time'])
              : DateTime.now(),
    );
  }
}

/// Create Order Request model
class CreateOrderRequest {
  final String symbol;
  final OrderSide side;
  final OrderType type;
  final double quantity;
  final double? price;
  final double? stopPrice;
  final String? quoteId; // For quote-based orders

  CreateOrderRequest({
    required this.symbol,
    required this.side,
    required this.type,
    required this.quantity,
    this.price,
    this.stopPrice,
    this.quoteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'side': side == OrderSide.buy ? 'buy' : 'sell',
      'type': type.name,
      'quantity': quantity,
      if (price != null) 'price': price,
      if (stopPrice != null) 'stopPrice': stopPrice,
      if (quoteId != null) 'quoteId': quoteId,
    };
  }
}

/// Trading Service - Handles spot trading API calls
class TradingService {
  final ApiService _api = api;

  // ============================================
  // TRADING PAIRS
  // ============================================

  /// Get available trading pairs
  Future<List<TradingPair>> getTradingPairs() async {
    final response = await _api.get(ApiConfig.spotPairs);
    final List<dynamic> data = response['pairs'] ?? response['symbols'] ?? [];
    return data.map((json) => TradingPair.fromJson(json)).toList();
  }

  /// Get specific trading pair info
  Future<TradingPair> getTradingPair(String symbol) async {
    final response = await _api.get('${ApiConfig.spotPairs}/$symbol');
    final pairData = response['pair'] ?? response;
    return TradingPair.fromJson(pairData);
  }

  // ============================================
  // QUOTES
  // ============================================

  /// Get quote for a trade
  Future<SpotQuote> getQuote({
    required String symbol,
    required String side,
    required double quantity,
  }) async {
    final response = await _api.post(
      ApiConfig.spotQuote,
      data: {
        'symbol': symbol,
        'side': side,
        'quantity': quantity,
      },
    );
    final quoteData = response['quote'] ?? response;
    return SpotQuote.fromJson(quoteData);
  }

  // ============================================
  // ORDERS
  // ============================================

  /// Create a new order
  Future<SpotOrder> createOrder(CreateOrderRequest request) async {
    final response = await _api.post(
      ApiConfig.spotOrder,
      data: request.toJson(),
    );
    final orderData = response['order'] ?? response;
    return SpotOrder.fromJson(orderData);
  }

  /// Get user orders
  Future<List<SpotOrder>> getOrders({
    String? symbol,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.spotOrders,
      queryParameters: {
        if (symbol != null) 'symbol': symbol,
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['orders'] ?? response['items'] ?? [];
    return data.map((json) => SpotOrder.fromJson(json)).toList();
  }

  /// Get open orders
  Future<List<SpotOrder>> getOpenOrders({String? symbol}) async {
    return getOrders(symbol: symbol, status: 'open');
  }

  /// Get order by ID
  Future<SpotOrder> getOrder(String orderId) async {
    final response = await _api.get('${ApiConfig.spotOrders}/$orderId');
    final orderData = response['order'] ?? response;
    return SpotOrder.fromJson(orderData);
  }

  /// Cancel order
  Future<SpotOrder> cancelOrder(String orderId) async {
    final response = await _api.delete('${ApiConfig.spotOrders}/$orderId');
    final orderData = response['order'] ?? response;
    return SpotOrder.fromJson(orderData);
  }

  /// Cancel all orders for a symbol
  Future<Map<String, dynamic>> cancelAllOrders(String symbol) async {
    final response = await _api.delete(
      ApiConfig.spotOrders,
      data: {'symbol': symbol},
    );
    return {
      'success': response['success'] ?? true,
      'cancelled': response['cancelled'] ?? 0,
    };
  }

  // ============================================
  // TRADE HISTORY
  // ============================================

  /// Get user trade history
  Future<List<TradeEntry>> getTradeHistory({
    String? symbol,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '${ApiConfig.spotOrders}/history',
      queryParameters: {
        if (symbol != null) 'symbol': symbol,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['trades'] ?? response['items'] ?? [];
    return data.map((json) => TradeEntry.fromJson(json)).toList();
  }

  // ============================================
  // ORDER BOOK
  // ============================================

  /// Get order book for a symbol
  Future<Map<String, dynamic>> getOrderBook(String symbol, {int limit = 20}) async {
    try {
      final response = await _api.get(
        '${ApiConfig.spotPairs}/$symbol/orderbook',
        queryParameters: {'limit': limit},
      );

      final List<dynamic> bidsData = response['bids'] ?? [];
      final List<dynamic> asksData = response['asks'] ?? [];

      return {
        'bids': bidsData.map((e) {
          if (e is List) {
            return {'price': double.tryParse(e[0].toString()) ?? 0, 'quantity': double.tryParse(e[1].toString()) ?? 0};
          }
          return {'price': (e['price'] ?? 0).toDouble(), 'quantity': (e['quantity'] ?? e['qty'] ?? 0).toDouble()};
        }).toList(),
        'asks': asksData.map((e) {
          if (e is List) {
            return {'price': double.tryParse(e[0].toString()) ?? 0, 'quantity': double.tryParse(e[1].toString()) ?? 0};
          }
          return {'price': (e['price'] ?? 0).toDouble(), 'quantity': (e['quantity'] ?? e['qty'] ?? 0).toDouble()};
        }).toList(),
        'lastPrice': response['lastPrice'] ?? response['last_price'],
      };
    } catch (e) {
      // Return empty order book on error
      return {'bids': [], 'asks': [], 'lastPrice': null};
    }
  }

  // ============================================
  // QUICK TRADE HELPERS
  // ============================================

  /// Quick buy with market order
  Future<SpotOrder> quickBuy(String symbol, double quantity) async {
    return createOrder(CreateOrderRequest(
      symbol: symbol,
      side: OrderSide.buy,
      type: OrderType.market,
      quantity: quantity,
    ));
  }

  /// Quick sell with market order
  Future<SpotOrder> quickSell(String symbol, double quantity) async {
    return createOrder(CreateOrderRequest(
      symbol: symbol,
      side: OrderSide.sell,
      type: OrderType.market,
      quantity: quantity,
    ));
  }

  /// Place limit buy order
  Future<SpotOrder> limitBuy(String symbol, double quantity, double price) async {
    return createOrder(CreateOrderRequest(
      symbol: symbol,
      side: OrderSide.buy,
      type: OrderType.limit,
      quantity: quantity,
      price: price,
    ));
  }

  /// Place limit sell order
  Future<SpotOrder> limitSell(String symbol, double quantity, double price) async {
    return createOrder(CreateOrderRequest(
      symbol: symbol,
      side: OrderSide.sell,
      type: OrderType.limit,
      quantity: quantity,
      price: price,
    ));
  }
}

/// Global trading service instance
final tradingService = TradingService();
