import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Coffre-fort des tokens JWT.
/// Seul point d'accès au stockage sécurisé du téléphone :
/// Keychain sur iOS, Keystore (EncryptedSharedPreferences) sur Android.
///
/// ⚠️ Règle de sécurité : les tokens ne passent JAMAIS par
/// shared_preferences (stockage en clair) ni par les logs.
class TokenStorageService {
  // Clés de stockage — privées, personne d'autre n'en a besoin
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  /// Le storage est injectable pour pouvoir le mocker dans les tests
  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── Écriture ─────────────────────────────────────────────────

  /// Sauvegarde la paire de tokens après login ou refresh
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // ─── Lecture ──────────────────────────────────────────────────

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// true si un access token existe (utilisé par le splash pour rediriger)
  Future<bool> hasTokens() async => await getAccessToken() != null;

  // ─── Suppression ──────────────────────────────────────────────

  /// Efface tout — appelé au logout ou quand le refresh échoue
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
