import 'package:flutter/material.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Fiat Provider model
class FiatProvider {
  final String id;
  final String name;
  final String logo;
  final Color color;
  final double feePercent;
  final double minAmount;
  final double maxAmount;
  final List<String> paymentMethods;
  final double rating;
  final List<String> supportedFiats;
  final List<String> supportedCryptos;
  final bool isActive;

  FiatProvider({
    required this.id,
    required this.name,
    required this.logo,
    required this.color,
    required this.feePercent,
    required this.minAmount,
    required this.maxAmount,
    required this.paymentMethods,
    required this.rating,
    required this.supportedFiats,
    required this.supportedCryptos,
    required this.isActive,
  });

  factory FiatProvider.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string
    Color parseColor(String? colorStr) {
      if (colorStr == null) return const Color(0xFF0066FF);
      colorStr = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$colorStr', radix: 16));
    }

    return FiatProvider(
      id: json['id'] ?? json['providerId'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? json['name']?.substring(0, 1) ?? 'P',
      color: parseColor(json['color']),
      feePercent: (json['feePercent'] ?? json['fee'] ?? 2.0).toDouble(),
      minAmount: (json['minAmount'] ?? json['min'] ?? 30).toDouble(),
      maxAmount: (json['maxAmount'] ?? json['max'] ?? 50000).toDouble(),
      paymentMethods: json['paymentMethods'] != null
          ? List<String>.from(json['paymentMethods'])
          : ['Card'],
      rating: (json['rating'] ?? 4.5).toDouble(),
      supportedFiats: json['supportedFiats'] != null
          ? List<String>.from(json['supportedFiats'])
          : ['USD', 'EUR', 'GBP'],
      supportedCryptos: json['supportedCryptos'] != null
          ? List<String>.from(json['supportedCryptos'])
          : ['BTC', 'ETH', 'USDT'],
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }

  String get feeString => '${feePercent.toStringAsFixed(1)}%';
  String get limitString => '\$${minAmount.toInt()} - \$${maxAmount.toInt()}';
}

/// Fiat Quote model
class FiatQuote {
  final String providerId;
  final String fiatCurrency;
  final String cryptoCurrency;
  final double fiatAmount;
  final double cryptoAmount;
  final double rate;
  final double fee;
  final double totalFiat;
  final DateTime expiresAt;

  FiatQuote({
    required this.providerId,
    required this.fiatCurrency,
    required this.cryptoCurrency,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.rate,
    required this.fee,
    required this.totalFiat,
    required this.expiresAt,
  });

  factory FiatQuote.fromJson(Map<String, dynamic> json) {
    return FiatQuote(
      providerId: json['providerId'] ?? '',
      fiatCurrency: json['fiatCurrency'] ?? json['fiat'] ?? 'USD',
      cryptoCurrency: json['cryptoCurrency'] ?? json['crypto'] ?? 'BTC',
      fiatAmount: (json['fiatAmount'] ?? 0).toDouble(),
      cryptoAmount: (json['cryptoAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      totalFiat: (json['totalFiat'] ?? json['total'] ?? 0).toDouble(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}

/// Fiat Order model
class FiatOrder {
  final String id;
  final String providerId;
  final String type; // buy, sell
  final String fiatCurrency;
  final String cryptoCurrency;
  final double fiatAmount;
  final double cryptoAmount;
  final double rate;
  final double fee;
  final String status; // pending, processing, completed, failed
  final String? paymentUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  FiatOrder({
    required this.id,
    required this.providerId,
    required this.type,
    required this.fiatCurrency,
    required this.cryptoCurrency,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.rate,
    required this.fee,
    required this.status,
    this.paymentUrl,
    required this.createdAt,
    this.completedAt,
  });

  factory FiatOrder.fromJson(Map<String, dynamic> json) {
    return FiatOrder(
      id: json['id'] ?? json['orderId'] ?? '',
      providerId: json['providerId'] ?? '',
      type: json['type'] ?? 'buy',
      fiatCurrency: json['fiatCurrency'] ?? json['fiat'] ?? 'USD',
      cryptoCurrency: json['cryptoCurrency'] ?? json['crypto'] ?? 'BTC',
      fiatAmount: (json['fiatAmount'] ?? 0).toDouble(),
      cryptoAmount: (json['cryptoAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentUrl: json['paymentUrl'] ?? json['redirectUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

/// Fiat Service - Handles all fiat on-ramp/off-ramp API calls
class FiatService {
  final ApiService _api = api;

  // Default providers (fallback if API fails)
  static final List<FiatProvider> defaultProviders = [
    FiatProvider(
      id: 'transak',
      name: 'Transak',
      logo: 'T',
      color: const Color(0xFF0066FF),
      feePercent: 1.5,
      minAmount: 50,
      maxAmount: 50000,
      paymentMethods: ['Card', 'Bank Transfer'],
      rating: 4.8,
      supportedFiats: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
      supportedCryptos: ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'],
      isActive: true,
    ),
    FiatProvider(
      id: 'moonpay',
      name: 'MoonPay',
      logo: 'M',
      color: const Color(0xFF7D00FF),
      feePercent: 2.0,
      minAmount: 30,
      maxAmount: 100000,
      paymentMethods: ['Card', 'Apple Pay', 'Bank'],
      rating: 4.7,
      supportedFiats: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
      supportedCryptos: ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'],
      isActive: true,
    ),
    FiatProvider(
      id: 'simplex',
      name: 'Simplex',
      logo: 'S',
      color: const Color(0xFFFF6B00),
      feePercent: 2.5,
      minAmount: 50,
      maxAmount: 20000,
      paymentMethods: ['Card'],
      rating: 4.5,
      supportedFiats: ['USD', 'EUR', 'GBP'],
      supportedCryptos: ['BTC', 'ETH', 'USDT', 'BNB'],
      isActive: true,
    ),
    FiatProvider(
      id: 'banxa',
      name: 'Banxa',
      logo: 'B',
      color: const Color(0xFF00B4D8),
      feePercent: 1.8,
      minAmount: 30,
      maxAmount: 15000,
      paymentMethods: ['Card', 'Bank', 'PIX'],
      rating: 4.6,
      supportedFiats: ['USD', 'EUR', 'GBP', 'BRL'],
      supportedCryptos: ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'],
      isActive: true,
    ),
  ];

  /// Get available fiat on-ramp providers
  Future<List<FiatProvider>> getProviders({String? fiat, String? crypto}) async {
    try {
      final response = await _api.get(
        ApiConfig.fiatProviders,
        queryParameters: {
          if (fiat != null) 'fiat': fiat,
          if (crypto != null) 'crypto': crypto,
        },
      );

      final List<dynamic> data = response['providers'] ?? response['items'] ?? [];
      if (data.isEmpty) {
        return defaultProviders;
      }
      return data.map((json) => FiatProvider.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching fiat providers: $e');
      return defaultProviders;
    }
  }

  /// Get quote for buy/sell
  Future<FiatQuote> getQuote({
    required String providerId,
    required String type, // buy, sell
    required String fiatCurrency,
    required String cryptoCurrency,
    required double amount,
  }) async {
    final response = await _api.post(
      ApiConfig.fiatQuote,
      data: {
        'providerId': providerId,
        'type': type,
        'fiatCurrency': fiatCurrency,
        'cryptoCurrency': cryptoCurrency,
        'amount': amount,
      },
    );
    return FiatQuote.fromJson(response['quote'] ?? response);
  }

  /// Create fiat order (initiate buy/sell)
  Future<FiatOrder> createOrder({
    required String providerId,
    required String type, // buy, sell
    required String fiatCurrency,
    required String cryptoCurrency,
    required double amount,
    String? paymentMethod,
  }) async {
    final response = await _api.post(
      ApiConfig.fiatOrder,
      data: {
        'providerId': providerId,
        'type': type,
        'fiatCurrency': fiatCurrency,
        'cryptoCurrency': cryptoCurrency,
        'amount': amount,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
    );
    return FiatOrder.fromJson(response['order'] ?? response);
  }

  /// Get order status
  Future<FiatOrder> getOrderStatus(String orderId) async {
    final response = await _api.get('${ApiConfig.fiatOrder}/$orderId');
    return FiatOrder.fromJson(response['order'] ?? response);
  }

  /// Get user's fiat orders history
  Future<List<FiatOrder>> getOrders({String? status, int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.fiatOrders,
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['orders'] ?? response['items'] ?? [];
    return data.map((json) => FiatOrder.fromJson(json)).toList();
  }

  /// Get supported currencies
  Future<Map<String, List<String>>> getSupportedCurrencies() async {
    try {
      final response = await _api.get(ApiConfig.fiatSupportedCurrencies);
      return {
        'fiat': List<String>.from(response['fiat'] ?? ['USD', 'EUR', 'GBP', 'CAD', 'AUD']),
        'crypto': List<String>.from(response['crypto'] ?? ['BTC', 'ETH', 'USDT', 'BNB', 'SOL']),
      };
    } catch (e) {
      return {
        'fiat': ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
        'crypto': ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'],
      };
    }
  }
}

/// Global fiat service instance
final fiatService = FiatService();
