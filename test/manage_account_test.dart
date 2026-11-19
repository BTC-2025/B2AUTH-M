import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b2auth/core/services/local_storage_service.dart';
import 'package:b2auth/manage_account_api_bundle/core/network/token_service.dart';
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

  test('Multi-Account Avatar isolation: avatar does not bleed across accounts', () async {
    // 1. Account 1 has a custom avatar URL
    const email1 = 'account1@bnxmail.com';
    const avatar1 = 'https://api.bnxmail.com/api/users/profile-picture/account1';
    await TokenService.saveUserAvatar(email1, avatar1);

    // 2. Account 2 has NO avatar URL
    const email2 = 'account2@bnxmail.com';

    // Verify Account 1 returns its avatar
    final res1 = await TokenService.getUserAvatar(email1);
    expect(res1, equals(avatar1));

    // Verify Account 2 returns NULL and does NOT bleed Account 1's avatar
    final res2 = await TokenService.getUserAvatar(email2);
    expect(res2, isNull);

    // 3. Save a distinct avatar for Account 3
    const email3 = 'account3@bnxmail.com';
    const avatar3 = 'https://api.bnxmail.com/api/users/profile-picture/account3';
    await TokenService.saveUserAvatar(email3, avatar3);

    expect(await TokenService.getUserAvatar(email3), equals(avatar3));
    expect(await TokenService.getUserAvatar(email1), equals(avatar1));
    expect(await TokenService.getUserAvatar(email2), isNull);
  });
}
