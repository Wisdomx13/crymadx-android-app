import 'api_service.dart';
import '../config/api_config.dart';

/// Swap Pair model - matches backend /api/swap/pairs
class SwapPair {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double minAmount;
  final double maxAmount;
  final bool isActive;

  SwapPair({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.minAmount,
    required this.maxAmount,
    required this.isActive,
  });

  factory SwapPair.fromJson(Map<String, dynamic> json) {
    return SwapPair(
      id: json['id'] ?? json['pairId'] ?? '',
      fromCurrency: json['fromCurrency'] ?? json['from'] ?? '',
      toCurrency: json['toCurrency'] ?? json['to'] ?? '',
      rate: (json['rate'] ?? json['exchangeRate'] ?? 0).toDouble(),
      minAmount: (json['minAmount'] ?? json['min'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? json['max'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }
}

/// Swap Estimate model - matches backend /api/swap/estimate
class SwapEstimate {
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final double fee;
  final String feeCurrency;
  final double networkFee;
  final DateTime expiresAt;
  final String? rateId;

  SwapEstimate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.fee,
    required this.feeCurrency,
    required this.networkFee,
    required this.expiresAt,
    this.rateId,
  });

  factory SwapEstimate.fromJson(Map<String, dynamic> json) {
    return SwapEstimate(
      fromCurrency: json['fromCurrency'] ?? json['from'] ?? '',
      toCurrency: json['toCurrency'] ?? json['to'] ?? '',
      fromAmount: (json['fromAmount'] ?? json['amount'] ?? 0).toDouble(),
      toAmount: (json['toAmount'] ?? json['estimatedAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? json['exchangeRate'] ?? 0).toDouble(),
      fee: (json['fee'] ?? json['serviceFee'] ?? 0).toDouble(),
      feeCurrency: json['feeCurrency'] ?? json['feeAsset'] ?? '',
      networkFee: (json['networkFee'] ?? 0).toDouble(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(minutes: 5)),
      rateId: json['rateId'] ?? json['quoteId'],
    );
  }
}

/// Swap Transaction model - matches backend /api/swap/create and /api/swap/status
class SwapTransaction {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final double fee;
  final String status; // pending, processing, completed, failed, refunded
  final String? txHash;
  final String? depositAddress;
  final String? payoutAddress;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  SwapTransaction({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.fee,
    required this.status,
    this.txHash,
    this.depositAddress,
    this.payoutAddress,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory SwapTransaction.fromJson(Map<String, dynamic> json) {
    return SwapTransaction(
      id: json['id'] ?? json['swapId'] ?? json['transactionId'] ?? '',
      fromCurrency: json['fromCurrency'] ?? json['from'] ?? '',
      toCurrency: json['toCurrency'] ?? json['to'] ?? '',
      fromAmount: (json['fromAmount'] ?? json['amount'] ?? 0).toDouble(),
      toAmount: (json['toAmount'] ?? json['receiveAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? json['exchangeRate'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      txHash: json['txHash'] ?? json['transactionHash'],
      depositAddress: json['depositAddress'] ?? json['payinAddress'],
      payoutAddress: json['payoutAddress'] ?? json['payoutAddress'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      errorMessage: json['errorMessage'] ?? json['error'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
}

/// Swap Service - Handles all swap/convert API calls (ChangeNow integration)
class SwapService {
  final ApiService _api = api;

  // ============================================
  // SWAP PAIRS
  // ============================================

  /// Get available swap pairs
  Future<List<SwapPair>> getSwapPairs() async {
    final response = await _api.get(ApiConfig.swapPairs);
    final List<dynamic> data = response['pairs'] ?? response['data'] ?? [];
    return data.map((json) => SwapPair.fromJson(json)).toList();
  }

  /// Get available currencies for swap
  Future<List<Map<String, dynamic>>> getAvailableCurrencies() async {
    final response = await _api.get('${ApiConfig.swap}/currencies');
    final List<dynamic> data = response['currencies'] ?? response['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // ============================================
  // SWAP ESTIMATES
  // ============================================

  /// Get swap estimate
  Future<SwapEstimate> getEstimate({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    final response = await _api.post(
      ApiConfig.swapEstimate,
      data: {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
      },
    );
    final estimateData = response['estimate'] ?? response;
    return SwapEstimate.fromJson(estimateData);
  }

  /// Get reverse estimate (specify amount to receive)
  Future<SwapEstimate> getReverseEstimate({
    required String fromCurrency,
    required String toCurrency,
    required double receiveAmount,
  }) async {
    final response = await _api.post(
      ApiConfig.swapEstimate,
      data: {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'receiveAmount': receiveAmount,
        'isReverse': true,
      },
    );
    final estimateData = response['estimate'] ?? response;
    return SwapEstimate.fromJson(estimateData);
  }

  // ============================================
  // SWAP TRANSACTIONS
  // ============================================

  /// Create swap transaction
  Future<SwapTransaction> createSwap({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    String? rateId,
    String? refundAddress,
  }) async {
    final response = await _api.post(
      ApiConfig.swapCreate,
      data: {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        if (rateId != null) 'rateId': rateId,
        if (refundAddress != null) 'refundAddress': refundAddress,
      },
    );
    final swapData = response['swap'] ?? response['transaction'] ?? response;
    return SwapTransaction.fromJson(swapData);
  }

  /// Get swap transaction status
  Future<SwapTransaction> getSwapStatus(String swapId) async {
    final response = await _api.get(
      ApiConfig.swapStatus,
      queryParameters: {'id': swapId},
    );
    final swapData = response['swap'] ?? response['transaction'] ?? response;
    return SwapTransaction.fromJson(swapData);
  }

  /// Get swap history
  Future<List<SwapTransaction>> getSwapHistory({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '${ApiConfig.swap}/history',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['swaps'] ?? response['transactions'] ?? response['items'] ?? [];
    return data.map((json) => SwapTransaction.fromJson(json)).toList();
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get minimum amount for a swap pair
  Future<double> getMinAmount(String fromCurrency, String toCurrency) async {
    final response = await _api.get(
      '${ApiConfig.swap}/min-amount',
      queryParameters: {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
      },
    );
    return (response['minAmount'] ?? response['min'] ?? 0).toDouble();
  }

  /// Validate swap address
  Future<bool> validateAddress(String currency, String address) async {
    final response = await _api.post(
      '${ApiConfig.swap}/validate-address',
      data: {
        'currency': currency,
        'address': address,
      },
    );
    return response['valid'] ?? response['isValid'] ?? false;
  }
}

/// Global swap service instance
final swapService = SwapService();
