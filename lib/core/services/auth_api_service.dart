import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class AuthApiService {
  // ---------------------------------------------------------------------------
  // 1. Authentication & Login
  // ---------------------------------------------------------------------------

  /// Step 1 of Login: Checking identifier with backend.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/login
  Future<ApiResponse> loginStep1({
    required String identifier,
    String? password,
  }) async {
    final cleanIdentifier = identifier.trim();
    final bool isEmail = cleanIdentifier.contains('@');
    final String email = isEmail ? cleanIdentifier : '$cleanIdentifier@bnxmail.com';

    if (password != null && password.isNotEmpty) {
      debugPrint('🔐 [AUTH SERVICE] Direct Login { email: $email } -> ${ApiConstants.login}');
      final resDirect = await ApiClient.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
      );
      // Return direct API response immediately. Do not fall through to strip password!
      return resDirect;
    }

    debugPrint('🔐 [AUTH SERVICE] Step 1 identifier check { identifier: $cleanIdentifier } -> ${ApiConstants.login}');
    return await ApiClient.post(
      ApiConstants.login,
      body: {
        'identifier': cleanIdentifier,
        'email': email,
      },
    );
  }

  /// Step 2 of Login: Verifying password with tempToken from Step 1.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/login/2fa
  Future<ApiResponse> loginStep2({
    required String tempToken,
    required String password,
  }) async {
    return await ApiClient.post(
      ApiConstants.login2fa,
      token: tempToken.isNotEmpty ? tempToken : null,
      body: {
        'tempToken': tempToken,
        'password': password,
      },
    );
  }

  /// Send 2FA OTP to phone/email.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/login/2fa/send-otp
  Future<ApiResponse> send2FaOtp({required String tempToken}) async {
    return await ApiClient.post(
      ApiConstants.send2faOtp,
      token: tempToken.isNotEmpty ? tempToken : null,
      body: {'tempToken': tempToken},
    );
  }

  /// Verify 2FA OTP and get final access token.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/login/2fa/verify-otp
  Future<ApiResponse> verify2FaOtp({
    required String tempToken,
    required String otp,
  }) async {
    return await ApiClient.post(
      ApiConstants.verify2faOtp,
      token: tempToken.isNotEmpty ? tempToken : null,
      body: {
        'tempToken': tempToken,
        'otp': otp,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Registration & Onboarding
  // ---------------------------------------------------------------------------

  /// Create a new user account (Personal, Child, or Business).
  /// Endpoint: POST https://api.bnxmail.com/api/auth/register
  Future<ApiResponse> registerUser(Map<String, dynamic> payload) async {
    return await ApiClient.post(
      ApiConstants.register,
      body: payload,
    );
  }

  /// Provisions actual email mailbox after user registration.
  /// Endpoint: POST https://api.bnxmail.com/api/emails/create
  Future<ApiResponse> provisionEmail({
    required String tempToken,
    required String emailName,
    required String password,
    bool isPrimary = true,
  }) async {
    return await ApiClient.post(
      ApiConstants.createEmail,
      token: tempToken.isNotEmpty ? tempToken : null,
      body: {
        'emailName': emailName,
        'password': password,
        'isPrimary': isPrimary,
      },
    );
  }

  /// Submit extra business onboarding details.
  /// Endpoint: POST https://api.bnxmail.com/api/business/onboard
  Future<ApiResponse> onboardBusiness({
    required String accessToken,
    required Map<String, dynamic> businessDetails,
  }) async {
    return await ApiClient.post(
      ApiConstants.onboardBusiness,
      token: accessToken.isNotEmpty ? accessToken : null,
      body: businessDetails,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Child Account Approvals
  // ---------------------------------------------------------------------------

  /// Send verification code to parent email for child account.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/child/send-parent-otp
  Future<ApiResponse> sendParentOtp({required String parentEmail}) async {
    return await ApiClient.post(
      ApiConstants.sendParentOtp,
      body: {'parentEmail': parentEmail},
    );
  }

  /// Verify the code sent to parent email for child account.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/child/verify-parent-otp
  Future<ApiResponse> verifyParentOtp({
    required String parentEmail,
    required String otp,
  }) async {
    return await ApiClient.post(
      ApiConstants.verifyParentOtp,
      body: {
        'parentEmail': parentEmail,
        'otp': otp,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Password Recovery (Forgot Password)
  // ---------------------------------------------------------------------------

  /// Get available recovery options (email/phone) for identifier.
  /// Endpoint: GET https://api.bnxmail.com/api/auth/forgot-password/options?identifier=...
  Future<ApiResponse> fetchForgotPasswordOptions(String identifier) async {
    final url = '${ApiConstants.forgotPasswordOptions}?identifier=${Uri.encodeComponent(identifier)}';
    return await ApiClient.get(url);
  }

  /// Send reset OTP via chosen method ('email' or 'phone').
  /// Endpoint: POST https://api.bnxmail.com/api/auth/forgot-password/send-otp
  Future<ApiResponse> sendForgotPasswordOtp({
    required String identifier,
    required String method,
  }) async {
    return await ApiClient.post(
      ApiConstants.sendForgotPasswordOtp,
      body: {
        'identifier': identifier,
        'method': method,
      },
    );
  }

  /// Verify reset OTP.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/forgot-password/verify-otp
  Future<ApiResponse> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  }) async {
    return await ApiClient.post(
      ApiConstants.verifyForgotPasswordOtp,
      body: {
        'identifier': identifier,
        'otp': otp,
      },
    );
  }

  /// Set new password using reset OTP.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/reset-password
  Future<ApiResponse> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    return await ApiClient.post(
      ApiConstants.resetPassword,
      body: {
        'identifier': identifier,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  /// Change password while logged in.
  /// Endpoint: POST https://api.bnxmail.com/api/auth/change-password
  Future<ApiResponse> changePassword({
    required String accessToken,
    required String oldPassword,
    required String newPassword,
  }) async {
    return await ApiClient.post(
      ApiConstants.changePassword,
      token: accessToken,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Miscellaneous & Username Suggestions
  // ---------------------------------------------------------------------------

  /// Fetch available username suggestions.
  /// Endpoint: GET https://api.bnxmail.com/api/auth/username-suggestions
  Future<ApiResponse> fetchUsernameSuggestions() async {
    return await ApiClient.get(ApiConstants.usernameSuggestions);
  }
}
