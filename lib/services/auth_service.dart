import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/auth_response.dart';
import '../shared/models/enums.dart';
import '../shared/models/user.dart';
import 'token_storage_service.dart';

/// Service d'authentification — la seule porte d'entrée de l'app
/// vers les endpoints /auth/* du backend.
///
/// Compose deux briques : ApiClient (HTTP + JWT auto) et
/// TokenStorageService (persistance sécurisée des tokens).
class AuthService {
  final ApiClient _api;
  final TokenStorageService _tokens;

  /// Dépendances injectables pour les tests, résolues via le locator sinon
  AuthService({ApiClient? apiClient, TokenStorageService? tokenStorage})
      : _api = apiClient ?? locator<ApiClient>(),
        _tokens = tokenStorage ?? locator<TokenStorageService>();

  // ─── Inscription ──────────────────────────────────────────────

  /// POST /auth/register → compte créé en statut PENDING_EMAIL.
  /// ⚠️ Pas de token à ce stade : le backend n'authentifie qu'après
  /// confirmation de l'email (lien envoyé, valable 24h).
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toJson(),
      },
    );
    return User.fromJson(data);
  }

  // ─── Connexion ────────────────────────────────────────────────

  /// POST /auth/login → sauvegarde la paire de tokens.
  /// Après cet appel, toutes les requêtes sont automatiquement
  /// authentifiées par l'AuthInterceptor.
  Future<void> login({required String email, required String password}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final auth = AuthResponse.fromJson(data);
    await _tokens.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
  }

  // ─── Déconnexion ──────────────────────────────────────────────

  /// Révoque la session côté serveur (blacklist JTI + refresh révoqué)
  /// puis purge les tokens locaux.
  /// La purge locale a lieu MÊME si l'appel serveur échoue :
  /// l'utilisateur doit toujours pouvoir se déconnecter (mode avion...).
  Future<void> logout() async {
    final refreshToken = await _tokens.getRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Échec serveur ignoré volontairement : la déconnexion locale prime.
    } finally {
      await _tokens.clearTokens();
    }
  }

  // ─── État de session ──────────────────────────────────────────

  /// Utilisé par le splash pour décider Login ou Home
  Future<bool> isLoggedIn() => _tokens.hasTokens();
}
