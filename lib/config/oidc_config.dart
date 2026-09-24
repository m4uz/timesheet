class OidcConfig {
  static final Uri redirectUri = Uri.parse(
    'http://127.0.0.1:8400/oauth/callback',
  );

  static const Duration tokenRefreshLeeway = Duration(minutes: 5);
  static const Duration tokenRefreshRetryInterval = Duration(seconds: 30);
  static const int tokenRefreshRetryCount = 3;
  static const Duration expirationCheckInterval = Duration(seconds: 30);
  static const Duration authorizationTimeout = Duration(minutes: 5);

  static const String interactionRequiredError = 'interaction_required';

  static String scope(Uri wtmBaseUrl) => 'openid ${wtmBaseUrl.toString()}';
}
