import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/core/utils/jwt_decoder.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/services/token_storage_service.dart';
import 'package:studup_app/shared/models/enums.dart';

import 'dart:convert';

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorageService {}

/// Fabrique un JWT factice (signature bidon — seul le payload compte
/// pour le décodage côté client)
String fakeJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.fake-signature';
}

void main() {
  late MockApiClient api;
  late MockTokenStorage tokens;
  late ProfileService service;

  const profileJson = {
    'id': 'profile-1',
    'userId': 'user-1',
    'villeA': 'Paris',
    'villeB': 'Lyon',
    'ecole': 'YNOV Paris',
    'entreprise': 'ACME Lyon',
    'dateDebut': '2026-09-01',
    'dateFin': '2027-08-31',
    'rythme': 'SEMAINE_3_1',
  };

  setUp(() {
    api = MockApiClient();
    tokens = MockTokenStorage();
    service = ProfileService(apiClient: api, tokenStorage: tokens);
  });

  group('JwtDecoder', () {
    test('lit userId et role dans le payload', () {
      final token = fakeJwt({'userId': 'user-1', 'role': 'ALTERNANT'});

      expect(JwtDecoder.userId(token), 'user-1');
      expect(JwtDecoder.role(token), 'ALTERNANT');
    });

    test('retourne null sur un token malformé', () {
      expect(JwtDecoder.decodePayload('pas-un-jwt'), isNull);
      expect(JwtDecoder.decodePayload('a.b'), isNull);
    });
  });

  group('currentRole', () {
    test('lit le rôle depuis le token stocké', () async {
      when(() => tokens.getAccessToken())
          .thenAnswer((_) async => fakeJwt({'role': 'ALTERNANT'}));

      expect(await service.currentRole(), UserRole.ALTERNANT);
    });

    test('null si pas de token', () async {
      when(() => tokens.getAccessToken()).thenAnswer((_) async => null);

      expect(await service.currentRole(), isNull);
    });

    test('null si le rôle est inconnu', () async {
      when(() => tokens.getAccessToken())
          .thenAnswer((_) async => fakeJwt({'role': 'SUPERADMIN'}));

      expect(await service.currentRole(), isNull);
    });
  });

  group('createAlternantProfile', () {
    test('envoie les dates au format LocalDate et parse la réponse',
        () async {
      when(() => api.post<Map<String, dynamic>>('/profile/alternant',
              data: any(named: 'data')))
          .thenAnswer((_) async => profileJson);

      final profile = await service.createAlternantProfile(
        villeA: 'Paris',
        villeB: 'Lyon',
        ecole: 'YNOV Paris',
        entreprise: 'ACME Lyon',
        dateDebut: DateTime(2026, 9, 1),
        dateFin: DateTime(2027, 8, 31),
        rythme: RythmeAlternance.SEMAINE_3_1,
        premiereSemaine: PremiereSemaine.ENTREPRISE,
      );

      expect(profile.villeA, 'Paris');
      expect(profile.rythme, RythmeAlternance.SEMAINE_3_1);

      // Vérifie le format exact des dates envoyées ("2026-09-01", pas ISO complet)
      final sent = verify(() => api.post<Map<String, dynamic>>(
              '/profile/alternant',
              data: captureAny(named: 'data')))
          .captured
          .single as Map<String, dynamic>;
      expect(sent['dateDebut'], '2026-09-01');
      expect(sent['dateFin'], '2027-08-31');
      expect(sent['rythme'], 'SEMAINE_3_1');
      expect(sent['premiereSemaine'], 'ENTREPRISE');
    });
  });

  group('updateAlternantProfile', () {
    test('envoie un PUT avec les bonnes données et parse la réponse',
        () async {
      when(() => api.put<Map<String, dynamic>>('/profile/alternant',
              data: any(named: 'data')))
          .thenAnswer((_) async => profileJson);

      final profile = await service.updateAlternantProfile(
        villeA: 'Bordeaux',
        villeB: 'Lyon',
        ecole: 'YNOV Bordeaux',
        entreprise: 'ACME Lyon',
        dateDebut: DateTime(2026, 9, 1),
        dateFin: DateTime(2027, 8, 31),
        rythme: RythmeAlternance.SEMAINE_3_1,
        premiereSemaine: PremiereSemaine.ENTREPRISE,
      );

      expect(profile.villeB, 'Lyon');

      final sent = verify(() => api.put<Map<String, dynamic>>(
              '/profile/alternant',
              data: captureAny(named: 'data')))
          .captured
          .single as Map<String, dynamic>;
      expect(sent['villeA'], 'Bordeaux');
      expect(sent['dateDebut'], '2026-09-01');
      expect(sent['premiereSemaine'], 'ENTREPRISE');
    });
  });

  group('getMyAlternantProfile', () {
    test('retourne le profil quand il existe', () async {
      when(() => tokens.getAccessToken())
          .thenAnswer((_) async => fakeJwt({'userId': 'user-1'}));
      when(() => api.get<Map<String, dynamic>>('/profile/alternant'))
          .thenAnswer((_) async => profileJson);

      final profile = await service.getMyAlternantProfile();

      expect(profile, isNotNull);
      expect(profile!.ecole, 'YNOV Paris');
    });

    test('retourne null sur 404 (pas encore de profil)', () async {
      when(() => tokens.getAccessToken())
          .thenAnswer((_) async => fakeJwt({'userId': 'user-1'}));
      when(() => api.get<Map<String, dynamic>>('/profile/alternant'))
          .thenThrow(const ApiException(
        code: 'NOT_FOUND',
        message: 'Profil introuvable',
        statusCode: 404,
      ));

      expect(await service.getMyAlternantProfile(), isNull);
    });

    test('propage les autres erreurs (500...)', () async {
      when(() => tokens.getAccessToken())
          .thenAnswer((_) async => fakeJwt({'userId': 'user-1'}));
      when(() => api.get<Map<String, dynamic>>('/profile/alternant'))
          .thenThrow(const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'Erreur interne',
        statusCode: 500,
      ));

      expect(() => service.getMyAlternantProfile(),
          throwsA(isA<ApiException>()));
    });
  });
}
