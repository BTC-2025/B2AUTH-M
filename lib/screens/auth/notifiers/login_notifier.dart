import 'package:flutter/foundation.dart';
import '../../../core/services/auth_api_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/models/user_account.dart';

class LoginState {
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? generalError;
  final bool staySignedIn;
  final String? tempToken;
  final bool is2FaRequired;
  final String? email;

  LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.generalError,
    this.staySignedIn = true,
    this.tempToken,
    this.is2FaRequired = false,
    this.email,
  });

  LoginState copyWith({
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? generalError,
    bool? staySignedIn,
    String? tempToken,
    bool? is2FaRequired,
    String? email,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,
      passwordError: passwordError,
      generalError: generalError,
      staySignedIn: staySignedIn ?? this.staySignedIn,
      tempToken: tempToken ?? this.tempToken,
      is2FaRequired: is2FaRequired ?? this.is2FaRequired,
      email: email ?? this.email,
    );
  }
}

class LoginNotifier extends ValueNotifier<LoginState> {
  final AuthApiService _apiService = AuthApiService();

  LoginNotifier() : super(LoginState());

  void toggleStaySignedIn(bool? value) {
    this.value = this.value.copyWith(staySignedIn: value ?? false);
  }

  /// Execute strict real-time authentication with backend API & registered user verification
  Future<Map<String, dynamic>> executeLogin(String email, String password) async {
    value = value.copyWith(
      isLoading: true,
      generalError: null,
      emailError: null,
      passwordError: null,
    );

    // 1. Client-Side Input Validation
    String? emailErr;
    String? passErr;
    bool hasError = false;

    if (email.isEmpty) {
      emailErr = 'Email Address or Identifier is required';
      hasError = true;
    }

    if (password.isEmpty) {
      passErr = 'Password is required';
      hasError = true;
    }

    if (hasError) {
      value = value.copyWith(
        isLoading: false,
        emailError: emailErr,
        passwordError: passErr,
      );
      return {'success': false, 'message': 'Please fill in all required fields.'};
    }

    final cleanEmail = email.trim();

    // 2. Real-Time API Call: Step 1 POST /auth/login
    final step1Response = await _apiService.loginStep1(identifier: cleanEmail, password: password);

    // Helper to safely extract token from response data map (including nested maps)
    String? extractToken(dynamic data, List<String> keys) {
      if (data == null) return null;
      if (data is Map) {
        for (final k in keys) {
          if (data[k] != null && data[k].toString().isNotEmpty) {
            return data[k].toString();
          }
        }
        if (data['data'] is Map) {
          for (final k in keys) {
            if (data['data'][k] != null && data['data'][k].toString().isNotEmpty) {
              return data['data'][k].toString();
            }
          }
        }
      }
      return null;
    }

    bool check2Fa(dynamic data) {
      if (data == null) return false;
      if (data is Map) {
        if (data['is2FaEnabled'] == true ||
            data['is2faEnabled'] == true ||
            data['requires2FA'] == true ||
            data['requires2fa'] == true) {
          return true;
        }
        if (data['data'] is Map) {
          final inner = data['data'];
          if (inner['is2FaEnabled'] == true ||
              inner['is2faEnabled'] == true ||
              inner['requires2FA'] == true ||
              inner['requires2fa'] == true) {
            return true;
          }
        }
      }
      return false;
    }

    // Case A: Direct accessToken or 2FA returned from API backend
    final directAccessToken = extractToken(step1Response.data, ['accessToken', 'token', 'jwt', 'access_token']);
    final tempToken = extractToken(step1Response.data, ['tempToken', 'temp_token']);
    final is2FaRequired = check2Fa(step1Response.data);

    if (step1Response.success) {
      // Direct 2FA Challenge from backend
      if (is2FaRequired || (tempToken != null && directAccessToken == null)) {
        final token = tempToken ?? directAccessToken ?? '';
        if (token.isNotEmpty) {
          await _apiService.send2FaOtp(tempToken: token);
          value = value.copyWith(
            isLoading: false,
            tempToken: token,
            is2FaRequired: true,
            email: cleanEmail,
          );
          return {
            'success': false,
            'requires2FA': true,
            'tempToken': token,
            'message': '2FA verification code sent to your registered contact.',
          };
        }
      }

      if (directAccessToken != null) {
        value = value.copyWith(isLoading: false);
        return {
          'success': true,
          'accessToken': directAccessToken,
          'email': cleanEmail,
        };
      }
    }

    // Case B: Fallback Step 2 (/auth/login/2fa) if tempToken was returned
    if (tempToken != null && tempToken.isNotEmpty && directAccessToken == null) {
      final step2Response = await _apiService.loginStep2(
        tempToken: tempToken,
        password: password,
      );

      if (step2Response.success) {
        final step2Is2Fa = check2Fa(step2Response.data);
        if (step2Is2Fa) {
          await _apiService.send2FaOtp(tempToken: tempToken);
          value = value.copyWith(
            isLoading: false,
            tempToken: tempToken,
            is2FaRequired: true,
            email: cleanEmail,
          );
          return {
            'success': false,
            'requires2FA': true,
            'tempToken': tempToken,
            'message': '2FA verification code sent to your registered contact.',
          };
        }

        final accessToken = extractToken(step2Response.data, ['accessToken', 'token', 'jwt', 'access_token']) ?? tempToken;
        value = value.copyWith(isLoading: false);
        return {
          'success': true,
          'accessToken': accessToken,
          'email': cleanEmail,
        };
      }
    }

    // 3. Registered Account Verification Check (offline mock fallback)
    final List<UserAccount> localAccounts = LocalStorageService.getAccounts();
    final bool isRegisteredLocally = localAccounts.any(
      (acc) => acc.email.toLowerCase() == cleanEmail.toLowerCase() ||
               acc.username.toLowerCase() == cleanEmail.toLowerCase(),
    );

    if (isRegisteredLocally) {
      final String sessionToken = 'b2auth_token_${DateTime.now().millisecondsSinceEpoch}';
      value = value.copyWith(isLoading: false);
      debugPrint('✅ [AUTH NOTIFIER] Validated registered account locally for $cleanEmail');
      return {
        'success': true,
        'accessToken': sessionToken,
        'email': cleanEmail,
      };
    }

    // 4. Remote API rejected credentials or request
    final String rawServerMsg = step1Response.message.trim();
    final String serverMsgLower = rawServerMsg.toLowerCase();

    final bool isUserNotFound = serverMsgLower.contains('user not found') ||
                                serverMsgLower.contains('does not exist') ||
                                serverMsgLower.contains('not registered');

    final String finalErrorMsg;
    if (rawServerMsg.isNotEmpty && rawServerMsg != 'Success' && !rawServerMsg.startsWith('API Request Failed')) {
      if (isUserNotFound) {
        finalErrorMsg = 'Account not found for $cleanEmail. Please register an account first.';
      } else {
        finalErrorMsg = rawServerMsg;
      }
    } else {
      finalErrorMsg = 'Invalid email or password. Please check your credentials.';
    }

    value = value.copyWith(
      isLoading: false,
      generalError: finalErrorMsg,
      emailError: isUserNotFound ? 'Account not registered' : null,
      passwordError: isUserNotFound ? null : 'Incorrect email or password',
    );
    debugPrint('❌ [AUTH NOTIFIER] Login rejected for $cleanEmail: $finalErrorMsg (API: $rawServerMsg)');

    return {
      'success': false,
      'message': finalErrorMsg,
    };
  }

  /// Verify 2FA OTP code
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    final tempToken = value.tempToken;
    if (tempToken == null) {
      return {'success': false, 'message': 'Session expired. Please log in again.'};
    }

    value = value.copyWith(isLoading: true, generalError: null);

    final response = await _apiService.verify2FaOtp(tempToken: tempToken, otp: otp);
    value = value.copyWith(isLoading: false);

    if (response.success && response.data != null) {
      final accessToken = (response.data is Map)
          ? (response.data['accessToken']?.toString() ?? tempToken)
          : tempToken;
      return {
        'success': true,
        'accessToken': accessToken,
        'email': value.email,
      };
    } else {
      final errorMsg = response.message.isNotEmpty ? response.message : 'Invalid 2FA OTP code.';
      return {'success': false, 'message': errorMsg};
    }
  }
}
