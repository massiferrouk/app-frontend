import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_config.dart';
import 'package:studup_app/core/api/auth_interceptor.dart';
import 'package:studup_app/services/token_storage_service.dart';

class MockTokenStorage extends Mock implements TokenStorageService {}

void main() {
  late MockTokenStorage tokenStorage;
  late Dio dio; // Dio principal, avec l'intercepteur
  late DioAdapter dioAdapter; // simule les réponses du serveur
  late Dio plainDio; // Dio nu utilisé par l'intercepteur (refresh + rejeu)
  late DioAdapter plainAdapter;

  setUp(() {
    tokenStorage = MockTokenStorage();

    plainDio = Dio();
    plainAdapter = DioAdapter(dio: plainDio);

    dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    dioAdapter = DioAdapter(dio: dio);
    dio.interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage, plainDio: plainDio),
    );
  });

  group('onRequest — ajout du token', () {
    test('ajoute le header Bearer sur une requête protégée', () async {
      when(() => tokenStorage.getAccessToken())
          .thenAnswer((_) async => 'mon-access-token');

      // Le mock ne matche QUE si le header Authorization attendu est présent
      dioAdapter.onGet(
        '/matching/suggestions',
        (server) => server.reply(200, {'ok': true}),
        headers: {'Authorization': 'Bearer mon-access-token'},
      );

      final response = await dio.get('/matching/suggestions');

      expect(response.statusCode, 200);
    });

    test('n\'ajoute PAS de token sur un endpoint public', () async {
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {'accessToken': 'a', 'refreshToken': 'r'}),
        data: Matchers.any,
      );

      await dio.post('/auth/login', data: {'email': 'a@a.fr'});

      // getAccessToken ne doit jamais avoir été consulté
      verifyNever(() => tokenStorage.getAccessToken());
    });
  });

  group('onError — refresh automatique sur 401', () {
    test('sur 401 : refresh, sauvegarde, rejeu de la requête', () async {
      when(() => tokenStorage.getAccessToken())
          .thenAnswer((_) async => 'token-expire');
      when(() => tokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-valide');
      when(() => tokenStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      // 1. La requête initiale répond 401 (token expiré)
      dioAdapter.onGet(
        '/accords/mes-accords',
        (server) => server.reply(401, {'message': 'Token expiré'}),
      );

      // 2. Le refresh répond une nouvelle paire de tokens
      plainAdapter.onPost(
        '${ApiConfig.baseUrl}/auth/refresh',
        (server) => server.reply(200, {
          'accessToken': 'nouveau-access',
          'refreshToken': 'nouveau-refresh',
        }),
        data: {'refreshToken': 'refresh-valide'},
      );

      // 3. Le rejeu de la requête d'origine répond 200
      plainAdapter.onGet(
        '${ApiConfig.baseUrl}/accords/mes-accords',
        (server) => server.reply(200, {'accords': []}),
        headers: {'Authorization': 'Bearer nouveau-access'},
      );

      final response = await dio.get('/accords/mes-accords');

      // L'appelant reçoit un 200 : le 401 a été absorbé par l'intercepteur
      expect(response.statusCode, 200);
      verify(() => tokenStorage.saveTokens(
            accessToken: 'nouveau-access',
            refreshToken: 'nouveau-refresh',
          )).called(1);
    });

    test('si le refresh échoue : purge des tokens et erreur propagée',
        () async {
      when(() => tokenStorage.getAccessToken())
          .thenAnswer((_) async => 'token-expire');
      when(() => tokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-expire');
      when(() => tokenStorage.clearTokens()).thenAnswer((_) async {});

      dioAdapter.onGet(
        '/accords/mes-accords',
        (server) => server.reply(401, {'message': 'Token expiré'}),
      );

      // Le refresh échoue aussi (refresh token révoqué)
      plainAdapter.onPost(
        '${ApiConfig.baseUrl}/auth/refresh',
        (server) => server.reply(401, {'message': 'Refresh token révoqué'}),
        data: Matchers.any,
      );

      await expectLater(
        dio.get('/accords/mes-accords'),
        throwsA(isA<DioException>()),
      );

      verify(() => tokenStorage.clearTokens()).called(1);
    });

    test('sans refresh token : erreur propagée sans tentative de refresh',
        () async {
      when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => null);
      when(() => tokenStorage.getRefreshToken()).thenAnswer((_) async => null);

      dioAdapter.onGet(
        '/accords/mes-accords',
        (server) => server.reply(401, {'message': 'Non authentifié'}),
      );

      await expectLater(
        dio.get('/accords/mes-accords'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
