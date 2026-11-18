import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b2auth/core/services/local_storage_service.dart';
import 'package:b2auth/manage_account_api_bundle/core/network/token_service.dart';
import 'package:b2auth/manage_account_api_bundle/data/repositories/user_repository.dart';
import 'package:b2auth/manage_account_api_bundle/data/repositories/storage_repository.dart';
import 'package:b2auth/manage_account_api_bundle/data/repositories/subscription_repository.dart';
import 'package:b2auth/manage_account_api_bundle/data/repositories/settings_repository.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  group('Manage Account Live API Integration Tests', () {
    test('Verify all Manage Account endpoints with active token', () async {
      // 1. Fetch available accounts from TokenService registry
      final registry = await TokenService.getSavedAccountsFromRegistry();
      expect(registry, isNotEmpty);

      // Select an active account with a valid live token
      final activeAcc = registry.firstWhere(
        (a) => a['email'] == 'ramaniteam123@bnxmail.com',
        orElse: () => registry.first,
      );
      final email = activeAcc['email'] as String;
      final token = activeAcc['accessToken'] as String?;

      expect(token, isNotNull);
      expect(token, isNotEmpty);

      // Save as active session
      await TokenService.saveTokens(accessToken: token!, refreshToken: '');
      await TokenService.saveUserInfo(email: email, name: activeAcc['name']?.toString() ?? 'User');

      // Test 1: GET /api/users/me (User Profile)
      final profile = await UserRepository.getProfile();
      expect(profile, isNotNull);
      expect(profile!.email, isNotEmpty);

      // Test 2: GET /api/users/settings (User Profile Data)
      final profileData = await UserRepository.getProfileData();
      expect(profileData, isNotNull);

      // Test 3: GET /api/mail/storage-quota (Storage Quota)
      final storageQuota = await StorageRepository.fetchStorageQuota();
      expect(storageQuota.storageLimit, greaterThan(0));
      expect(storageQuota.email, isNotEmpty);

      // Test 4: GET https://cliks.beta-softnet.com/api/v1/business/subscription/{userEmail}
      final sub = await SubscriptionRepository.getBusinessSubscription(email);
      expect(sub, isNotNull);
      expect(sub!['plan_name'], isNotNull);

      // Test 5: GET /api/emails/list (Connected Mail Accounts)
      final connectedEmails = await UserRepository.getConnectedEmails();
      expect(connectedEmails, isA<List>());

      // Test 6: GET /api/subid/list (Sub-IDs)
      final subIds = await UserRepository.listSubIds();
      expect(subIds, isA<List>());

      // Test 7: GET /api/signatures (Signatures)
      final signatures = await SettingsRepository.getSignatures();
      expect(signatures, isA<List>());

      // Test 8: GET /api/auth/sessions (Active Sessions)
      final sessions = await UserRepository.getSessions();
      expect(sessions, isA<List>());

      // Test 9: GET /api/settings/language
      final language = await SettingsRepository.getLanguage();
      expect(language, isNotEmpty);

      // Test 10: GET /api/settings/composing
      final composing = await SettingsRepository.getComposing();
      expect(composing, isNotEmpty);

      // Test 11: GET /api/settings/text-style
      final textStyle = await SettingsRepository.getTextStyle();
      expect(textStyle, isNotEmpty);

      // Test 12: GET /api/settings/wallpaper
      final wallpaper = await SettingsRepository.getWallpaper();
      expect(wallpaper, isNotNull);

      // Test 13: POST /api/users/2fa/setup (2FA setup initiation)
      final twoFa = await SettingsRepository.setup2FA();
      expect(twoFa.qrCode, isNotNull);

      // Test 14: PATCH /api/users/profile (Update Profile)
      await UserRepository.updateProfile({'nickname': 'Ramani Team'});
    });
  });
}
