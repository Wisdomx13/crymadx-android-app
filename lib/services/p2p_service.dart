import 'api_service.dart';
import '../config/api_config.dart';

/// P2P Order model - matches backend /api/p2p/orders
class P2POrder {
  final String id;
  final String type; // buy, sell
  final String currency;
  final String fiatCurrency;
  final double price;
  final double amount;
  final double minAmount;
  final double maxAmount;
  final List<String> paymentMethods;
  final String status; // active, completed, cancelled
  final String? merchantId;
  final String? merchantName;
  final double? merchantRating;
  final int? merchantTrades;
  final DateTime createdAt;
  final DateTime? expiresAt;

  P2POrder({
    required this.id,
    required this.type,
    required this.currency,
    required this.fiatCurrency,
    required this.price,
    required this.amount,
    required this.minAmount,
    required this.maxAmount,
    required this.paymentMethods,
    required this.status,
    this.merchantId,
    this.merchantName,
    this.merchantRating,
    this.merchantTrades,
    required this.createdAt,
    this.expiresAt,
  });

  factory P2POrder.fromJson(Map<String, dynamic> json) {
    return P2POrder(
      id: json['id'] ?? json['orderId'] ?? '',
      type: json['type'] ?? json['side'] ?? 'buy',
      currency: json['currency'] ?? json['crypto'] ?? '',
      fiatCurrency: json['fiatCurrency'] ?? json['fiat'] ?? 'USD',
      price: (json['price'] ?? 0).toDouble(),
      amount: (json['amount'] ?? json['quantity'] ?? 0).toDouble(),
      minAmount: (json['minAmount'] ?? json['minLimit'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? json['maxLimit'] ?? 0).toDouble(),
      paymentMethods: List<String>.from(json['paymentMethods'] ?? json['methods'] ?? []),
      status: json['status'] ?? 'active',
      merchantId: json['merchantId'] ?? json['userId'],
      merchantName: json['merchantName'] ?? json['merchant']?['name'],
      merchantRating: json['merchantRating'] != null
          ? (json['merchantRating']).toDouble()
          : json['merchant']?['rating']?.toDouble(),
      merchantTrades: json['merchantTrades'] ?? json['merchant']?['totalTrades'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }
}

/// P2P Trade model - matches backend /api/p2p/trades
class P2PTrade {
  final String id;
  final String orderId;
  final String type; // buy, sell
  final String currency;
  final String fiatCurrency;
  final double price;
  final double amount;
  final double total;
  final String status; // pending, paid, released, completed, cancelled, disputed
  final String? paymentMethod;
  final String? buyerId;
  final String? buyerName;
  final String? sellerId;
  final String? sellerName;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? releasedAt;
  final DateTime? completedAt;
  final String? chatId;
  final Map<String, dynamic>? paymentDetails;

  P2PTrade({
    required this.id,
    required this.orderId,
    required this.type,
    required this.currency,
    required this.fiatCurrency,
    required this.price,
    required this.amount,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.buyerId,
    this.buyerName,
    this.sellerId,
    this.sellerName,
    required this.createdAt,
    this.paidAt,
    this.releasedAt,
    this.completedAt,
    this.chatId,
    this.paymentDetails,
  });

  factory P2PTrade.fromJson(Map<String, dynamic> json) {
    return P2PTrade(
      id: json['id'] ?? json['tradeId'] ?? '',
      orderId: json['orderId'] ?? '',
      type: json['type'] ?? json['side'] ?? 'buy',
      currency: json['currency'] ?? json['crypto'] ?? '',
      fiatCurrency: json['fiatCurrency'] ?? json['fiat'] ?? 'USD',
      price: (json['price'] ?? 0).toDouble(),
      amount: (json['amount'] ?? json['quantity'] ?? 0).toDouble(),
      total: (json['total'] ?? json['fiatAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? json['method'],
      buyerId: json['buyerId'] ?? json['buyer']?['id'],
      buyerName: json['buyerName'] ?? json['buyer']?['name'],
      sellerId: json['sellerId'] ?? json['seller']?['id'],
      sellerName: json['sellerName'] ?? json['seller']?['name'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      releasedAt: json['releasedAt'] != null ? DateTime.parse(json['releasedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      chatId: json['chatId'],
      paymentDetails: json['paymentDetails'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isReleased => status == 'released';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isDisputed => status == 'disputed';
}

/// P2P Payment Method model
class P2PPaymentMethod {
  final String id;
  final String type; // bank_transfer, mobile_money, paypal, etc.
  final String name;
  final Map<String, dynamic> details;
  final bool isDefault;
  final DateTime createdAt;

  P2PPaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.details,
    required this.isDefault,
    required this.createdAt,
  });

  factory P2PPaymentMethod.fromJson(Map<String, dynamic> json) {
    return P2PPaymentMethod(
      id: json['id'] ?? json['methodId'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? json['methodName'] ?? '',
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      isDefault: json['isDefault'] ?? json['default'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// P2P Service - Handles all P2P trading API calls
class P2PService {
  final ApiService _api = api;

  // ============================================
  // P2P ORDERS (Marketplace)
  // ============================================

  /// Get P2P orders (marketplace listings)
  Future<List<P2POrder>> getOrders({
    String? type, // buy, sell
    String? currency,
    String? fiatCurrency,
    String? paymentMethod,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.p2pOrders,
      queryParameters: {
        if (type != null) 'type': type,
        if (currency != null) 'currency': currency,
        if (fiatCurrency != null) 'fiatCurrency': fiatCurrency,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['orders'] ?? response['items'] ?? [];
    return data.map((json) => P2POrder.fromJson(json)).toList();
  }

  /// Get single order details
  Future<P2POrder> getOrder(String orderId) async {
    final response = await _api.get('${ApiConfig.p2pOrders}/$orderId');
    final orderData = response['order'] ?? response;
    return P2POrder.fromJson(orderData);
  }

  /// Create P2P order (post ad)
  Future<P2POrder> createOrder({
    required String type, // buy, sell
    required String currency,
    required String fiatCurrency,
    required double price,
    required double amount,
    required double minAmount,
    required double maxAmount,
    required List<String> paymentMethods,
    String? terms,
  }) async {
    final response = await _api.post(
      ApiConfig.p2pOrders,
      data: {
        'type': type,
        'currency': currency,
        'fiatCurrency': fiatCurrency,
        'price': price,
        'amount': amount,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
        'paymentMethods': paymentMethods,
        if (terms != null) 'terms': terms,
      },
    );
    final orderData = response['order'] ?? response;
    return P2POrder.fromJson(orderData);
  }

  /// Cancel P2P order
  Future<void> cancelOrder(String orderId) async {
    await _api.delete('${ApiConfig.p2pOrders}/$orderId');
  }

  /// Get my P2P orders
  Future<List<P2POrder>> getMyOrders({String? status, int page = 1, int limit = 20}) async {
    final response = await _api.get(
      '${ApiConfig.p2pOrders}/my',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['orders'] ?? response['items'] ?? [];
    return data.map((json) => P2POrder.fromJson(json)).toList();
  }

  // ============================================
  // P2P TRADES
  // ============================================

  /// Get my P2P trades
  Future<List<P2PTrade>> getTrades({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.p2pTrades,
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['trades'] ?? response['items'] ?? [];
    return data.map((json) => P2PTrade.fromJson(json)).toList();
  }

  /// Get single trade details
  Future<P2PTrade> getTrade(String tradeId) async {
    final response = await _api.get('${ApiConfig.p2pTrades}/$tradeId');
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  /// Initiate trade (accept an order)
  Future<P2PTrade> initiateTrade({
    required String orderId,
    required double amount,
    required String paymentMethodId,
  }) async {
    final response = await _api.post(
      ApiConfig.p2pTrades,
      data: {
        'orderId': orderId,
        'amount': amount,
        'paymentMethodId': paymentMethodId,
      },
    );
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  /// Mark trade as paid (buyer action)
  Future<P2PTrade> markAsPaid(String tradeId) async {
    final response = await _api.post('${ApiConfig.p2pTrades}/$tradeId/paid');
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  /// Release crypto (seller action after confirming payment)
  Future<P2PTrade> releaseCrypto(String tradeId) async {
    final response = await _api.post('${ApiConfig.p2pTrades}/$tradeId/release');
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  /// Cancel trade
  Future<P2PTrade> cancelTrade(String tradeId, {String? reason}) async {
    final response = await _api.post(
      '${ApiConfig.p2pTrades}/$tradeId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  /// Open dispute
  Future<P2PTrade> openDispute(String tradeId, String reason) async {
    final response = await _api.post(
      '${ApiConfig.p2pTrades}/$tradeId/dispute',
      data: {'reason': reason},
    );
    final tradeData = response['trade'] ?? response;
    return P2PTrade.fromJson(tradeData);
  }

  // ============================================
  // PAYMENT METHODS
  // ============================================

  /// Get my payment methods
  Future<List<P2PPaymentMethod>> getPaymentMethods() async {
    final response = await _api.get('${ApiConfig.p2p}/payment-methods');
    final List<dynamic> data = response['methods'] ?? response['paymentMethods'] ?? [];
    return data.map((json) => P2PPaymentMethod.fromJson(json)).toList();
  }

  /// Add payment method
  Future<P2PPaymentMethod> addPaymentMethod({
    required String type,
    required String name,
    required Map<String, dynamic> details,
    bool isDefault = false,
  }) async {
    final response = await _api.post(
      '${ApiConfig.p2p}/payment-methods',
      data: {
        'type': type,
        'name': name,
        'details': details,
        'isDefault': isDefault,
      },
    );
    final methodData = response['method'] ?? response;
    return P2PPaymentMethod.fromJson(methodData);
  }

  /// Remove payment method
  Future<void> removePaymentMethod(String methodId) async {
    await _api.delete('${ApiConfig.p2p}/payment-methods/$methodId');
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get supported fiat currencies
  Future<List<String>> getSupportedFiatCurrencies() async {
    final response = await _api.get('${ApiConfig.p2p}/fiat-currencies');
    final List<dynamic> data = response['currencies'] ?? [];
    return data.cast<String>();
  }

  /// Get supported payment method types
  Future<List<Map<String, dynamic>>> getPaymentMethodTypes() async {
    final response = await _api.get('${ApiConfig.p2p}/payment-method-types');
    final List<dynamic> data = response['types'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}

/// Global P2P service instance
final p2pService = P2PService();
