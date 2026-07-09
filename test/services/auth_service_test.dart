import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/token_storage_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorageService {}

void main() {
  late MockApiClient api;
  late MockTokenStorage tokens;
  late AuthService authService;

  setUp(() {
    api = MockApiClient();
    tokens = MockTokenStorage();
    authService = AuthService(apiClient: api, tokenStorage: tokens);
  });

  group('register', () {
    test('appelle POST /auth/register et retourne le User créé', () async {
      when(() => api.post<Map<String, dynamic>>('/auth/register',
          data: any(named: 'data'))).thenAnswer((_) async => {
            'id': 'uuid-1',
            'email': 'alice@studup.fr',
            'firstName': 'Alice',
            'lastName': 'Martin',
            'role': 'ALTERNANT',
            'isVerified': false,
          });

      final user = await authService.register(
        email: 'alice@studup.fr',
        password: 'motdepasse123',
        firstName: 'Alice',
        lastName: 'Martin',
        role: UserRole.ALTERNANT,
      );

      expect(user.email, 'alice@studup.fr');
      expect(user.isVerified, isFalse); // PENDING_EMAIL : pas encore confirmé

      // Aucun token ne doit être sauvegardé à l'inscription
      verifyNever(() => tokens.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('propage l\'ApiException sur email en doublon (409)', () async {
      when(() => api.post<Map<String, dynamic>>('/auth/register',
              data: any(named: 'data')))
          .thenThrow(const ApiException(
        code: 'DUPLICATE_EMAIL',
        message: 'Un compte existe déjà avec cet email',
        statusCode: 409,
      ));

      expect(
        () => authService.register(
          email: 'alice@studup.fr',
          password: 'motdepasse123',
          firstName: 'Alice',
          lastName: 'Martin',
          role: UserRole.ALTERNANT,
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.isConflict, 'isConflict', isTrue)),
      );
    });
  });

  group('login', () {
    test('sauvegarde les tokens après connexion réussie', () async {
      when(() => api.post<Map<String, dynamic>>('/auth/login',
          data: any(named: 'data'))).thenAnswer((_) async => {
            'accessToken': 'access-123',
            'refreshToken': 'refresh-456',
          });
      when(() => tokens.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await authService.login(
          email: 'alice@studup.fr', password: 'motdepasse123');

      verify(() => tokens.saveTokens(
            accessToken: 'access-123',
            refreshToken: 'refresh-456',
          )).called(1);
    });

    test('ne sauvegarde rien si le login échoue (401)', () async {
      when(() => api.post<Map<String, dynamic>>('/auth/login',
              data: any(named: 'data')))
          .thenThrow(const ApiException(
        code: 'BAD_CREDENTIALS',
        message: 'Email ou mot de passe incorrect',
        statusCode: 401,
      ));

      await expectLater(
        authService.login(email: 'alice@studup.fr', password: 'mauvais'),
        throwsA(isA<ApiException>()),
      );

      verifyNever(() => tokens.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });
  });

  group('logout', () {
    test('révoque côté serveur puis purge les tokens locaux', () async {
      when(() => tokens.getRefreshToken())
          .thenAnswer((_) async => 'refresh-456');
      when(() => api.post<dynamic>('/auth/logout', data: any(named: 'data')))
          .thenAnswer((_) async => null);
      when(() => tokens.clearTokens()).thenAnswer((_) async {});

      await authService.logout();

      verify(() => api.post<dynamic>('/auth/logout',
          data: {'refreshToken': 'refresh-456'})).called(1);
      verify(() => tokens.clearTokens()).called(1);
    });

    test('purge les tokens locaux MÊME si le serveur est injoignable',
        () async {
      when(() => tokens.getRefreshToken())
          .thenAnswer((_) async => 'refresh-456');
      when(() => api.post<dynamic>('/auth/logout', data: any(named: 'data')))
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur',
        statusCode: 0,
      ));
      when(() => tokens.clearTokens()).thenAnswer((_) async {});

      // Ne doit PAS lever d'exception
      await authService.logout();

      verify(() => tokens.clearTokens()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('délègue à hasTokens', () async {
      when(() => tokens.hasTokens()).thenAnswer((_) async => true);

      expect(await authService.isLoggedIn(), isTrue);
    });
  });
}
