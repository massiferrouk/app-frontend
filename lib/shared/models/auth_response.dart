/// Miroir de l'AuthResponse backend : la paire de tokens
/// renvoyée par POST /auth/login et POST /auth/refresh.
class AuthResponse {
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}
