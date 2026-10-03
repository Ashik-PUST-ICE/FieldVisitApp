class AppConstants {
  AppConstants._();

  // API Base URLs
  static const String authBaseUrl =
      'https://fieldvisit-ecosystem-api-gateway.test/api/p/auth_service/v1';
  static const String authUserBaseUrl =
      'https://fieldvisit-ecosystem-api-gateway.test/api/u/auth_service/v1';
  static const String businessBaseUrl =
      'https://fieldvisit-ecosystem-api-gateway.test/api/u/business_service/v1';

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/auth/change-password';
  static const String publicKey = '/auth/public-key';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String isLoggedInKey = 'is_logged_in';
  static const String biometricLoginEnabledKey = 'biometric_login_enabled';

  // App Info
  static const String appName = 'Field Visit';
  static const String appVersion = '1.0.0';
}
