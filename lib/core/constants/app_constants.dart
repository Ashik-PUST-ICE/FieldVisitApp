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
  static const String authServiceSite =
      'fieldvisit-ecosystem-auth-service.test';

  /// When true, media URLs coming back from the API are rewritten onto the
  /// local `adb reverse` tunnel so the phone can actually load them.
  ///
  /// The auth-service returns absolute URLs like
  /// `https://fieldvisit-ecosystem-auth-service.test/storage/users/x.jpg`.
  /// That host only resolves on the laptop (Herd/Valet `.test` domain), and
  /// nginx binds port 80 to 127.0.0.1 only - so the phone cannot fetch it.
  /// Herd routes by URI prefix, so `http://127.0.0.1:8080/<site>/storage/...`
  /// reaches the same file through the tunnel.
  // TODO(prod): set to false once the API serves media from a real domain.
  static const bool useLocalDevMedia = true;

  /// Rewrites a media URL so the device can load it.
  /// Returns an empty string for null/empty input.
  static String resolveMediaUrl(String? url) {
    if (url == null) return '';
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    if (!useLocalDevMedia) return trimmed;

    final uri = Uri.tryParse(trimmed);
    // Relative paths (e.g. "/storage/users/x.jpg") need no host handling.
    if (uri == null || !uri.hasScheme) {
      var path = trimmed;
      if (!path.startsWith('/')) path = '/$path';
      return 'http://$devHost:$devPort/$authServiceSite$path';
    }

    // Absolute URL: keep the path (+query) but re-host it onto the tunnel.
    var path = uri.path;
    if (path.isEmpty) path = '/';
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return 'http://$devHost:$devPort/$authServiceSite$path$query';
  }

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
