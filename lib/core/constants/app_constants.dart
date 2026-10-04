class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Local-dev server config (Laravel Herd on the laptop, reached from the phone
  // via `adb reverse tcp:8080 tcp:80` — see run-app.bat).
  //
  // - URL uses http://127.0.0.1:8080 (adb reverse forwards to laptop:80).
  // - The site name is embedded as the first path segment because Valet/Herd
  //   extracts it when the Host header is an IP address (Server.php
  //   `valetSiteFromIpAddressUri`).
  // - The Host header MUST be sent without a port (see devHost below);
  //   Dio's default would send "127.0.0.1:8080" which Valet wouldn't match.
  // TODO(prod): switch back to https://fieldvisit-ecosystem-api-gateway.test/...
  // and remove the Host header override before releasing.
  // ---------------------------------------------------------------------------
  static const String devHost = '127.0.0.1';
  static const String devPort = '8080';
  static const String gatewaySite = 'fieldvisit-ecosystem-api-gateway.test';

  // API Base URLs
  static const String authBaseUrl =
      'http://$devHost:$devPort/$gatewaySite/api/p/auth_service/v1';
  static const String authUserBaseUrl =
      'http://$devHost:$devPort/$gatewaySite/api/u/auth_service/v1';
  static const String businessBaseUrl =
      'http://$devHost:$devPort/$gatewaySite/api/u/business_service/v1';

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
