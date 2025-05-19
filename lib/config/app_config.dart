class AppConfig {
  static const String apiBaseUrl = 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app';
  
  // API 경로
  static const String apiLogin = '/api/users/login';
  static const String apiGoogleLogin = '/api/users/google-login';
  static const String apiGoogleLoginCheck = '/api/users/google-login-check';
  static const String apiRegister = '/api/users/register-with-agreements';
  static const String apiGoogleRegister = '/api/users/google-login-with-agreements';
  static const String apiCheckEmail = '/api/users/check-email';
  static const String apiVerifyEmail = '/api/users/verify-email';
  static const String apiResendVerification = '/api/users/resend-verification';
  static const String apiGetVerificationCode = '/api/users/verification-code';
  static const String apiFindUsername = '/api/users/verify-for-username';
  static const String apiResetPassword = '/api/users/verify-for-password-reset';
  static const String apiSendVerificationForCredential = '/api/users/send-verification-for-credential';
  static const String apiChangePassword = '/api/users/change-password';
  static const String apiVerifyPassword = '/api/users/verify-password';
  static const String apiDeleteAccount = '/api/users/delete-account';
  static const String apiUserInfo = '/api/users/me';
}