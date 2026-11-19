import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:b2auth/standalone_macos_storage/standalone_macos_storage.dart';
import 'package:b2auth/manage_account_api_bundle/screens/manage_account_screen.dart';
import 'package:b2auth/core/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LocalStorageService.init();
    await LocalStorageService.setString(
      'access_token',
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJyYXZpbmV3MjAwNEBibnhtYWlsLmNvbSIsImV4cCI6MTc5NTY3NTYxMX0.fake_sig',
    );
    await LocalStorageService.setString('active_email', 'ravinew2004@bnxmail.com');
  });

  group('Standalone Storage Models & Repository Unit Tests', () {
    test('StorageQuota model deserializes accurately and computes metrics', () {
      final json = {
        'email': 'ravinew2004@bnxmail.com',
        'storageLimit': 5368709120, // 5.0 GB
        'storageUsed': 10276044, // 9.80 MB
        'storagePercentage': 0.1914,
      };

      final quota = StorageQuota.fromJson(json);

      expect(quota.email, 'ravinew2004@bnxmail.com');
      expect(quota.storageLimit, 5368709120);
      expect(quota.storageUsed, 10276044);
      expect(quota.storagePercentage, closeTo(0.1914, 0.001));
      expect(quota.fraction, closeTo(0.001914, 0.0001));
      expect(quota.usedFormatted, contains('MB'));
      expect(quota.limitFormatted, contains('GB'));
      expect(quota.status, 'Normal');
      expect(quota.statusColor, const Color(0xFF10B981));
    });

    test('VaultFile model handles file details and formatting', () {
      final json = {
        'id': 1042,
        'filename': 'q3_backup.zip',
        'contentType': 'application/zip',
        'size': 10485760, // 10 MB
        'createdAt': '2026-10-15T14:32:00.000Z',
      };

      final file = VaultFile.fromJson(json);

      expect(file.id, 1042);
      expect(file.filename, 'q3_backup.zip');
      expect(file.contentType, 'application/zip');
      expect(file.size, 10485760);
      expect(file.sizeFormatted, contains('MB'));
    });
    test('TokenService resolves account-specific tokens without bleeding across accounts', () async {
      await TokenService.saveTokens(
        accessToken: 'token_user_a',
        email: 'usera@bnxmail.com',
      );
      await TokenService.saveTokens(
        accessToken: 'token_user_b',
        email: 'userb@bnxmail.com',
      );

      final tokenA = await TokenService.getAccessToken('usera@bnxmail.com');
      final tokenB = await TokenService.getAccessToken('userb@bnxmail.com');

      expect(tokenA, 'token_user_a');
      expect(tokenB, 'token_user_b');
      expect(tokenA, isNot(equals(tokenB)));
    });
  });

  group('MacOsStoragePage Widget & Interaction Tests', () {
    testWidgets('MacOsStoragePage mounts and renders header and navigation tabs', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MacOsStoragePage(
              backButtonTooltip: 'Back to Account',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header verification
      expect(find.byType(MacOsStoragePage), findsOneWidget);
      expect(find.text('Storage'), findsWidgets);

      // Verify tabs exist
      expect(find.text('Bnx mail'), findsWidgets);
      expect(find.text('Cliks'), findsWidgets);
      expect(find.text('Cliks Business'), findsWidgets);
      expect(find.text('Recycle Bin'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Tapping sidebar items switches views in MacOsStoragePage', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MacOsStoragePage(
              backButtonTooltip: 'Back to Account',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Click on Recycle Bin in the sidebar
      final recycleBinTab = find.text('Recycle Bin');
      expect(recycleBinTab, findsWidgets);
      await tester.tap(recycleBinTab.first);
      await tester.pumpAndSettle();

      // Verify Recycle Bin content displays
      expect(find.textContaining('Recycle Bin'), findsWidgets);

      // Click on Settings in sidebar
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsWidgets);
      await tester.tap(settingsTab.first);
      await tester.pumpAndSettle();

      // Verify Settings options display
      expect(find.textContaining('Storage Unit'), findsWidgets);
    });
    testWidgets('MacOsStoragePage mounts and renders for specific accountEmail', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MacOsStoragePage(
              accountEmail: 'chandran123@bnxmail.com',
              backButtonTooltip: 'Back to Account',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MacOsStoragePage), findsOneWidget);
      expect(find.text('ravi kumar'), findsOneWidget);
    });
  });

  group('ManageAccountScreen Account Storage Integration', () {
    testWidgets('Tapping Account storage in sidebar opens MacOsStoragePage', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ManageAccountScreen(initialTab: 0),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Sidebar has 'Account storage'
      final accountStorageTab = find.text('Account storage').first;
      expect(accountStorageTab, findsOneWidget);

      await tester.tap(accountStorageTab);
      await tester.pumpAndSettle();

      // Verify MacOsStoragePage is pushed
      expect(find.byType(MacOsStoragePage), findsOneWidget);
    });

    testWidgets('Manage storage action on Overview card pushes MacOsStoragePage', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ManageAccountScreen(initialTab: 0),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Scroll until 'Manage storage' is visible
      final manageStorageAction = find.text('Manage storage');
      expect(manageStorageAction, findsOneWidget);

      await tester.scrollUntilVisible(
        manageStorageAction,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Manage storage
      await tester.tap(manageStorageAction);
      await tester.pumpAndSettle();

      // Verify MacOsStoragePage has appeared
      expect(find.byType(MacOsStoragePage), findsOneWidget);
    });
  });
}
