import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Cache service for offline data storage using Hive
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _userBox = 'user_cache';
  static const String _balancesBox = 'balances_cache';
  static const String _tickersBox = 'tickers_cache';
  static const String _ordersBox = 'orders_cache';
  static const String _transactionsBox = 'transactions_cache';
  static const String _settingsBox = 'settings_cache';
  static const String _p2pBox = 'p2p_cache';
  static const String _nftBox = 'nft_cache';

  Box? _userBoxInstance;
  Box? _balancesBoxInstance;
  Box? _tickersBoxInstance;
  Box? _ordersBoxInstance;
  Box? _transactionsBoxInstance;
  Box? _settingsBoxInstance;
  Box? _p2pBoxInstance;
  Box? _nftBoxInstance;

  bool _isInitialized = false;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Initialize the cache service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _userBoxInstance = await Hive.openBox(_userBox);
      _balancesBoxInstance = await Hive.openBox(_balancesBox);
      _tickersBoxInstance = await Hive.openBox(_tickersBox);
      _ordersBoxInstance = await Hive.openBox(_ordersBox);
      _transactionsBoxInstance = await Hive.openBox(_transactionsBox);
      _settingsBoxInstance = await Hive.openBox(_settingsBox);
      _p2pBoxInstance = await Hive.openBox(_p2pBox);
      _nftBoxInstance = await Hive.openBox(_nftBox);

      _isInitialized = true;

      // Monitor connectivity
      _setupConnectivityListener();

      debugPrint('CacheService initialized');
    } catch (e) {
      debugPrint('Error initializing CacheService: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isOnline);
    });
  }

  // ============================================
  // USER CACHE
  // ============================================

  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await _userBoxInstance?.put('profile', jsonEncode(profile));
    await _userBoxInstance?.put('profile_timestamp', DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? getCachedUserProfile() {
    final data = _userBoxInstance?.get('profile');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  DateTime? getUserProfileCacheTime() {
    final timestamp = _userBoxInstance?.get('profile_timestamp');
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  bool isUserProfileCacheValid({Duration maxAge = const Duration(minutes: 15)}) {
    final cacheTime = getUserProfileCacheTime();
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < maxAge;
  }

  // ============================================
  // BALANCES CACHE
  // ============================================

  Future<void> cacheBalances(List<Map<String, dynamic>> balances) async {
    await _balancesBoxInstance?.put('balances', jsonEncode(balances));
    await _balancesBoxInstance?.put('balances_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedBalances() {
    final data = _balancesBoxInstance?.get('balances');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> cacheBalanceSummary(Map<String, dynamic> summary) async {
    await _balancesBoxInstance?.put('summary', jsonEncode(summary));
    await _balancesBoxInstance?.put('summary_timestamp', DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? getCachedBalanceSummary() {
    final data = _balancesBoxInstance?.get('summary');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  bool isBalancesCacheValid({Duration maxAge = const Duration(minutes: 5)}) {
    final timestamp = _balancesBoxInstance?.get('balances_timestamp');
    if (timestamp == null) return false;
    return DateTime.now().difference(DateTime.parse(timestamp)) < maxAge;
  }

  // ============================================
  // TICKERS CACHE
  // ============================================

  Future<void> cacheTickers(Map<String, dynamic> tickers) async {
    await _tickersBoxInstance?.put('tickers', jsonEncode(tickers));
    await _tickersBoxInstance?.put('tickers_timestamp', DateTime.now().toIso8601String());
  }

  Map<String, dynamic> getCachedTickers() {
    final data = _tickersBoxInstance?.get('tickers');
    if (data != null) {
      return jsonDecode(data);
    }
    return {};
  }

  Future<void> cacheTicker(String symbol, Map<String, dynamic> ticker) async {
    final tickers = getCachedTickers();
    tickers[symbol] = ticker;
    await cacheTickers(tickers);
  }

  Map<String, dynamic>? getCachedTicker(String symbol) {
    final tickers = getCachedTickers();
    return tickers[symbol];
  }

  // ============================================
  // ORDERS CACHE
  // ============================================

  Future<void> cacheOrders(List<Map<String, dynamic>> orders, {String? type}) async {
    final key = type != null ? 'orders_$type' : 'orders';
    await _ordersBoxInstance?.put(key, jsonEncode(orders));
    await _ordersBoxInstance?.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedOrders({String? type}) {
    final key = type != null ? 'orders_$type' : 'orders';
    final data = _ordersBoxInstance?.get(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // TRANSACTIONS CACHE
  // ============================================

  Future<void> cacheTransactions(List<Map<String, dynamic>> transactions) async {
    await _transactionsBoxInstance?.put('transactions', jsonEncode(transactions));
    await _transactionsBoxInstance?.put('transactions_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedTransactions() {
    final data = _transactionsBoxInstance?.get('transactions');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // P2P CACHE
  // ============================================

  Future<void> cacheP2POrders(List<Map<String, dynamic>> orders, {String? type, String? currency}) async {
    final key = 'p2p_orders_${type ?? 'all'}_${currency ?? 'all'}';
    await _p2pBoxInstance?.put(key, jsonEncode(orders));
    await _p2pBoxInstance?.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedP2POrders({String? type, String? currency}) {
    final key = 'p2p_orders_${type ?? 'all'}_${currency ?? 'all'}';
    final data = _p2pBoxInstance?.get(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> cacheP2PTrades(List<Map<String, dynamic>> trades) async {
    await _p2pBoxInstance?.put('p2p_trades', jsonEncode(trades));
    await _p2pBoxInstance?.put('p2p_trades_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedP2PTrades() {
    final data = _p2pBoxInstance?.get('p2p_trades');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // NFT CACHE
  // ============================================

  Future<void> cacheNFTListings(List<Map<String, dynamic>> listings) async {
    await _nftBoxInstance?.put('nft_listings', jsonEncode(listings));
    await _nftBoxInstance?.put('nft_listings_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedNFTListings() {
    final data = _nftBoxInstance?.get('nft_listings');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> cacheOwnedNFTs(List<Map<String, dynamic>> nfts) async {
    await _nftBoxInstance?.put('owned_nfts', jsonEncode(nfts));
    await _nftBoxInstance?.put('owned_nfts_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedOwnedNFTs() {
    final data = _nftBoxInstance?.get('owned_nfts');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> cacheNFTCollections(List<Map<String, dynamic>> collections) async {
    await _nftBoxInstance?.put('nft_collections', jsonEncode(collections));
    await _nftBoxInstance?.put('nft_collections_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedNFTCollections() {
    final data = _nftBoxInstance?.get('nft_collections');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // SETTINGS CACHE
  // ============================================

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBoxInstance?.put(key, jsonEncode(value));
  }

  T? getSetting<T>(String key) {
    final data = _settingsBoxInstance?.get(key);
    if (data != null) {
      return jsonDecode(data) as T?;
    }
    return null;
  }

  Future<void> saveThemeMode(String mode) async {
    await saveSetting('theme_mode', mode);
  }

  String getThemeMode() {
    return getSetting<String>('theme_mode') ?? 'dark';
  }

  Future<void> saveCurrency(String currency) async {
    await saveSetting('currency', currency);
  }

  String getCurrency() {
    return getSetting<String>('currency') ?? 'USD';
  }

  // ============================================
  // GENERIC CACHE METHODS
  // ============================================

  Future<void> cacheData(String box, String key, dynamic data) async {
    Box? targetBox;
    switch (box) {
      case 'user':
        targetBox = _userBoxInstance;
        break;
      case 'balances':
        targetBox = _balancesBoxInstance;
        break;
      case 'tickers':
        targetBox = _tickersBoxInstance;
        break;
      case 'orders':
        targetBox = _ordersBoxInstance;
        break;
      case 'transactions':
        targetBox = _transactionsBoxInstance;
        break;
      case 'settings':
        targetBox = _settingsBoxInstance;
        break;
      case 'p2p':
        targetBox = _p2pBoxInstance;
        break;
      case 'nft':
        targetBox = _nftBoxInstance;
        break;
    }

    if (targetBox != null) {
      await targetBox.put(key, jsonEncode(data));
      await targetBox.put('${key}_timestamp', DateTime.now().toIso8601String());
    }
  }

  dynamic getCachedData(String box, String key) {
    Box? targetBox;
    switch (box) {
      case 'user':
        targetBox = _userBoxInstance;
        break;
      case 'balances':
        targetBox = _balancesBoxInstance;
        break;
      case 'tickers':
        targetBox = _tickersBoxInstance;
        break;
      case 'orders':
        targetBox = _ordersBoxInstance;
        break;
      case 'transactions':
        targetBox = _transactionsBoxInstance;
        break;
      case 'settings':
        targetBox = _settingsBoxInstance;
        break;
      case 'p2p':
        targetBox = _p2pBoxInstance;
        break;
      case 'nft':
        targetBox = _nftBoxInstance;
        break;
    }

    if (targetBox != null) {
      final data = targetBox.get(key);
      if (data != null) {
        return jsonDecode(data);
      }
    }
    return null;
  }

  bool isCacheValid(String box, String key, {Duration maxAge = const Duration(minutes: 15)}) {
    Box? targetBox;
    switch (box) {
      case 'user':
        targetBox = _userBoxInstance;
        break;
      case 'balances':
        targetBox = _balancesBoxInstance;
        break;
      case 'tickers':
        targetBox = _tickersBoxInstance;
        break;
      case 'orders':
        targetBox = _ordersBoxInstance;
        break;
      case 'transactions':
        targetBox = _transactionsBoxInstance;
        break;
      case 'settings':
        targetBox = _settingsBoxInstance;
        break;
      case 'p2p':
        targetBox = _p2pBoxInstance;
        break;
      case 'nft':
        targetBox = _nftBoxInstance;
        break;
    }

    if (targetBox != null) {
      final timestamp = targetBox.get('${key}_timestamp');
      if (timestamp != null) {
        return DateTime.now().difference(DateTime.parse(timestamp)) < maxAge;
      }
    }
    return false;
  }

  // ============================================
  // CLEAR CACHE
  // ============================================

  Future<void> clearUserCache() async {
    await _userBoxInstance?.clear();
  }

  Future<void> clearBalancesCache() async {
    await _balancesBoxInstance?.clear();
  }

  Future<void> clearAllCache() async {
    await _userBoxInstance?.clear();
    await _balancesBoxInstance?.clear();
    await _tickersBoxInstance?.clear();
    await _ordersBoxInstance?.clear();
    await _transactionsBoxInstance?.clear();
    await _p2pBoxInstance?.clear();
    await _nftBoxInstance?.clear();
    // Don't clear settings
  }

  Future<void> clearOnLogout() async {
    await _userBoxInstance?.clear();
    await _balancesBoxInstance?.clear();
    await _ordersBoxInstance?.clear();
    await _transactionsBoxInstance?.clear();
    await _p2pBoxInstance?.clear();
    await _nftBoxInstance?.clear();
    // Keep tickers and settings
  }

  /// Dispose the cache service
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

/// Global cache service instance
final cacheService = CacheService();
