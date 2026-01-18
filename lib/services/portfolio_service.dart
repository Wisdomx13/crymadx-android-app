import 'api_service.dart';
import '../config/api_config.dart';

/// Portfolio Asset model
class PortfolioAsset {
  final String id;
  final String symbol;
  final String name;
  final double balance;
  final double price;
  final double value;
  final double change24h;
  final double changePercent24h;
  final double allocation;
  final double averageBuyPrice;
  final double profitLoss;
  final double profitLossPercent;

  PortfolioAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.balance,
    required this.price,
    required this.value,
    this.change24h = 0,
    this.changePercent24h = 0,
    this.allocation = 0,
    this.averageBuyPrice = 0,
    this.profitLoss = 0,
    this.profitLossPercent = 0,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      id: json['id'] ?? json['assetId'] ?? '',
      symbol: json['symbol'] ?? json['asset'] ?? '',
      name: json['name'] ?? json['assetName'] ?? '',
      balance: (json['balance'] ?? json['amount'] ?? 0).toDouble(),
      price: (json['price'] ?? json['currentPrice'] ?? 0).toDouble(),
      value: (json['value'] ?? json['totalValue'] ?? 0).toDouble(),
      change24h: (json['change24h'] ?? json['priceChange'] ?? 0).toDouble(),
      changePercent24h: (json['changePercent24h'] ?? json['priceChangePercent'] ?? 0).toDouble(),
      allocation: (json['allocation'] ?? json['allocationPercent'] ?? 0).toDouble(),
      averageBuyPrice: (json['averageBuyPrice'] ?? json['avgPrice'] ?? 0).toDouble(),
      profitLoss: (json['profitLoss'] ?? json['pnl'] ?? 0).toDouble(),
      profitLossPercent: (json['profitLossPercent'] ?? json['pnlPercent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'balance': balance,
    'price': price,
    'value': value,
    'change24h': change24h,
    'changePercent24h': changePercent24h,
    'allocation': allocation,
    'averageBuyPrice': averageBuyPrice,
    'profitLoss': profitLoss,
    'profitLossPercent': profitLossPercent,
  };
}

/// Portfolio Performance model
class PortfolioPerformance {
  final double totalValue;
  final double totalChange24h;
  final double totalChangePercent24h;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final double totalInvested;
  final List<PerformancePoint> history;

  PortfolioPerformance({
    required this.totalValue,
    this.totalChange24h = 0,
    this.totalChangePercent24h = 0,
    this.totalProfitLoss = 0,
    this.totalProfitLossPercent = 0,
    this.totalInvested = 0,
    this.history = const [],
  });

  factory PortfolioPerformance.fromJson(Map<String, dynamic> json) {
    return PortfolioPerformance(
      totalValue: (json['totalValue'] ?? json['value'] ?? 0).toDouble(),
      totalChange24h: (json['totalChange24h'] ?? json['change24h'] ?? 0).toDouble(),
      totalChangePercent24h: (json['totalChangePercent24h'] ?? json['changePercent24h'] ?? 0).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] ?? json['pnl'] ?? 0).toDouble(),
      totalProfitLossPercent: (json['totalProfitLossPercent'] ?? json['pnlPercent'] ?? 0).toDouble(),
      totalInvested: (json['totalInvested'] ?? json['invested'] ?? 0).toDouble(),
      history: (json['history'] as List? ?? [])
          .map((p) => PerformancePoint.fromJson(p))
          .toList(),
    );
  }
}

/// Performance Point for charting
class PerformancePoint {
  final DateTime timestamp;
  final double value;

  PerformancePoint({
    required this.timestamp,
    required this.value,
  });

  factory PerformancePoint.fromJson(Map<String, dynamic> json) {
    return PerformancePoint(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      value: (json['value'] ?? json['price'] ?? 0).toDouble(),
    );
  }
}

/// Portfolio Allocation by category
class PortfolioAllocation {
  final String category;
  final String color;
  final double value;
  final double percentage;
  final List<PortfolioAsset> assets;

  PortfolioAllocation({
    required this.category,
    required this.color,
    required this.value,
    required this.percentage,
    this.assets = const [],
  });

  factory PortfolioAllocation.fromJson(Map<String, dynamic> json) {
    return PortfolioAllocation(
      category: json['category'] ?? json['type'] ?? '',
      color: json['color'] ?? '#00D4AA',
      value: (json['value'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? json['percent'] ?? 0).toDouble(),
      assets: (json['assets'] as List? ?? [])
          .map((a) => PortfolioAsset.fromJson(a))
          .toList(),
    );
  }
}

/// Transaction for portfolio history
class PortfolioTransaction {
  final String id;
  final String type; // buy, sell, deposit, withdraw, transfer
  final String asset;
  final double amount;
  final double price;
  final double value;
  final double fee;
  final DateTime timestamp;
  final String status;

  PortfolioTransaction({
    required this.id,
    required this.type,
    required this.asset,
    required this.amount,
    this.price = 0,
    this.value = 0,
    this.fee = 0,
    required this.timestamp,
    this.status = 'completed',
  });

  factory PortfolioTransaction.fromJson(Map<String, dynamic> json) {
    return PortfolioTransaction(
      id: json['id'] ?? json['transactionId'] ?? '',
      type: json['type'] ?? json['action'] ?? '',
      asset: json['asset'] ?? json['symbol'] ?? '',
      amount: (json['amount'] ?? json['quantity'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      value: (json['value'] ?? json['total'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      status: json['status'] ?? 'completed',
    );
  }
}

/// Portfolio Service - Handles portfolio management
class PortfolioService {
  final ApiService _api = api;

  /// Get portfolio overview with all assets
  Future<List<PortfolioAsset>> getPortfolioAssets() async {
    try {
      final response = await _api.get('${ApiConfig.baseUrl}/portfolio/assets');
      final List<dynamic> data = response['assets'] ?? response['data'] ?? [];
      return data.map((json) => PortfolioAsset.fromJson(json)).toList();
    } catch (e) {
      // Fallback to balance endpoint if portfolio endpoint not available
      final response = await _api.get(ApiConfig.balanceList);
      final List<dynamic> data = response['balances'] ?? response['data'] ?? [];
      return data.map((json) => PortfolioAsset.fromJson(json)).toList();
    }
  }

  /// Get portfolio performance summary
  Future<PortfolioPerformance> getPerformance({String period = '24h'}) async {
    try {
      final response = await _api.get(
        '${ApiConfig.baseUrl}/portfolio/performance',
        queryParameters: {'period': period},
      );
      return PortfolioPerformance.fromJson(response);
    } catch (e) {
      // Return empty performance if endpoint not available
      return PortfolioPerformance(totalValue: 0);
    }
  }

  /// Get portfolio history for charts
  Future<List<PerformancePoint>> getPortfolioHistory({
    String period = '7d',
    String interval = '1h',
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.baseUrl}/portfolio/history',
        queryParameters: {'period': period, 'interval': interval},
      );
      final List<dynamic> data = response['history'] ?? response['data'] ?? [];
      return data.map((json) => PerformancePoint.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get portfolio allocation breakdown
  Future<List<PortfolioAllocation>> getAllocation() async {
    try {
      final response = await _api.get('${ApiConfig.baseUrl}/portfolio/allocation');
      final List<dynamic> data = response['allocation'] ?? response['data'] ?? [];
      return data.map((json) => PortfolioAllocation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get transaction history
  Future<List<PortfolioTransaction>> getTransactions({
    String? asset,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.baseUrl}/portfolio/transactions',
        queryParameters: {
          if (asset != null) 'asset': asset,
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );
      final List<dynamic> data = response['transactions'] ?? response['data'] ?? [];
      return data.map((json) => PortfolioTransaction.fromJson(json)).toList();
    } catch (e) {
      // Fallback to transfers endpoint
      final response = await _api.get(ApiConfig.balanceTransfers);
      final List<dynamic> data = response['transfers'] ?? response['data'] ?? [];
      return data.map((json) => PortfolioTransaction.fromJson(json)).toList();
    }
  }

  /// Get portfolio statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.get('${ApiConfig.baseUrl}/portfolio/statistics');
      return response;
    } catch (e) {
      return {};
    }
  }

  /// Calculate portfolio metrics from assets
  PortfolioPerformance calculateMetrics(List<PortfolioAsset> assets) {
    if (assets.isEmpty) {
      return PortfolioPerformance(totalValue: 0);
    }

    double totalValue = 0;
    double totalChange24h = 0;
    double totalProfitLoss = 0;
    double totalInvested = 0;

    for (final asset in assets) {
      totalValue += asset.value;
      totalChange24h += asset.change24h * asset.balance;
      totalProfitLoss += asset.profitLoss;
      totalInvested += asset.averageBuyPrice * asset.balance;
    }

    return PortfolioPerformance(
      totalValue: totalValue,
      totalChange24h: totalChange24h,
      totalChangePercent24h: totalValue > 0 ? (totalChange24h / totalValue) * 100 : 0,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercent: totalInvested > 0 ? (totalProfitLoss / totalInvested) * 100 : 0,
      totalInvested: totalInvested,
    );
  }

  /// Calculate allocation percentages
  List<PortfolioAllocation> calculateAllocation(List<PortfolioAsset> assets) {
    if (assets.isEmpty) return [];

    final double totalValue = assets.fold(0, (sum, a) => sum + a.value);
    if (totalValue == 0) return [];

    // Group by asset type (simplified - just creates individual allocations)
    final allocations = <PortfolioAllocation>[];
    final colors = ['#00D4AA', '#FFD700', '#FF6B6B', '#4169E1', '#9B59B6', '#1ABC9C', '#E74C3C', '#3498DB'];

    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i];
      if (asset.value > 0) {
        allocations.add(PortfolioAllocation(
          category: asset.symbol,
          color: colors[i % colors.length],
          value: asset.value,
          percentage: (asset.value / totalValue) * 100,
          assets: [asset],
        ));
      }
    }

    // Sort by value descending
    allocations.sort((a, b) => b.value.compareTo(a.value));

    return allocations;
  }
}

/// Global portfolio service instance
final portfolioService = PortfolioService();
