import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/theme_provider.dart';
import 'services/cache_service.dart';
// import 'services/notification_service.dart'; // Uncomment when Firebase is configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache service for offline support
  await cacheService.init();

  // Push notifications disabled until Firebase is configured
  // To enable: run `flutterfire configure` and uncomment firebase dependencies in pubspec.yaml
  // try {
  //   await notificationService.init();
  // } catch (e) {
  //   debugPrint('Notification service init failed: $e');
  // }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const CrymadXApp(),
    ),
  );
}
