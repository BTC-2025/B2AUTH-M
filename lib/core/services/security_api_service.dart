import '../network/api_client.dart';
import '../network/api_constants.dart';

class SecurityApiService {
  // ---------------------------------------------------------------------------
  // 6. Security & Sessions
  // ---------------------------------------------------------------------------

  /// Fetch active user login sessions.
  /// Endpoint: GET https://api.bnxmail.com/api/auth/sessions
  Future<ApiResponse> fetchActiveSessions(String accessToken) async {
    return await ApiClient.get(
      ApiConstants.sessions,
      token: accessToken,
    );
  }

  /// Fetch active external application login sessions.
  /// Endpoint: GET https://api.bnxmail.com/api/auth/sessions/external
  Future<ApiResponse> fetchExternalSessions(String accessToken) async {
    return await ApiClient.get(
      ApiConstants.externalSessions,
      token: accessToken,
    );
  }

  /// Terminate a specific user session.
  /// Endpoint: DELETE https://api.bnxmail.com/api/auth/sessions/{sessionId}
  Future<ApiResponse> terminateSession({
    required String accessToken,
    required String sessionId,
  }) async {
    final url = '${ApiConstants.sessions}/$sessionId';
    return await ApiClient.delete(
      url,
      token: accessToken,
    );
  }

  /// Terminate a specific external application session.
  /// Endpoint: DELETE https://api.bnxmail.com/api/auth/sessions/external/{sessionId}
  Future<ApiResponse> terminateExternalSession({
    required String accessToken,
    required String sessionId,
  }) async {
    final url = '${ApiConstants.externalSessions}/$sessionId';
    return await ApiClient.delete(
      url,
      token: accessToken,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Two-Factor Authentication (2FA)
  // ---------------------------------------------------------------------------

  /// Fetch configured 2FA accounts/tokens.
  /// Endpoint: GET https://api.bnxmail.com/api/users/2fa/accounts
  Future<ApiResponse> fetch2FaAccounts(String accessToken) async {
    return await ApiClient.get(
      ApiConstants.twoFaAccounts,
      token: accessToken,
    );
  }

  /// Setup 2FA: returns secret key and QR code data.
  /// Endpoint: POST https://api.bnxmail.com/api/users/2fa/setup
  Future<ApiResponse> setup2Fa(String accessToken) async {
    return await ApiClient.post(
      ApiConstants.twoFaSetup,
      token: accessToken,
    );
  }

  /// Verify and activate 2FA with 6-digit TOTP code.
  /// Endpoint: POST https://api.bnxmail.com/api/users/2fa/verify
  Future<ApiResponse> verify2Fa({
    required String accessToken,
    required String code,
  }) async {
    return await ApiClient.post(
      ApiConstants.twoFaVerify,
      token: accessToken,
      body: {'code': code},
    );
  }

  /// Disable 2FA for user account.
  /// Endpoint: POST https://api.bnxmail.com/api/users/2fa/disable
  Future<ApiResponse> disable2Fa(String accessToken) async {
    return await ApiClient.post(
      ApiConstants.twoFaDisable,
      token: accessToken,
    );
  }
}
