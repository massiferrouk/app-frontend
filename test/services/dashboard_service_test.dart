import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/dashboard_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late DashboardService service;

  setUp(() {
    api = MockApiClient();
    service = DashboardService(apiClient: api);
  });

  test('getAlternantDashboard parse les KPIs', () async {
    when(() => api.get<Map<String, dynamic>>('/dashboard/alternant'))
        .thenAnswer((_) async => {
              'prochainAccords': [],
              'accordsEnAttente': [],
              'economiesEstimees': 600.0,
              'nbAccordsTermines': 2,
            });

    final dashboard = await service.getAlternantDashboard();

    expect(dashboard.economiesEstimees, 600.0);
    expect(dashboard.nbAccordsTermines, 2);
  });

  test('getProprietaireDashboard parse KPIs et logements', () async {
    when(() => api.get<Map<String, dynamic>>('/dashboard/proprietaire'))
        .thenAnswer((_) async => {
              'nbLogementsTotaux': 3,
              'nbLogementsActifs': 2,
              'nbLocatairesActifs': 1,
              'tauxOccupation': 0.66,
              'logements': [
                {
                  'id': 'l1',
                  'ville': 'Paris',
                  'adresse': '1 rue X',
                  'type': 'STUDIO',
                  'statut': 'ACTIF',
                  'loyer': 700.0,
                  'isOccupe': true,
                }
              ],
            });

    final dashboard = await service.getProprietaireDashboard();

    expect(dashboard.nbLogementsTotaux, 3);
    expect(dashboard.logements, hasLength(1));
    expect(dashboard.logements.first.ville, 'Paris');
  });
}
