import 'package:flutter_test/flutter_test.dart';
import 'package:crymadx/services/portfolio_service.dart';

void main() {
  group('PortfolioAsset', () {
    test('fromJson parses asset correctly', () {
      final json = {
        'id': 'btc-1',
        'symbol': 'BTC',
        'name': 'Bitcoin',
        'balance': 1.5,
        'price': 45000.0,
        'value': 67500.0,
        'change24h': 500.0,
        'changePercent24h': 1.12,
        'allocation': 60.0,
        'averageBuyPrice': 40000.0,
        'profitLoss': 7500.0,
        'profitLossPercent': 12.5,
      };

      final asset = PortfolioAsset.fromJson(json);

      expect(asset.id, 'btc-1');
      expect(asset.symbol, 'BTC');
      expect(asset.name, 'Bitcoin');
      expect(asset.balance, 1.5);
      expect(asset.price, 45000.0);
      expect(asset.value, 67500.0);
      expect(asset.change24h, 500.0);
      expect(asset.changePercent24h, 1.12);
      expect(asset.allocation, 60.0);
      expect(asset.averageBuyPrice, 40000.0);
      expect(asset.profitLoss, 7500.0);
      expect(asset.profitLossPercent, 12.5);
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'assetId': 'eth-1',
        'asset': 'ETH',
        'assetName': 'Ethereum',
        'amount': 10.0,
        'currentPrice': 3000.0,
        'totalValue': 30000.0,
      };

      final asset = PortfolioAsset.fromJson(json);

      expect(asset.id, 'eth-1');
      expect(asset.symbol, 'ETH');
      expect(asset.name, 'Ethereum');
      expect(asset.balance, 10.0);
      expect(asset.price, 3000.0);
      expect(asset.value, 30000.0);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {'symbol': 'BTC'};

      final asset = PortfolioAsset.fromJson(json);

      expect(asset.symbol, 'BTC');
      expect(asset.balance, 0);
      expect(asset.price, 0);
      expect(asset.value, 0);
      expect(asset.change24h, 0);
    });

    test('toJson serializes correctly', () {
      final asset = PortfolioAsset(
        id: 'btc-1',
        symbol: 'BTC',
        name: 'Bitcoin',
        balance: 1.5,
        price: 45000.0,
        value: 67500.0,
      );

      final json = asset.toJson();

      expect(json['id'], 'btc-1');
      expect(json['symbol'], 'BTC');
      expect(json['balance'], 1.5);
      expect(json['value'], 67500.0);
    });
  });

  group('PortfolioPerformance', () {
    test('fromJson parses performance correctly', () {
      final json = {
        'totalValue': 100000.0,
        'totalChange24h': 1500.0,
        'totalChangePercent24h': 1.5,
        'totalProfitLoss': 15000.0,
        'totalProfitLossPercent': 17.6,
        'totalInvested': 85000.0,
        'history': [
          {'timestamp': '2024-01-01T00:00:00Z', 'value': 98000.0},
          {'timestamp': '2024-01-02T00:00:00Z', 'value': 100000.0},
        ],
      };

      final performance = PortfolioPerformance.fromJson(json);

      expect(performance.totalValue, 100000.0);
      expect(performance.totalChange24h, 1500.0);
      expect(performance.totalChangePercent24h, 1.5);
      expect(performance.totalProfitLoss, 15000.0);
      expect(performance.history.length, 2);
    });

    test('fromJson handles missing fields', () {
      final json = {'totalValue': 50000.0};

      final performance = PortfolioPerformance.fromJson(json);

      expect(performance.totalValue, 50000.0);
      expect(performance.totalChange24h, 0);
      expect(performance.history, isEmpty);
    });
  });

  group('PerformancePoint', () {
    test('fromJson parses timestamp correctly', () {
      final json = {
        'timestamp': '2024-01-01T12:00:00Z',
        'value': 50000.0,
      };

      final point = PerformancePoint.fromJson(json);

      expect(point.value, 50000.0);
      expect(point.timestamp.year, 2024);
      expect(point.timestamp.month, 1);
      expect(point.timestamp.day, 1);
    });

    test('fromJson handles millisecond timestamp', () {
      final json = {
        'time': 1704067200000, // 2024-01-01 00:00:00 UTC
        'price': 45000.0,
      };

      final point = PerformancePoint.fromJson(json);

      expect(point.value, 45000.0);
    });
  });

  group('PortfolioAllocation', () {
    test('fromJson parses allocation correctly', () {
      final json = {
        'category': 'Bitcoin',
        'color': '#F7931A',
        'value': 67500.0,
        'percentage': 60.0,
        'assets': [
          {'symbol': 'BTC', 'balance': 1.5, 'value': 67500.0, 'price': 45000.0, 'id': '1', 'name': 'Bitcoin'},
        ],
      };

      final allocation = PortfolioAllocation.fromJson(json);

      expect(allocation.category, 'Bitcoin');
      expect(allocation.color, '#F7931A');
      expect(allocation.value, 67500.0);
      expect(allocation.percentage, 60.0);
      expect(allocation.assets.length, 1);
    });
  });

  group('PortfolioTransaction', () {
    test('fromJson parses transaction correctly', () {
      final json = {
        'id': 'tx-1',
        'type': 'buy',
        'asset': 'BTC',
        'amount': 0.5,
        'price': 44000.0,
        'value': 22000.0,
        'fee': 22.0,
        'timestamp': '2024-01-01T12:00:00Z',
        'status': 'completed',
      };

      final tx = PortfolioTransaction.fromJson(json);

      expect(tx.id, 'tx-1');
      expect(tx.type, 'buy');
      expect(tx.asset, 'BTC');
      expect(tx.amount, 0.5);
      expect(tx.price, 44000.0);
      expect(tx.value, 22000.0);
      expect(tx.fee, 22.0);
      expect(tx.status, 'completed');
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'transactionId': 'tx-2',
        'action': 'sell',
        'symbol': 'ETH',
        'quantity': 5.0,
      };

      final tx = PortfolioTransaction.fromJson(json);

      expect(tx.id, 'tx-2');
      expect(tx.type, 'sell');
      expect(tx.asset, 'ETH');
      expect(tx.amount, 5.0);
    });
  });

  group('PortfolioService', () {
    late PortfolioService service;

    setUp(() {
      service = PortfolioService();
    });

    test('calculateMetrics returns empty performance for empty assets', () {
      final performance = service.calculateMetrics([]);

      expect(performance.totalValue, 0);
      expect(performance.totalChange24h, 0);
      expect(performance.totalProfitLoss, 0);
    });

    test('calculateMetrics calculates total value correctly', () {
      final assets = [
        PortfolioAsset(id: '1', symbol: 'BTC', name: 'Bitcoin', balance: 1.0, price: 45000.0, value: 45000.0),
        PortfolioAsset(id: '2', symbol: 'ETH', name: 'Ethereum', balance: 10.0, price: 3000.0, value: 30000.0),
      ];

      final performance = service.calculateMetrics(assets);

      expect(performance.totalValue, 75000.0);
    });

    test('calculateAllocation returns empty for empty assets', () {
      final allocations = service.calculateAllocation([]);

      expect(allocations, isEmpty);
    });

    test('calculateAllocation calculates percentages correctly', () {
      final assets = [
        PortfolioAsset(id: '1', symbol: 'BTC', name: 'Bitcoin', balance: 1.0, price: 75000.0, value: 75000.0),
        PortfolioAsset(id: '2', symbol: 'ETH', name: 'Ethereum', balance: 10.0, price: 2500.0, value: 25000.0),
      ];

      final allocations = service.calculateAllocation(assets);

      expect(allocations.length, 2);
      expect(allocations[0].category, 'BTC'); // BTC should be first (higher value)
      expect(allocations[0].percentage, 75.0);
      expect(allocations[1].category, 'ETH');
      expect(allocations[1].percentage, 25.0);
    });

    test('portfolioService global instance is available', () {
      expect(portfolioService, isNotNull);
      expect(portfolioService, isA<PortfolioService>());
    });
  });
}
