import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b2auth/core/services/local_storage_service.dart';
import 'package:b2auth/manage_account_api_bundle/screens/manage_account_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  testWidgets('ManageAccountScreen mounts and renders top bar and tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ManageAccountScreen(initialTab: 0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of Account title in top bar
    expect(find.textContaining('Account'), findsWidgets);
    // Verify presence of Home tab
    expect(find.text('Home'), findsWidgets);
    // Verify presence of Personal info tab
    expect(find.text('Personal info'), findsWidgets);
    // Verify presence of Account storage tab
    expect(find.text('Account storage'), findsWidgets);
  });
}
