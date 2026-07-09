import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/services/token_storage_service.dart';

/// Mock du stockage sécurisé — évite de dépendre d'un vrai téléphone
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late TokenStorageService service;

  setUp(() {
    mockStorage = MockSecureStorage();
    service = TokenStorageService(storage: mockStorage);
  });

  group('TokenStorageService', () {
    test('saveTokens écrit les deux tokens', () async {
      when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async {});

      await service.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );

      verify(() => mockStorage.write(key: 'access_token', value: 'access-123'))
          .called(1);
      verify(() =>
              mockStorage.write(key: 'refresh_token', value: 'refresh-456'))
          .called(1);
    });

    test('getAccessToken lit la bonne clé', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'access-123');

      final token = await service.getAccessToken();

      expect(token, 'access-123');
    });

    test('hasTokens retourne true si un access token existe', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'access-123');

      expect(await service.hasTokens(), isTrue);
    });

    test('hasTokens retourne false si aucun token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      expect(await service.hasTokens(), isFalse);
    });

    test('clearTokens supprime les deux tokens', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.clearTokens();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });
}
