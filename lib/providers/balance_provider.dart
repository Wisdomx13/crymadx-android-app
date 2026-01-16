import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

/// BalanceProvider - Centralized balance management connected to CrymadX backend
class BalanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Balance data from backend
  double _totalBalance = 0.0;
  double _fundingBalance = 0.0;
  double _tradingBalance = 0.0;
  double _change24h = 0.0;
  double _changePercent24h = 0.0;

  // Asset balances
  List<AssetBalance> _fundingAssets = [];
  List<AssetBalance> _tradingAssets = [];
  List<AssetBalance> _allAssets = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalBalance => _totalBalance;
  double get fundingBalance => _fundingBalance;
  double get tradingBalance => _tradingBalance;
  double get change24h => _change24h;
  double get changePercent24h => _changePercent24h;

  List<AssetBalance> get fundingAssets => _fundingAssets;
  List<AssetBalance> get tradingAssets => _tradingAssets;
  List<AssetBalance> get allAssets => _allAssets;

  Map<String, AssetBalance> get fundingAssetsMap => {
    for (var asset in _fundingAssets) asset.symbol: asset
  };
  Map<String, AssetBalance> get tradingAssetsMap => {
    for (var asset in _tradingAssets) asset.symbol: asset
  };

  List<AssetBalance> get fundingAssetsList => _fundingAssets;
  List<AssetBalance> get tradingAssetsList => _tradingAssets;

  /// Initialize and load balances
  Future<void> init() async {
    await loadBalances();
  }

  /// Load all balances from backend
  Future<void> loadBalances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get balances summary from backend
      final summary = await walletService.getBalancesSummary();

      _totalBalance = summary.totalUsdValue;
      _change24h = summary.change24h;
      _changePercent24h = summary.changePercent24h;

      // Convert wallet balances to AssetBalance
      _allAssets = summary.balances.map((wb) => AssetBalance(
        symbol: wb.symbol,
        name: _getCryptoName(wb.symbol),
        amount: wb.available + wb.locked,
        price: wb.usdValue / (wb.available + wb.locked > 0 ? wb.available + wb.locked : 1),
        available: wb.available,
        locked: wb.locked,
      )).toList();

      // For now, all balances go to funding (until we have wallet type info)
      _fundingAssets = _allAssets;
      _fundingBalance = _totalBalance;
      _tradingBalance = 0.0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      // Show zero balances on error - no mock data
      if (_allAssets.isEmpty) {
        _totalBalance = 0.0;
        _fundingBalance = 0.0;
        _tradingBalance = 0.0;
      }
      notifyListeners();
    }
  }

  /// Load balances without showing loading state (for background refresh)
  Future<void> refreshBalances() async {
    try {
      final summary = await walletService.getBalancesSummary();

      _totalBalance = summary.totalUsdValue;
      _change24h = summary.change24h;
      _changePercent24h = summary.changePercent24h;

      _allAssets = summary.balances.map((wb) => AssetBalance(
        symbol: wb.symbol,
        name: _getCryptoName(wb.symbol),
        amount: wb.available + wb.locked,
        price: wb.usdValue / (wb.available + wb.locked > 0 ? wb.available + wb.locked : 1),
        available: wb.available,
        locked: wb.locked,
      )).toList();

      _fundingAssets = _allAssets;
      _fundingBalance = _totalBalance;

      notifyListeners();
    } catch (e) {
      // Silently fail on refresh
    }
  }

  /// Transfer between wallets
  Future<bool> transfer({
    required String fromWallet,
    required String toWallet,
    required String currency,
    required double amount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await walletService.transfer(TransferRequest(
        fromWallet: fromWallet,
        toWallet: toWallet,
        currency: currency,
        amount: amount,
      ));

      // Refresh balances after transfer
      await loadBalances();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update funding balance (local update)
  void updateFundingBalance(double amount) {
    _fundingBalance = amount;
    _totalBalance = _fundingBalance + _tradingBalance;
    notifyListeners();
  }

  /// Update trading balance (local update)
  void updateTradingBalance(double amount) {
    _tradingBalance = amount;
    _totalBalance = _fundingBalance + _tradingBalance;
    notifyListeners();
  }

  /// Add to funding balance (local update)
  void addToFunding(double amount) {
    _fundingBalance += amount;
    _totalBalance += amount;
    notifyListeners();
  }

  /// Add to trading balance (local update)
  void addToTrading(double amount) {
    _tradingBalance += amount;
    _totalBalance += amount;
    notifyListeners();
  }

  /// Transfer from funding to trading (local update)
  void transferToTrading(double amount) {
    if (_fundingBalance >= amount) {
      _fundingBalance -= amount;
      _tradingBalance += amount;
      notifyListeners();
    }
  }

  /// Transfer from trading to funding (local update)
  void transferToFunding(double amount) {
    if (_tradingBalance >= amount) {
      _tradingBalance -= amount;
      _fundingBalance += amount;
      notifyListeners();
    }
  }

  /// Update asset price (for live price updates)
  void updateAssetPrice(String symbol, double newPrice) {
    for (int i = 0; i < _allAssets.length; i++) {
      if (_allAssets[i].symbol == symbol) {
        _allAssets[i] = _allAssets[i].copyWithPrice(newPrice);
      }
    }
    _recalculateBalances();
    notifyListeners();
  }

  /// Recalculate total balances from assets
  void _recalculateBalances() {
    _fundingBalance = _fundingAssets.fold(0.0, (sum, asset) => sum + asset.valueUsd);
    _tradingBalance = _tradingAssets.fold(0.0, (sum, asset) => sum + asset.valueUsd);
    _totalBalance = _fundingBalance + _tradingBalance;
  }

  /// Format balance for display
  String formatBalance(double balance, {bool showCurrency = true}) {
    final formatted = balance.toStringAsFixed(2);
    return showCurrency ? '\$$formatted' : formatted;
  }

  /// Get crypto name from symbol
  String _getCryptoName(String symbol) {
    const names = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'BNB': 'BNB',
      'SOL': 'Solana',
      'XRP': 'Ripple',
      'ADA': 'Cardano',
      'DOGE': 'Dogecoin',
      'DOT': 'Polkadot',
      'MATIC': 'Polygon',
      'LTC': 'Litecoin',
      'USDT': 'Tether',
      'USDC': 'USD Coin',
      'AVAX': 'Avalanche',
      'LINK': 'Chainlink',
    };
    return names[symbol] ?? symbol;
  }

  /// Load mock data for offline/error fallback
  void _loadMockData() {
    _fundingAssets = [
      AssetBalance(symbol: 'BTC', name: 'Bitcoin', amount: 0.0905, price: 91000),
      AssetBalance(symbol: 'ETH', name: 'Ethereum', amount: 1.5, price: 2280),
      AssetBalance(symbol: 'USDT', name: 'Tether', amount: 1534.50, price: 1),
      AssetBalance(symbol: 'SOL', name: 'Solana', amount: 10.0, price: 98.45),
    ];
    _tradingAssets = [
      AssetBalance(symbol: 'BTC', name: 'Bitcoin', amount: 0.0463, price: 91000),
      AssetBalance(symbol: 'ETH', name: 'Ethereum', amount: 1.0, price: 2280),
      AssetBalance(symbol: 'USDT', name: 'Tether', amount: 450.00, price: 1),
      AssetBalance(symbol: 'SOL', name: 'Solana', amount: 5.5, price: 98.45),
    ];
    _allAssets = [..._fundingAssets];
    _recalculateBalances();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Asset balance model
class AssetBalance {
  final String symbol;
  final String name;
  final double amount;
  final double price;
  final double available;
  final double locked;

  const AssetBalance({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.price,
    this.available = 0,
    this.locked = 0,
  });

  double get valueUsd => amount * price;

  AssetBalance copyWithPrice(double newPrice) {
    return AssetBalance(
      symbol: symbol,
      name: name,
      amount: amount,
      price: newPrice,
      available: available,
      locked: locked,
    );
  }

  AssetBalance copyWithAmount(double newAmount) {
    return AssetBalance(
      symbol: symbol,
      name: name,
      amount: newAmount,
      price: price,
      available: available,
      locked: locked,
    );
  }
}
