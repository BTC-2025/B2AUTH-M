import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
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

import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  
  runApp(
    MultiProvider(
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
      darkTheme: ThemeData.dark(), // TODO: Implement proper dark theme if needed
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
