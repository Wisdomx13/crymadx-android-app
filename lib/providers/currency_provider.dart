import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Currency data
class Currency {
  final String code;
  final String name;
  final String symbol;
  final double rate; // Rate to USD

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rate,
  });
}

/// Supported currencies with exchange rates
const List<Currency> _supportedCurrenciesList = [
  Currency(code: 'USD', name: 'US Dollar', symbol: '\$', rate: 1.0),
  Currency(code: 'EUR', name: 'Euro', symbol: '€', rate: 0.92),
  Currency(code: 'GBP', name: 'British Pound', symbol: '£', rate: 0.79),
  Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', rate: 149.50),
  Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', rate: 1.53),
  Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', rate: 1.36),
  Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', rate: 0.88),
  Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', rate: 7.24),
  Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', rate: 83.12),
  Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', rate: 1550.00),
  Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', rate: 153.50),
  Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', rate: 18.65),
  Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', rate: 3.67),
  Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', rate: 1.34),
  Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', rate: 7.82),
  Currency(code: 'BTC', name: 'Bitcoin', symbol: '₿', rate: 0.0000234),
];

/// Currency state provider
class CurrencyProvider extends ChangeNotifier {
  String _currencyCode = 'USD';
  double _baseBalanceUSD = 1000.0;

  /// Static access to supported currencies list
  static List<Currency> get supportedCurrencies => _supportedCurrenciesList;

  String get currencyCode => _currencyCode;
  double get baseBalanceUSD => _baseBalanceUSD;

  Currency get selectedCurrency => _supportedCurrenciesList.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => _supportedCurrenciesList.first,
      );

  /// Alias for selectedCurrency
  Currency get currency => _supportedCurrenciesList.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => _supportedCurrenciesList.first,
      );

  /// Set currency
  void setCurrency(String code) {
    _currencyCode = code;
    notifyListeners();
  }

  /// Convert USD amount to selected currency
  double convertAmount(double amountUSD) {
    return amountUSD * selectedCurrency.rate;
  }

  /// Format amount in selected currency
  String formatAmount(double amountUSD, {bool showSymbol = true}) {
    final converted = convertAmount(amountUSD);
    final currency = selectedCurrency;

    // Determine decimal places
    int decimals;
    if (currency.code == 'BTC') {
      decimals = 8;
    } else if (['JPY', 'NGN', 'KES', 'INR'].contains(currency.code)) {
      decimals = 0;
    } else {
      decimals = 2;
    }

    final formatter = NumberFormat.currency(
      symbol: showSymbol ? currency.symbol : '',
      decimalDigits: decimals,
    );

    return formatter.format(converted);
  }

  /// Get currency symbol
  String getSymbol() => selectedCurrency.symbol;

  /// Update base balance
  void setBaseBalance(double balance) {
    _baseBalanceUSD = balance;
    notifyListeners();
  }
}
