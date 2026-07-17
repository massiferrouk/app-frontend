import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/calendrier_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late CalendrierService service;

  setUp(() {
    api = MockApiClient();
    service = CalendrierService(apiClient: api);
  });

  test('getMesSemaines parse le profil et ses semaines', () async {
    when(() => api.get<Map<String, dynamic>>('/calendrier/mes-semaines'))
        .thenAnswer((_) async => {
              'profileId': 'p1',
              'villeA': 'Paris',
              'villeB': 'Lyon',
              'rythme': 'SEMAINE_3_1',
              'semaines': [
                {
                  'id': 's1',
                  'semaine': '2026-09-07',
                  'label': 'B',
                  'isOverridden': false,
                }
              ],
            });

    final result = await service.getMesSemaines();

    expect(result.rythme, RythmeAlternance.SEMAINE_3_1);
    expect(result.semaines, hasLength(1));
    expect(result.semaines.first.label, 'B');
  });

  test('overrideSemaine formate la date dans l\'URL et envoie label+reason',
      () async {
    when(() => api.patch<Map<String, dynamic>>(
          '/calendrier/p1/semaines/2026-09-07',
          data: any(named: 'data'),
        )).thenAnswer((_) async => {
          'id': 's1',
          'semaine': '2026-09-07',
          'label': 'A',
          'isOverridden': true,
          'overrideReason': 'Projet',
        });

    final semaine = await service.overrideSemaine(
      profileId: 'p1',
      semaine: DateTime(2026, 9, 7),
      label: 'A',
      reason: 'Projet',
    );

    expect(semaine.isOverridden, isTrue);
    expect(semaine.label, 'A');
    final sent = verify(() => api.patch<Map<String, dynamic>>(
              '/calendrier/p1/semaines/2026-09-07',
              data: captureAny(named: 'data'),
            ))
        .captured
        .single as Map<String, dynamic>;
    expect(sent['label'], 'A');
    expect(sent['reason'], 'Projet');
  });
}
