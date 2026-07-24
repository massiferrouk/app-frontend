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
/// Si le refresh échoue (refresh token expiré/révoqué, compte suspendu ou
/// banni par un admin) : purge les tokens ET prévient l'application via
/// [onSessionExpiree], pour qu'elle ramène l'utilisateur au login.
///
/// QueuedInterceptor (et pas Interceptor) : si 5 requêtes reçoivent 401 en
/// même temps, elles sont traitées une par une → un seul refresh, pas cinq.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorageService _tokenStorage;

  /// Dio "nu", sans intercepteur — utilisé pour l'appel refresh et le rejeu.
  /// Si on utilisait le Dio principal, un 401 sur le refresh lui-même
  /// redéclencherait l'intercepteur → boucle infinie.
  final Dio _plainDio;

  /// Appelé quand la session ne peut plus être rétablie.
  ///
  /// C'est un callback et non un NavigationService : la couche API n'a pas à
  /// connaître la navigation. L'application branche la redirection dessus,
  /// les tests peuvent l'omettre.
  final Future<void> Function()? onSessionExpiree;

  AuthInterceptor({
    required TokenStorageService tokenStorage,
    required Dio plainDio,
    this.onSessionExpiree,
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

    // Aucune route publique ne déclenche de refresh (APP-121).
    //
    // Auparavant seul /auth/refresh était exclu : un login refusé (mauvais
    // mot de passe, compte suspendu) partait donc en tentative de refresh,
    // qui échouait à son tour et déclenchait la redirection « session
    // terminée » — écrasant le vrai message d'erreur du login.
    final estRoutePublique = ApiConfig.publicPaths
        .any((p) => err.requestOptions.path.endsWith(p));

    // On ne tente le refresh que sur un 401 d'une requête authentifiée
    if (!is401 || estRoutePublique) {
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
      //
      // APP-121 : purger ne suffisait pas. Un compte banni pendant qu'il
      // utilise l'app restait sur ses écrans, chaque appel échouant en
      // « une erreur s'est produite » — sans jamais comprendre pourquoi.
      // On le ramène donc au login avec une explication.
      await _tokenStorage.clearTokens();
      await onSessionExpiree?.call();
      handler.next(err);
    }
  }
}
