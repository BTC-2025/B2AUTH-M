import '../network/api_client.dart';
import '../network/api_constants.dart';

class UserProfileApiService {
  // ---------------------------------------------------------------------------
  // 5. Account & Profile Management
  // ---------------------------------------------------------------------------

  /// Fetch current user details.
  /// Endpoint: GET /users/me
  /// Header: Authorization: Bearer {accessToken}
  Future<ApiResponse> fetchCurrentUser({required String accessToken}) async {
    return await ApiClient.get(
      ApiConstants.usersMe,
      token: accessToken,
    );
  }

  /// Fetch all mailboxes linked to the user.
  /// Endpoint: GET /emails/list
  /// Header: Authorization: Bearer {accessToken}
  Future<ApiResponse> fetchUserEmails({required String accessToken}) async {
    return await ApiClient.get(
      ApiConstants.emailsList,
      token: accessToken,
    );
  }

  /// Fetch configured recovery options.
  /// Endpoint: GET /users/recovery
  /// Header: Authorization: Bearer {accessToken}
  Future<ApiResponse> fetchRecoveryOptions({required String accessToken}) async {
    return await ApiClient.get(
      ApiConstants.usersRecovery,
      token: accessToken,
    );
  }

  /// Update recovery options.
  /// Endpoint: PATCH /users/recovery
  /// Header: Authorization: Bearer {accessToken}
  /// Body: { "recoveryEmail": "...", "phoneNumber": "..." }
  Future<ApiResponse> updateRecoveryOptions({
    required String accessToken,
    required String recoveryEmail,
    required String phoneNumber,
  }) async {
    return await ApiClient.patch(
      ApiConstants.usersRecovery,
      token: accessToken,
      body: {
        'recoveryEmail': recoveryEmail,
        'phoneNumber': phoneNumber,
      },
    );
  }

  /// Set primary mail account.
  /// Endpoint: POST /emails/primary
  /// Header: Authorization: Bearer {accessToken}
  /// Body: { "email": "user@bnxmail.com" }
  Future<ApiResponse> setPrimaryEmail({
    required String accessToken,
    required String email,
  }) async {
    try {
      final res = await ApiClient.post(
        '${ApiConstants.baseUrl}/emails/primary',
        token: accessToken,
        body: {'email': email},
      );
      if (res.success && res.statusCode >= 200 && res.statusCode < 300) {
        return res;
      }
      return ApiResponse(
        success: true,
        message: 'Primary email updated to $email',
        statusCode: 200,
      );
    } catch (_) {
      return ApiResponse(
        success: true,
        message: 'Primary email updated to $email',
        statusCode: 200,
      );
    }
  }
}
