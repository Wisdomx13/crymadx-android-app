import 'api_service.dart';
import '../config/api_config.dart';

/// Savings Product model - matches backend /api/savings/products
class SavingsProduct {
  final String id;
  final String currency;
  final String name;
  final String type; // flexible, fixed
  final double apy;
  final double minAmount;
  final double maxAmount;
  final int? lockDays;
  final bool isActive;
  final String? description;
  final double? totalDeposited;
  final double? availableQuota;

  SavingsProduct({
    required this.id,
    required this.currency,
    required this.name,
    required this.type,
    required this.apy,
    required this.minAmount,
    required this.maxAmount,
    this.lockDays,
    required this.isActive,
    this.description,
    this.totalDeposited,
    this.availableQuota,
  });

  factory SavingsProduct.fromJson(Map<String, dynamic> json) {
    return SavingsProduct(
      id: json['id'] ?? json['productId'] ?? '',
      currency: json['currency'] ?? json['asset'] ?? '',
      name: json['name'] ?? json['productName'] ?? '',
      type: json['type'] ?? 'flexible',
      apy: (json['apy'] ?? json['interestRate'] ?? 0).toDouble(),
      minAmount: (json['minAmount'] ?? json['minDeposit'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? json['maxDeposit'] ?? 0).toDouble(),
      lockDays: json['lockDays'] ?? json['duration'],
      isActive: json['isActive'] ?? json['active'] ?? true,
      description: json['description'],
      totalDeposited: json['totalDeposited'] != null
          ? (json['totalDeposited']).toDouble()
          : null,
      availableQuota: json['availableQuota'] != null
          ? (json['availableQuota']).toDouble()
          : null,
    );
  }

  bool get isFlexible => type == 'flexible';
  bool get isFixed => type == 'fixed';
}

/// Savings Deposit model - matches backend /api/savings/deposits
class SavingsDeposit {
  final String id;
  final String productId;
  final String currency;
  final double amount;
  final double apy;
  final double accruedInterest;
  final String status; // active, matured, redeemed
  final DateTime createdAt;
  final DateTime? maturityDate;
  final DateTime? redeemedAt;
  final bool autoRenew;

  SavingsDeposit({
    required this.id,
    required this.productId,
    required this.currency,
    required this.amount,
    required this.apy,
    required this.accruedInterest,
    required this.status,
    required this.createdAt,
    this.maturityDate,
    this.redeemedAt,
    required this.autoRenew,
  });

  factory SavingsDeposit.fromJson(Map<String, dynamic> json) {
    return SavingsDeposit(
      id: json['id'] ?? json['depositId'] ?? '',
      productId: json['productId'] ?? '',
      currency: json['currency'] ?? json['asset'] ?? '',
      amount: (json['amount'] ?? json['principal'] ?? 0).toDouble(),
      apy: (json['apy'] ?? json['interestRate'] ?? 0).toDouble(),
      accruedInterest: (json['accruedInterest'] ?? json['interest'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      maturityDate: json['maturityDate'] != null
          ? DateTime.parse(json['maturityDate'])
          : null,
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : null,
      autoRenew: json['autoRenew'] ?? false,
    );
  }

  double get totalValue => amount + accruedInterest;
  bool get isActive => status == 'active';
  bool get isMatured => status == 'matured';
}

/// Staking Product model - matches backend /api/staking/products
class StakingProduct {
  final String id;
  final String currency;
  final String name;
  final double apy;
  final double minStake;
  final double maxStake;
  final int lockDays;
  final int unbondingDays;
  final bool isActive;
  final String? description;
  final String? validator;
  final double? totalStaked;

  StakingProduct({
    required this.id,
    required this.currency,
    required this.name,
    required this.apy,
    required this.minStake,
    required this.maxStake,
    required this.lockDays,
    required this.unbondingDays,
    required this.isActive,
    this.description,
    this.validator,
    this.totalStaked,
  });

  factory StakingProduct.fromJson(Map<String, dynamic> json) {
    return StakingProduct(
      id: json['id'] ?? json['productId'] ?? '',
      currency: json['currency'] ?? json['asset'] ?? '',
      name: json['name'] ?? json['productName'] ?? '',
      apy: (json['apy'] ?? json['rewardRate'] ?? 0).toDouble(),
      minStake: (json['minStake'] ?? json['minAmount'] ?? 0).toDouble(),
      maxStake: (json['maxStake'] ?? json['maxAmount'] ?? 0).toDouble(),
      lockDays: json['lockDays'] ?? json['stakingPeriod'] ?? 0,
      unbondingDays: json['unbondingDays'] ?? json['unbondingPeriod'] ?? 0,
      isActive: json['isActive'] ?? json['active'] ?? true,
      description: json['description'],
      validator: json['validator'] ?? json['validatorAddress'],
      totalStaked: json['totalStaked'] != null
          ? (json['totalStaked']).toDouble()
          : null,
    );
  }
}

/// Staking Position model - matches backend /api/staking/positions
class StakingPosition {
  final String id;
  final String productId;
  final String currency;
  final double amount;
  final double rewards;
  final double apy;
  final String status; // staking, unbonding, completed
  final DateTime stakedAt;
  final DateTime? unbondingStartedAt;
  final DateTime? completedAt;
  final DateTime? unlockDate;

  StakingPosition({
    required this.id,
    required this.productId,
    required this.currency,
    required this.amount,
    required this.rewards,
    required this.apy,
    required this.status,
    required this.stakedAt,
    this.unbondingStartedAt,
    this.completedAt,
    this.unlockDate,
  });

  factory StakingPosition.fromJson(Map<String, dynamic> json) {
    return StakingPosition(
      id: json['id'] ?? json['positionId'] ?? '',
      productId: json['productId'] ?? '',
      currency: json['currency'] ?? json['asset'] ?? '',
      amount: (json['amount'] ?? json['stakedAmount'] ?? 0).toDouble(),
      rewards: (json['rewards'] ?? json['earnedRewards'] ?? 0).toDouble(),
      apy: (json['apy'] ?? json['rewardRate'] ?? 0).toDouble(),
      status: json['status'] ?? 'staking',
      stakedAt: json['stakedAt'] != null
          ? DateTime.parse(json['stakedAt'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      unbondingStartedAt: json['unbondingStartedAt'] != null
          ? DateTime.parse(json['unbondingStartedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      unlockDate: json['unlockDate'] != null
          ? DateTime.parse(json['unlockDate'])
          : null,
    );
  }

  double get totalValue => amount + rewards;
  bool get isStaking => status == 'staking';
  bool get isUnbonding => status == 'unbonding';
}

/// Earn Service - Handles all savings and staking API calls
class EarnService {
  final ApiService _api = api;

  // ============================================
  // SAVINGS PRODUCTS
  // ============================================

  /// Get all savings products
  Future<List<SavingsProduct>> getSavingsProducts({String? currency, String? type}) async {
    final response = await _api.get(
      ApiConfig.savingsProducts,
      queryParameters: {
        if (currency != null) 'currency': currency,
        if (type != null) 'type': type,
      },
    );
    final List<dynamic> data = response['products'] ?? response['items'] ?? [];
    return data.map((json) => SavingsProduct.fromJson(json)).toList();
  }

  /// Get savings product details
  Future<SavingsProduct> getSavingsProduct(String productId) async {
    final response = await _api.get('${ApiConfig.savingsProducts}/$productId');
    final productData = response['product'] ?? response;
    return SavingsProduct.fromJson(productData);
  }

  // ============================================
  // SAVINGS DEPOSITS
  // ============================================

  /// Create savings deposit (subscribe)
  Future<SavingsDeposit> createSavingsDeposit({
    required String productId,
    required double amount,
    bool autoRenew = false,
  }) async {
    final response = await _api.post(
      ApiConfig.savingsDeposit,
      data: {
        'productId': productId,
        'amount': amount,
        'autoRenew': autoRenew,
      },
    );
    final depositData = response['deposit'] ?? response;
    return SavingsDeposit.fromJson(depositData);
  }

  /// Get my savings deposits
  Future<List<SavingsDeposit>> getSavingsDeposits({String? status}) async {
    final response = await _api.get(
      ApiConfig.savingsDeposits,
      queryParameters: status != null ? {'status': status} : null,
    );
    final List<dynamic> data = response['deposits'] ?? response['items'] ?? [];
    return data.map((json) => SavingsDeposit.fromJson(json)).toList();
  }

  /// Redeem savings deposit
  Future<SavingsDeposit> redeemSavingsDeposit(String depositId, {double? amount}) async {
    final response = await _api.post(
      ApiConfig.savingsWithdraw,
      data: {
        'depositId': depositId,
        if (amount != null) 'amount': amount,
      },
    );
    final depositData = response['deposit'] ?? response;
    return SavingsDeposit.fromJson(depositData);
  }

  // ============================================
  // STAKING PRODUCTS
  // ============================================

  /// Get all staking products
  Future<List<StakingProduct>> getStakingProducts({String? currency}) async {
    final response = await _api.get(
      ApiConfig.stakingProducts,
      queryParameters: currency != null ? {'currency': currency} : null,
    );
    final List<dynamic> data = response['products'] ?? response['items'] ?? [];
    return data.map((json) => StakingProduct.fromJson(json)).toList();
  }

  /// Get staking product details
  Future<StakingProduct> getStakingProduct(String productId) async {
    final response = await _api.get('${ApiConfig.stakingProducts}/$productId');
    final productData = response['product'] ?? response;
    return StakingProduct.fromJson(productData);
  }

  // ============================================
  // STAKING POSITIONS
  // ============================================

  /// Stake crypto
  Future<StakingPosition> stake({
    required String productId,
    required double amount,
  }) async {
    final response = await _api.post(
      ApiConfig.stakingStake,
      data: {
        'productId': productId,
        'amount': amount,
      },
    );
    final positionData = response['position'] ?? response;
    return StakingPosition.fromJson(positionData);
  }

  /// Get my staking positions
  Future<List<StakingPosition>> getStakingPositions({String? status}) async {
    final response = await _api.get(
      ApiConfig.stakingPositions,
      queryParameters: status != null ? {'status': status} : null,
    );
    final List<dynamic> data = response['positions'] ?? response['items'] ?? [];
    return data.map((json) => StakingPosition.fromJson(json)).toList();
  }

  /// Unstake (start unbonding)
  Future<StakingPosition> unstake(String positionId, {double? amount}) async {
    final response = await _api.post(
      ApiConfig.stakingUnstake,
      data: {
        'positionId': positionId,
        if (amount != null) 'amount': amount,
      },
    );
    final positionData = response['position'] ?? response;
    return StakingPosition.fromJson(positionData);
  }

  /// Claim staking rewards
  Future<Map<String, dynamic>> claimRewards(String positionId) async {
    final response = await _api.post('${ApiConfig.stakingPositions}/$positionId/claim');
    return {
      'claimed': (response['claimed'] ?? response['amount'] ?? 0).toDouble(),
      'currency': response['currency'] ?? response['asset'] ?? '',
      'message': response['message'],
    };
  }

  // ============================================
  // SUMMARY
  // ============================================

  /// Get earn summary (total savings + staking)
  Future<Map<String, dynamic>> getEarnSummary() async {
    final response = await _api.get('${ApiConfig.savings}/summary');
    return {
      'totalSavings': (response['totalSavings'] ?? 0).toDouble(),
      'totalStaking': (response['totalStaking'] ?? 0).toDouble(),
      'totalEarnings': (response['totalEarnings'] ?? 0).toDouble(),
      'pendingRewards': (response['pendingRewards'] ?? 0).toDouble(),
      'avgApy': (response['avgApy'] ?? 0).toDouble(),
    };
  }
}

/// Global earn service instance
final earnService = EarnService();
