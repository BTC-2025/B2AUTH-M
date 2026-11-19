import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'core/services/local_storage_service.dart';
import 'core/providers/account_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/threat_provider.dart';
import 'core/providers/passkey_provider.dart';
import 'core/providers/zero_trust_provider.dart';
import 'services/location_provider.dart';
import 'screens/auth/notifiers/auth_notifier.dart';
import 'standalone_macos_storage/pages/macos_storage_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccountProvider()),
          ChangeNotifierProvider(create: (_) => AuthNotifier()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SecurityProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => ThreatProvider()),
          ChangeNotifierProvider(create: (_) => PasskeyProvider()),
          ChangeNotifierProvider(create: (_) => ZeroTrustProvider()),
        ],
        child: const B2AuthApp(),
      ),
    ),
  );
}

class B2AuthApp extends StatelessWidget {
  const B2AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return MaterialApp(
      title: 'B2Auth Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const SplashScreen(),
      routes: {
        '/storage': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return MacOsStoragePage(
            accountEmail: email,
            onBack: () => Navigator.of(context).pop(),
            backButtonTooltip: 'Back to Account',
          );
        },
      },
    );
  }
}
