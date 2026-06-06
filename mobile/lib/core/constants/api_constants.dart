class ApiConstants {
  // For Chrome/Web use localhost
  static const String baseUrl = 'http://localhost:8080';

  // If you use Android Emulator later, change baseUrl to:
  // static const String baseUrl = 'http://10.0.2.2:8080';

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String validateResetToken = '/api/auth/validate-reset-token';
  static const String resetPassword = '/api/auth/reset-password';
  static const String me = '/api/auth/me';
}