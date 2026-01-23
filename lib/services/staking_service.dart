import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Staking Product model
class StakingProduct {
  final String id;
  final String name;
  final String token;
  final String chain;
  final double apy;
  final double minDeposit;
  final double maxDeposit;
  final int lockPeriodDays;
  final double availablePool;
  final bool isLiquid;
  final int validators;

  StakingProduct({
    required this.id,
    required this.name,
    required this.token,
    required this.chain,
    required this.apy,
    required this.minDeposit,
    required this.maxDeposit,
    required this.lockPeriodDays,
    required this.availablePool,
    required this.isLiquid,
    required this.validators,
  });

  factory StakingProduct.fromJson(Map<String, dynamic> json) {
    return StakingProduct(
      id: json['productId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['token'] ?? '',
      token: json['token'] ?? json['symbol'] ?? '',
      chain: json['chain'] ?? 'ETH',
      apy: (json['apy'] ?? 0).toDouble(),
      minDeposit: double.tryParse(json['minDeposit']?.toString() ?? '0') ?? 0,
      maxDeposit: double.tryParse(json['maxDeposit']?.toString() ?? '100000') ?? 100000,
      lockPeriodDays: json['lockPeriodDays'] ?? json['lockPeriod'] ?? 0,
      availablePool: double.tryParse(json['availablePool']?.toString() ?? json['tvl']?.toString() ?? '0') ?? 0,
      isLiquid: (json['lockPeriodDays'] ?? json['lockPeriod'] ?? 0) == 0,
      validators: json['validators'] ?? 100,
    );
  }
}

/// Staking Position model
class StakingPosition {
  final String id;
  final String productId;
  final String productName;
  final String token;
  final double amount;
  final double apy;
  final int lockPeriodDays;
  final String status;
  final double accruedInterest;
  final double totalValue;
  final DateTime depositedAt;
  final DateTime? maturesAt;

  StakingPosition({
    required this.id,
    required this.productId,
    required this.productName,
    required this.token,
    required this.amount,
    required this.apy,
    required this.lockPeriodDays,
    required this.status,
    required this.accruedInterest,
    required this.totalValue,
    required this.depositedAt,
    this.maturesAt,
  });

  factory StakingPosition.fromJson(Map<String, dynamic> json) {
    return StakingPosition(
      id: json['depositId'] ?? json['positionId'] ?? json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      token: json['token'] ?? json['symbol'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      apy: (json['apy'] ?? 0).toDouble(),
      lockPeriodDays: json['lockPeriodDays'] ?? json['lockPeriod'] ?? 0,
      status: json['status'] ?? 'active',
      accruedInterest: double.tryParse(json['accruedInterest']?.toString() ?? json['rewards']?.toString() ?? '0') ?? 0,
      totalValue: double.tryParse(json['totalValue']?.toString() ?? '0') ?? 0,
      depositedAt: json['depositedAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['depositedAt'] ?? json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      maturesAt: json['maturesAt'] != null ? DateTime.tryParse(json['maturesAt']) : null,
    );
  }
}

/// Staking Service
class StakingService {
  final ApiService _api = api;

  /// Get staking products
  Future<List<StakingProduct>> getProducts() async {
    try {
      final response = await _api.get(ApiConfig.stakingProducts);
      final List<dynamic> data = response['products'] ?? response['items'] ?? response['data'] ?? [];
      return data.map((json) => StakingProduct.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Staking products failed, trying savings: $e');
      try {
        final response = await _api.get(ApiConfig.savingsProducts);
        final List<dynamic> data = response['products'] ?? response['items'] ?? response['data'] ?? [];
        return data.map((json) => StakingProduct.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('Savings products also failed: $e2');
        return [];
      }
    }
  }

  /// Get user's staking positions
  Future<List<StakingPosition>> getPositions() async {
    try {
      final response = await _api.get(ApiConfig.stakingPositions);
      final List<dynamic> data = response['positions'] ?? response['items'] ?? response['data'] ?? [];
      return data.map((json) => StakingPosition.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Staking positions failed, trying savings: $e');
      try {
        final response = await _api.get(ApiConfig.savingsDeposits);
        final List<dynamic> data = response['deposits'] ?? response['items'] ?? response['data'] ?? [];
        return data.map((json) => StakingPosition.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('Savings deposits also failed: $e2');
        return [];
      }
    }
  }

  /// Stake/subscribe to a product
  Future<StakingPosition> stake({required String productId, required double amount}) async {
    try {
      final response = await _api.post(
        ApiConfig.stakingStake,
        data: {'productId': productId, 'amount': amount.toString()},
      );
      final data = response['position'] ?? response['deposit'] ?? response;
      return StakingPosition.fromJson(data);
    } catch (e) {
      final response = await _api.post(
        ApiConfig.savingsDeposit,
        data: {'productId': productId, 'amount': amount.toString()},
      );
      final data = response['deposit'] ?? response;
      return StakingPosition.fromJson(data);
    }
  }

  /// Unstake/withdraw from a position
  Future<Map<String, dynamic>> unstake(String positionId) async {
    try {
      return await _api.post(ApiConfig.stakingUnstake, data: {'positionId': positionId});
    } catch (e) {
      return await _api.post(ApiConfig.savingsWithdraw, data: {'depositId': positionId});
    }
  }

  /// Get staking summary
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final positions = await getPositions();
      double totalStaked = 0;
      double totalRewards = 0;
      double avgApy = 0;

      if (positions.isNotEmpty) {
        for (final pos in positions) {
          totalStaked += pos.totalValue > 0 ? pos.totalValue : pos.amount;
          totalRewards += pos.accruedInterest;
          avgApy += pos.apy;
        }
        avgApy = avgApy / positions.length;
      }

      return {
        'totalStaked': totalStaked,
        'totalRewards': totalRewards,
        'avgApy': avgApy,
        'activePositions': positions.length,
      };
    } catch (e) {
      return {'totalStaked': 0.0, 'totalRewards': 0.0, 'avgApy': 0.0, 'activePositions': 0};
    }
  }
}

/// Global staking service instance
final stakingService = StakingService();
