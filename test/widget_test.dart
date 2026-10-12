import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:b2auth/main.dart';
import 'package:b2auth/core/providers/account_provider.dart';
import 'package:b2auth/core/providers/settings_provider.dart';
import 'package:b2auth/core/providers/notification_provider.dart';
import 'package:b2auth/core/providers/security_provider.dart';
import 'package:b2auth/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  testWidgets('B2AuthApp initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccountProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ],
        child: const B2AuthApp(),
      ),
    );

    // Verify that the title B2Auth is present (since it's displayed in bottom navigation/app bar)
    expect(find.textContaining('B2Auth'), findsWidgets);
  });
}
