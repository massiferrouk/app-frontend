import 'package:dio/dio.dart';

import '../../app/app.locator.dart';
import '../../services/token_storage_service.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Client HTTP unique de l'application.
/// Tous les services métier (AuthService, MatchingService...) passent par
/// lui — personne n'instancie Dio directement ailleurs.
///
/// Garanties :
/// - baseUrl et timeouts configurés une seule fois
/// - token JWT attaché automatiquement (AuthInterceptor)
/// - refresh automatique sur 401
/// - toutes les erreurs ressortent en ApiException
class ApiClient {
  late final Dio _dio;

  /// tokenStorage et dio sont injectables pour les tests ;
  /// en production le locator fournit le TokenStorageService partagé.
  ApiClient({TokenStorageService? tokenStorage, Dio? dio}) {
    final storage = tokenStorage ?? locator<TokenStorageService>();
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ));

    _dio.interceptors.add(AuthInterceptor(
      tokenStorage: storage,
      plainDio: Dio(), // Dio nu pour refresh + rejeu (voir AuthInterceptor)
    ));
  }

  // ─── Méthodes HTTP — miroir des verbes de l'API backend ───────
  // Chaque méthode traduit les DioException en ApiException :
  // les ViewModels n'ont jamais à connaître Dio.

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<T> post<T>(String path, {Object? data}) =>
      _wrap(() => _dio.post<T>(path, data: data));

  Future<T> put<T>(String path, {Object? data}) =>
      _wrap(() => _dio.put<T>(path, data: data));

  Future<T> patch<T>(String path, {Object? data}) =>
      _wrap(() => _dio.patch<T>(path, data: data));

  Future<T> delete<T>(String path) => _wrap(() => _dio.delete<T>(path));

  Future<T> _wrap<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
