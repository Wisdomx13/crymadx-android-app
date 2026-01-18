import 'api_service.dart';
import '../config/api_config.dart';

/// Wallet Balance model - matches backend /api/balance/balances response
class WalletBalance {
  final String currency;
  final String symbol;
  final double available;
  final double locked;
  final double usdValue;
  final String? network;
  final String? walletAddress;

  WalletBalance({
    required this.currency,
    required this.symbol,
    required this.available,
    required this.locked,
    required this.usdValue,
    this.network,
    this.walletAddress,
  });

  double get total => available + locked;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      currency: json['currency'] ?? json['asset'] ?? '',
      symbol: json['symbol'] ?? json['currency'] ?? json['asset'] ?? '',
      available: (json['available'] ?? json['free'] ?? json['balance'] ?? 0).toDouble(),
      locked: (json['locked'] ?? json['frozen'] ?? 0).toDouble(),
      usdValue: (json['usdValue'] ?? json['usd_value'] ?? json['valueUsd'] ?? 0).toDouble(),
      network: json['network'],
      walletAddress: json['walletAddress'] ?? json['address'],
    );
  }
}

/// Balances Summary model - matches backend /api/balance/balances/summary
class BalancesSummary {
  final double totalUsdValue;
  final double totalBtcValue;
  final double change24h;
  final double changePercent24h;
  final List<WalletBalance> balances;

  BalancesSummary({
    required this.totalUsdValue,
    required this.totalBtcValue,
    required this.change24h,
    required this.changePercent24h,
    required this.balances,
  });

  factory BalancesSummary.fromJson(Map<String, dynamic> json) {
    return BalancesSummary(
      totalUsdValue: (json['totalUsdValue'] ?? json['totalUsd'] ?? json['total'] ?? 0).toDouble(),
      totalBtcValue: (json['totalBtcValue'] ?? json['totalBtc'] ?? 0).toDouble(),
      change24h: (json['change24h'] ?? json['dailyChange'] ?? 0).toDouble(),
      changePercent24h: (json['changePercent24h'] ?? json['dailyChangePercent'] ?? 0).toDouble(),
      balances: (json['balances'] as List? ?? [])
          .map((b) => WalletBalance.fromJson(b))
          .toList(),
    );
  }
}

/// Wallet Info model - matches backend /api/user/wallets response
class WalletInfo {
  final String id;
  final String currency;
  final String network;
  final String address;
  final String? memo;
  final bool isActive;
  final DateTime createdAt;

  WalletInfo({
    required this.id,
    required this.currency,
    required this.network,
    required this.address,
    this.memo,
    required this.isActive,
    required this.createdAt,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id'] ?? json['walletId'] ?? '',
      currency: json['currency'] ?? json['asset'] ?? '',
      network: json['network'] ?? json['chain'] ?? '',
      address: json['address'] ?? '',
      memo: json['memo'] ?? json['tag'],
      isActive: json['isActive'] ?? json['active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Deposit Address model
class DepositAddress {
  final String address;
  final String network;
  final String? memo;
  final String? qrCode;
  final String currency;
  final double? minDeposit;

  DepositAddress({
    required this.address,
    required this.network,
    this.memo,
    this.qrCode,
    required this.currency,
    this.minDeposit,
  });

  factory DepositAddress.fromJson(Map<String, dynamic> json) {
    return DepositAddress(
      address: json['address'] ?? '',
      network: json['network'] ?? json['chain'] ?? '',
      memo: json['memo'] ?? json['tag'],
      qrCode: json['qrCode'] ?? json['qr_code'],
      currency: json['currency'] ?? json['asset'] ?? '',
      minDeposit: json['minDeposit'] != null ? (json['minDeposit']).toDouble() : null,
    );
  }
}

/// Transaction/Transfer model - matches backend response
class Transaction {
  final String id;
  final String type; // deposit, withdraw, transfer, internal
  final String currency;
  final double amount;
  final String status; // pending, completed, failed, cancelled
  final String? txHash;
  final String? fromAddress;
  final String? toAddress;
  final String? network;
  final double? fee;
  final String? memo;
  final DateTime createdAt;
  final DateTime? completedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.currency,
    required this.amount,
    required this.status,
    this.txHash,
    this.fromAddress,
    this.toAddress,
    this.network,
    this.fee,
    this.memo,
    required this.createdAt,
    this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? json['transactionId'] ?? json['transferId'] ?? '',
      type: json['type'] ?? json['txType'] ?? 'transfer',
      currency: json['currency'] ?? json['asset'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      txHash: json['txHash'] ?? json['tx_hash'] ?? json['transactionHash'],
      fromAddress: json['fromAddress'] ?? json['from'],
      toAddress: json['toAddress'] ?? json['to'] ?? json['address'],
      network: json['network'] ?? json['chain'],
      fee: json['fee'] != null ? (json['fee']).toDouble() : null,
      memo: json['memo'] ?? json['tag'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

/// Transfer Request model for internal transfers
class TransferRequest {
  final String fromWallet; // spot, funding, earn
  final String toWallet;
  final String currency;
  final double amount;

  TransferRequest({
    required this.fromWallet,
    required this.toWallet,
    required this.currency,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromWallet': fromWallet,
      'toWallet': toWallet,
      'currency': currency,
      'amount': amount,
    };
  }
}

/// Wallet Service - Handles all wallet/balance API calls
class WalletService {
  final ApiService _api = api;

  // ============================================
  // BALANCE METHODS
  // ============================================

  /// Get all wallet balances
  Future<List<WalletBalance>> getBalances() async {
    final response = await _api.get(ApiConfig.balances);
    final List<dynamic> data = response['balances'] ?? response['data'] ?? [];
    return data.map((json) => WalletBalance.fromJson(json)).toList();
  }

  /// Get balances summary with totals
  Future<BalancesSummary> getBalancesSummary() async {
    final response = await _api.get(ApiConfig.balancesSummary);
    return BalancesSummary.fromJson(response);
  }

  /// Get specific currency balance
  Future<WalletBalance> getBalance(String currency) async {
    final response = await _api.get('${ApiConfig.balances}/$currency');
    final balanceData = response['balance'] ?? response;
    return WalletBalance.fromJson(balanceData);
  }

  // ============================================
  // WALLET METHODS (Circle Integration)
  // ============================================

  /// Get user wallets
  Future<List<WalletInfo>> getWallets() async {
    final response = await _api.get(ApiConfig.userWallets);
    final List<dynamic> data = response['wallets'] ?? response['data'] ?? [];
    return data.map((json) => WalletInfo.fromJson(json)).toList();
  }

  /// Initialize wallets for user (creates Circle wallets)
  Future<Map<String, dynamic>> initializeWallets() async {
    final response = await _api.post(ApiConfig.userWalletsInitialize);
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'Wallets initialized',
      'wallets': response['wallets'],
    };
  }

  /// Get wallets status
  Future<Map<String, dynamic>> getWalletsStatus() async {
    final response = await _api.get(ApiConfig.userWalletsStatus);
    return {
      'initialized': response['initialized'] ?? false,
      'status': response['status'] ?? 'pending',
      'wallets': response['wallets'],
    };
  }

  /// Map network names to chain identifiers used by Circle
  static const Map<String, String> _networkToChain = {
    // Ethereum networks
    'ERC20': 'eth',
    'Ethereum': 'eth',
    'ETH': 'eth',
    // Bitcoin networks
    'Bitcoin': 'btc',
    'BTC': 'btc',
    // Solana networks
    'Solana': 'sol',
    'SOL': 'sol',
    // Polygon networks
    'Polygon': 'matic',
    'MATIC': 'matic',
    // Avalanche networks
    'Avalanche': 'avax',
    'Avalanche C-Chain': 'avax',
    'AVAX': 'avax',
    // Arbitrum networks
    'Arbitrum': 'arb',
    'ARB': 'arb',
    // Optimism networks
    'Optimism': 'op',
    'OP': 'op',
    // Tron networks
    'TRC20': 'trx',
    'TRON': 'trx',
    'TRX': 'trx',
    // BNB Chain networks
    'BEP20': 'bsc',
    'BSC': 'bsc',
    'BNB': 'bsc',
    'BNB Smart Chain': 'bsc',
    // Base network
    'Base': 'base',
  };

  /// Get deposit address for a currency by fetching from /user/wallets
  /// Since the backend doesn't have a separate deposit-address endpoint,
  /// we use the wallets endpoint which already contains all addresses
  Future<DepositAddress> getDepositAddress(String currency, {String? network}) async {
    try {
      // Fetch all wallets from /user/wallets
      final response = await _api.get(ApiConfig.userWallets);
      final List<dynamic> wallets = response['wallets'] ?? response['data'] ?? [];

      if (wallets.isEmpty) {
        throw Exception('No wallets found. Please initialize your wallets first.');
      }

      // Map the selected network to chain identifier
      String? targetChain;
      if (network != null) {
        targetChain = _networkToChain[network]?.toLowerCase();
        // If no mapping found, try using the network name directly
        targetChain ??= network.toLowerCase();
      }

      // Find the appropriate wallet
      Map<String, dynamic>? selectedWallet;

      for (var wallet in wallets) {
        final chain = (wallet['chain'] ?? '').toString().toLowerCase();

        // If a specific network was requested, match by chain
        if (targetChain != null) {
          if (chain == targetChain) {
            selectedWallet = wallet;
            break;
          }
        } else {
          // No specific network - match by currency symbol
          // ETH, USDT, USDC typically use eth chain
          // BTC uses btc chain
          // SOL uses sol chain
          final currencyUpper = currency.toUpperCase();
          if (currencyUpper == 'BTC' && chain == 'btc') {
            selectedWallet = wallet;
            break;
          } else if (currencyUpper == 'SOL' && chain == 'sol') {
            selectedWallet = wallet;
            break;
          } else if (currencyUpper == 'MATIC' && chain == 'matic') {
            selectedWallet = wallet;
            break;
          } else if (['ETH', 'USDT', 'USDC', 'DAI', 'LINK', 'UNI'].contains(currencyUpper) && chain == 'eth') {
            selectedWallet = wallet;
            break;
          }
        }
      }

      // If no specific wallet found, default to first one (usually ETH)
      selectedWallet ??= wallets.first as Map<String, dynamic>;

      // Return the deposit address
      final wallet = selectedWallet;
      return DepositAddress(
        address: wallet['address'] ?? '',
        network: _getNetworkName(wallet['chain'] ?? ''),
        memo: wallet['memo'],
        currency: currency,
        minDeposit: null,
      );
    } catch (e) {
      // If error message contains HTML (like "Cannot GET"), provide clearer error
      final errorStr = e.toString();
      if (errorStr.contains('Cannot GET') || errorStr.contains('<!DOCTYPE')) {
        throw Exception('Deposit addresses not available. Please try again later.');
      }
      rethrow;
    }
  }

  /// Convert chain identifier back to user-friendly network name
  String _getNetworkName(String chain) {
    switch (chain.toLowerCase()) {
      case 'eth':
        return 'ERC20';
      case 'btc':
        return 'Bitcoin';
      case 'sol':
        return 'Solana';
      case 'matic':
        return 'Polygon';
      case 'avax':
        return 'Avalanche';
      case 'arb':
        return 'Arbitrum';
      case 'op':
        return 'Optimism';
      case 'trx':
        return 'TRC20';
      case 'bsc':
        return 'BEP20';
      case 'base':
        return 'Base';
      default:
        return chain.toUpperCase();
    }
  }

  // ============================================
  // TRANSFER METHODS
  // ============================================

  /// Internal transfer between wallets (spot, funding, earn)
  Future<Transaction> transfer(TransferRequest request) async {
    final response = await _api.post(
      ApiConfig.balanceTransfer,
      data: request.toJson(),
    );
    final txData = response['transfer'] ?? response['transaction'] ?? response;
    return Transaction.fromJson({...txData, 'type': 'internal'});
  }

  /// Get transfer history
  /// Returns empty list if endpoint is not available (graceful degradation)
  Future<List<Transaction>> getTransfers({
    String? type,
    String? currency,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.balanceTransfers,
        queryParameters: {
          if (type != null) 'type': type,
          if (currency != null) 'currency': currency,
          if (status != null) 'status': status,
          'page': page,
          'limit': limit,
        },
      );
      final List<dynamic> data = response['transfers'] ?? response['items'] ?? response['data'] ?? [];
      return data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      // If the endpoint doesn't exist (404 or HTML error), return empty list
      final errorStr = e.toString();
      if (errorStr.contains('Cannot GET') ||
          errorStr.contains('<!DOCTYPE') ||
          errorStr.contains('404') ||
          errorStr.contains('Not Found')) {
        // Return empty list - transaction history feature not available yet
        return [];
      }
      rethrow;
    }
  }

  /// Get single transfer by ID
  Future<Transaction> getTransfer(String transferId) async {
    final response = await _api.get('${ApiConfig.balanceTransfers}/$transferId');
    final txData = response['transfer'] ?? response;
    return Transaction.fromJson(txData);
  }

  // ============================================
  // SUPPORTED ASSETS
  // ============================================

  /// Get list of supported currencies
  Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    final response = await _api.get('${ApiConfig.balance}/currencies');
    final List<dynamic> data = response['currencies'] ?? response['assets'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Get supported networks for a currency
  Future<List<Map<String, dynamic>>> getSupportedNetworks(String currency) async {
    final response = await _api.get('${ApiConfig.balance}/networks/$currency');
    final List<dynamic> data = response['networks'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}

/// Global wallet service instance
final walletService = WalletService();
