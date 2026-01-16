import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/main/home_screen.dart';
import '../screens/main/markets_screen.dart';
import '../screens/main/trading_screen.dart';
import '../screens/main/assets_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/convert_screen.dart';
import '../screens/main/p2p_screen.dart';
import '../screens/main/earn_screen.dart';
import '../screens/main/stake_screen.dart';
import '../screens/main/quick_actions_screen.dart';
import '../screens/main/nft_screen.dart';
import '../screens/main/fiat_screen.dart';
import '../screens/wallet/deposit_screen.dart';
import '../screens/wallet/withdraw_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/wallet/qr_scanner_screen.dart';
import '../screens/wallet/coin_detail_screen.dart';
import '../screens/profile/kyc_screen.dart';
import '../screens/profile/transaction_history_screen.dart';
import '../screens/profile/payment_methods_screen.dart';
import '../screens/profile/rewards_screen.dart';
import '../screens/profile/referral_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/support_tickets_screen.dart';

/// App route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/main/home';
  static const String markets = '/main/markets';
  static const String trade = '/main/trade';
  static const String assets = '/main/assets';
  static const String profile = '/profile';

  // Feature routes
  static const String deposit = '/deposit';
  static const String withdraw = '/withdraw';
  static const String transfer = '/transfer';
  static const String p2p = '/p2p';
  static const String convert = '/convert';
  static const String earn = '/earn';
  static const String stake = '/stake';
  static const String kyc = '/kyc';
  static const String rewards = '/rewards';
  static const String referral = '/referral';
  static const String tickets = '/tickets';
  static const String notifications = '/notifications';
  static const String transactionHistory = '/transactions';
  static const String paymentMethods = '/payment-methods';
  static const String wallet = '/wallet';
  static const String quickActions = '/quick-actions';
  static const String qrScanner = '/qr-scanner';
  static const String coinDetail = '/coin-detail';
  static const String nft = '/nft';
  static const String fiat = '/fiat';
}

/// Main app router
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // Splash
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.markets,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MarketsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.trade,
          pageBuilder: (context, state) {
            final symbol = state.uri.queryParameters['symbol'] ?? 'BTCUSDT';
            final base = state.uri.queryParameters['base'] ?? 'BTC';
            return NoTransitionPage(
              child: TradingScreen(symbol: symbol, baseAsset: base),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.assets,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AssetsScreen(),
          ),
        ),
      ],
    ),

    // Profile
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),

    // Wallet Features
    GoRoute(
      path: AppRoutes.deposit,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DepositScreen(
          initialSymbol: extra?['symbol'],
          initialName: extra?['name'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.withdraw,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return WithdrawScreen(
          initialSymbol: extra?['symbol'],
          initialName: extra?['name'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.transfer,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TransferScreen(
          initialSymbol: extra?['symbol'],
          initialName: extra?['name'],
        );
      },
    ),

    // Profile Feature Routes
    GoRoute(
      path: AppRoutes.kyc,
      builder: (context, state) => const KYCScreen(),
    ),
    GoRoute(
      path: AppRoutes.transactionHistory,
      builder: (context, state) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentMethods,
      builder: (context, state) => const PaymentMethodsScreen(),
    ),

    // Feature Screens
    GoRoute(
      path: AppRoutes.convert,
      builder: (context, state) => const ConvertScreen(),
    ),
    GoRoute(
      path: AppRoutes.p2p,
      builder: (context, state) => const P2PScreen(),
    ),
    GoRoute(
      path: AppRoutes.earn,
      builder: (context, state) => const EarnScreen(),
    ),
    GoRoute(
      path: AppRoutes.stake,
      builder: (context, state) => const StakeScreen(),
    ),

    // Profile Feature Routes
    GoRoute(
      path: AppRoutes.rewards,
      builder: (context, state) => const RewardsScreen(),
    ),
    GoRoute(
      path: AppRoutes.referral,
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.tickets,
      builder: (context, state) => const SupportTicketsScreen(),
    ),
    GoRoute(
      path: AppRoutes.quickActions,
      builder: (context, state) => const QuickActionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.qrScanner,
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.coinDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CoinDetailScreen(
          symbol: extra?['symbol'] ?? 'BTC',
          name: extra?['name'] ?? 'Bitcoin',
          amount: extra?['amount'] ?? 0.0,
          valueUsd: extra?['valueUsd'] ?? 0.0,
          accountType: extra?['accountType'] ?? 'funding',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.nft,
      builder: (context, state) => const NFTScreen(),
    ),
    GoRoute(
      path: AppRoutes.fiat,
      builder: (context, state) => const FiatScreen(),
    ),
  ],

  // Redirect logic
  redirect: (context, state) {
    // Add authentication redirect logic here
    return null;
  },

  // Error handler
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
