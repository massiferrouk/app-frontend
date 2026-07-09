import 'package:dio/dio.dart';

import '../../services/token_storage_service.dart';
import 'api_config.dart';

/// Intercepteur JWT — s'exécute automatiquement autour de chaque requête.
///
/// Rôle 1 (onRequest) : attache "Authorization: Bearer token" sur toutes
/// les requêtes sauf les endpoints publics (login, register...).
///
/// Rôle 2 (onError) : si le serveur répond 401 (access token expiré),
/// tente un refresh via POST /auth/refresh, sauvegarde les nouveaux tokens
/// puis REJOUE la requête d'origine. L'utilisateur ne voit rien.
/// Si le refresh échoue (refresh token expiré/révoqué) : purge les tokens —
/// l'utilisateur devra se reconnecter.
///
/// QueuedInterceptor (et pas Interceptor) : si 5 requêtes reçoivent 401 en
/// même temps, elles sont traitées une par une → un seul refresh, pas cinq.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorageService _tokenStorage;

  /// Dio "nu", sans intercepteur — utilisé pour l'appel refresh et le rejeu.
  /// Si on utilisait le Dio principal, un 401 sur le refresh lui-même
  /// redéclencherait l'intercepteur → boucle infinie.
  final Dio _plainDio;

  AuthInterceptor({
    required TokenStorageService tokenStorage,
    required Dio plainDio,
  })  : _tokenStorage = tokenStorage,
        _plainDio = plainDio;

  // ─── Avant chaque requête : attacher le token ─────────────────

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic =
        ApiConfig.publicPaths.any((p) => options.path.endsWith(p));

    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options); // laisse la requête continuer
  }

  // ─── Sur erreur : tenter le refresh si 401 ────────────────────

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.endsWith('/auth/refresh');

    // On ne tente le refresh que sur un 401 d'une requête normale
    if (!is401 || isRefreshCall) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      handler.next(err); // pas connecté : rien à rafraîchir
      return;
    }

    try {
      // 1. Demande une nouvelle paire de tokens au backend
      final refreshResponse = await _plainDio.post(
        '${ApiConfig.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = refreshResponse.data['accessToken'] as String;
      final newRefresh = refreshResponse.data['refreshToken'] as String;

      // 2. Sauvegarde la nouvelle paire (rotation des tokens)
      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      // 3. Rejoue la requête d'origine avec le nouveau token.
      //    On reconstruit une requête propre plutôt que de réutiliser
      //    l'objet RequestOptions déjà consommé (états internes pollués).
      final original = err.requestOptions;
      final retryResponse = await _plainDio.request(
        original.uri.toString(),
        data: original.data,
        options: Options(
          method: original.method,
          headers: {
            ...original.headers,
            'Authorization': 'Bearer $newAccess',
          },
        ),
      );

      // 4. Résout avec la réponse du rejeu : pour l'appelant,
      //    tout s'est passé comme si de rien n'était
      handler.resolve(retryResponse);
    } catch (_) {
      // Refresh échoué : session terminée, on purge.
      // (La redirection vers Login sera gérée en APP-63.)
      await _tokenStorage.clearTokens();
      handler.next(err);
    }
  }
}
