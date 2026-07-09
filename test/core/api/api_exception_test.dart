import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/core/api/api_exception.dart';

void main() {
  // Helper : fabrique une DioException avec une réponse serveur
  DioException dioError({int? status, dynamic data}) {
    final options = RequestOptions(path: '/api/v1/test');
    return DioException(
      requestOptions: options,
      response: status == null
          ? null
          : Response(requestOptions: options, statusCode: status, data: data),
    );
  }

  group('ApiException.fromDioException', () {
    test('parse le format d\'erreur backend StudUp', () {
      final e = dioError(status: 409, data: {
        'code': 'DUPLICATE_EMAIL',
        'message': 'Un compte existe déjà avec cet email',
        'timestamp': '2026-07-01T10:30:00Z',
        'path': '/api/v1/auth/register',
        'details': [],
      });

      final exception = ApiException.fromDioException(e);

      expect(exception.code, 'DUPLICATE_EMAIL');
      expect(exception.message, 'Un compte existe déjà avec cet email');
      expect(exception.statusCode, 409);
      expect(exception.isConflict, isTrue);
    });

    test('parse les détails de validation', () {
      final e = dioError(status: 400, data: {
        'code': 'VALIDATION_ERROR',
        'message': 'Données invalides',
        'details': ['email: format invalide', 'password: trop court'],
      });

      final exception = ApiException.fromDioException(e);

      expect(exception.isValidationError, isTrue);
      expect(exception.details, hasLength(2));
      expect(exception.details.first, 'email: format invalide');
    });

    test('erreur réseau quand aucune réponse serveur', () {
      final exception = ApiException.fromDioException(dioError());

      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.isNetworkError, isTrue);
      expect(exception.statusCode, 0);
    });

    test('erreur inconnue quand la réponse n\'a pas le format attendu', () {
      final e = dioError(status: 502, data: '<html>Bad Gateway</html>');

      final exception = ApiException.fromDioException(e);

      expect(exception.code, 'UNKNOWN');
      expect(exception.statusCode, 502);
    });

    test('les raccourcis de statut répondent correctement', () {
      final e401 = ApiException.fromDioException(
          dioError(status: 401, data: {'message': 'Non authentifié'}));
      final e403 = ApiException.fromDioException(
          dioError(status: 403, data: {'message': 'Interdit'}));
      final e429 = ApiException.fromDioException(
          dioError(status: 429, data: {'message': 'Trop de requêtes'}));

      expect(e401.isUnauthorized, isTrue);
      expect(e403.isForbidden, isTrue);
      expect(e429.isRateLimited, isTrue);
    });
  });
}
