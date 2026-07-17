import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/services/matching_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late MatchingService service;

  // JSON minimal d'une suggestion (les listes semaines/scenarios sont vides
  // pour ne pas dépendre de leurs sous-modèles)
  const suggestionJson = {
    'profileId': 'p1',
    'userId': 'u1',
    'prenom': 'Félix',
    'nom': 'Martin',
    'villeA': 'Paris',
    'villeB': 'Lyon',
    'score': 0.75,
    'scorePercent': 75,
    'typePropose': 'ECHANGE_PARTIEL',
    'isMatchActif': true,
    'nbSemainesEchange': 6,
  };

  setUp(() {
    api = MockApiClient();
    service = MatchingService(apiClient: api);
  });

  group('getSuggestions', () {
    test('appelle la bonne route et parse la liste', () async {
      when(() => api.get<List<dynamic>>('/matching/suggestions'))
          .thenAnswer((_) async => [suggestionJson]);

      final result = await service.getSuggestions();

      expect(result, hasLength(1));
      expect(result.first.prenom, 'Félix');
      expect(result.first.scorePercent, 75);
      expect(result.first.typePropose, AccordType.ECHANGE_PARTIEL);
      expect(result.first.isMatchActif, isTrue);
    });

    test('liste vide → liste vide', () async {
      when(() => api.get<List<dynamic>>('/matching/suggestions'))
          .thenAnswer((_) async => []);

      expect(await service.getSuggestions(), isEmpty);
    });

    test('propage les ApiException', () async {
      when(() => api.get<List<dynamic>>('/matching/suggestions')).thenThrow(
          const ApiException(
              code: 'SERVER_ERROR', message: 'Erreur', statusCode: 500));

      expect(service.getSuggestions(), throwsA(isA<ApiException>()));
    });
  });
}
