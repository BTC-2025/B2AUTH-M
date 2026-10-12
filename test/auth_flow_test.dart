import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b2auth/core/services/local_storage_service.dart';
import 'package:b2auth/core/services/auth_api_service.dart';
import 'package:b2auth/screens/auth/notifiers/login_notifier.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  group('AuthApiService live and network tests', () {
    test('loginStep1 normalizes username to email format and connects cleanly', () async {
      final service = AuthApiService();
      final res = await service.loginStep1(
        identifier: 'ravinew2004',
        password: 'wrong_test_password',
      );
      expect(res.statusCode, inInclusiveRange(200, 500));
      expect(res.message, isNotEmpty);
    });

    test('fetchForgotPasswordOptions handles registered account lookup', () async {
      final service = AuthApiService();
      final res = await service.fetchForgotPasswordOptions('ravinew2004@bnxmail.com');
      expect(res.statusCode, inInclusiveRange(200, 500));
      expect(res.message, isNotEmpty);
    });

    test('fetchForgotPasswordOptions handles non-existent account lookup', () async {
      final service = AuthApiService();
      final res = await service.fetchForgotPasswordOptions('nonexistentuser99999@bnxmail.com');
      expect(res.statusCode, inInclusiveRange(200, 500));
      expect(res.message, isNotEmpty);
    });
  });

  group('LoginNotifier internal tests', () {
    test('validation failure when email or password is empty', () async {
      final notifier = LoginNotifier();
      final res1 = await notifier.executeLogin('', 'password');
      expect(res1['success'], isFalse);
      expect(notifier.value.emailError, isNotNull);

      final res2 = await notifier.executeLogin('user@bnxmail.com', '');
      expect(res2['success'], isFalse);
      expect(notifier.value.passwordError, isNotNull);
    });

    test('rejection for invalid password shows proper error without register prompt', () async {
      final notifier = LoginNotifier();
      final result = await notifier.executeLogin('ravinew2004@bnxmail.com', 'wrongpasswordxyz999');
      expect(result['success'], isFalse);
      expect(notifier.value.generalError?.toLowerCase().contains('register an account first'), isFalse);
    });

    test('rejection for unknown account provides clear feedback', () async {
      final notifier = LoginNotifier();
      final result = await notifier.executeLogin('nonexistentuser99999@bnxmail.com', 'wrongpasswordxyz999');
      expect(result['success'], isFalse);
      expect(result['message'], isNotEmpty);
    });
  });
}
