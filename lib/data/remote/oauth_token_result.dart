class OAuthTokenResult {
  const OAuthTokenResult({
    required this.accessToken,
    this.refreshToken,
    this.accessTokenExpirationDateTime,
    this.idToken,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpirationDateTime;
  final String? idToken;
}
