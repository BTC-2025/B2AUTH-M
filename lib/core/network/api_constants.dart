class ApiConstants {
  static const String baseUrl = 'https://api.bnxmail.com/api';

  // 1. Authentication & Login
  static const String login = '$baseUrl/auth/login';
  static const String login2fa = '$baseUrl/auth/login/2fa';
  static const String send2faOtp = '$baseUrl/auth/login/2fa/send-otp';
  static const String verify2faOtp = '$baseUrl/auth/login/2fa/verify-otp';

  // 2. Registration & Onboarding
  static const String register = '$baseUrl/auth/register';
  static const String createEmail = '$baseUrl/emails/create';
  static const String onboardBusiness = '$baseUrl/business/onboard';

  // 3. Child Account Approvals
  static const String sendParentOtp = '$baseUrl/auth/child/send-parent-otp';
  static const String verifyParentOtp = '$baseUrl/auth/child/verify-parent-otp';

  // 4. Password Recovery & Password Change
  static const String forgotPasswordOptions = '$baseUrl/auth/forgot-password/options';
  static const String sendForgotPasswordOtp = '$baseUrl/auth/forgot-password/send-otp';
  static const String verifyForgotPasswordOtp = '$baseUrl/auth/forgot-password/verify-otp';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String changePassword = '$baseUrl/auth/change-password';

  // 5. Account & Profile Management
  static const String usersMe = '$baseUrl/users/me';
  static const String emailsList = '$baseUrl/emails/list';
  static const String usersRecovery = '$baseUrl/users/recovery';

  // 6. Security & Sessions
  static const String sessions = '$baseUrl/auth/sessions';
  static const String externalSessions = '$baseUrl/auth/sessions/external';

  // 7. Two-Factor Authentication (2FA)
  static const String twoFaAccounts = '$baseUrl/users/2fa/accounts';
  static const String twoFaSetup = '$baseUrl/users/2fa/setup';
  static const String twoFaVerify = '$baseUrl/users/2fa/verify';
  static const String twoFaDisable = '$baseUrl/users/2fa/disable';

  // 8. Miscellaneous
  static const String usernameSuggestions = '$baseUrl/auth/username-suggestions';
  static const String verificationInitiate = '$baseUrl/verification/initiate';
  static const String verificationStatus = '$baseUrl/verification/status';
}
