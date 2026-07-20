import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/dashboard/home_proprio_viewmodel.dart';
import 'package:studup_app/services/dashboard_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/shared/models/proprietaire_dashboard.dart';

class MockDashboardService extends Mock implements DashboardService {}

class MockLogementService extends Mock implements LogementService {}

void main() {
  late MockDashboardService dashboardService;
  late MockLogementService logementService;
  late HomeProprioViewModel viewModel;

  Map<String, dynamic> logementJson(
          {required String id, required String statut, required bool occupe}) =>
      {
        'id': id,
        'ville': 'Paris',
        'adresse': '1 rue Test',
        'type': 'STUDIO',
        'statut': statut,
        'loyer': 800.0,
        'isOccupe': occupe,
      };

  setUp(() {
    dashboardService = MockDashboardService();
    logementService = MockLogementService();
    viewModel = HomeProprioViewModel(
      dashboardService: dashboardService,
      logementService: logementService,
    );
    // L'aperçu de l'accueil charge la liste complète des logements (photos) ;
    // les tests portent sur les KPIs/alertes, une liste vide suffit ici.
    when(() => logementService.getMesLogements()).thenAnswer((_) async => []);
  });

  test('charge les KPIs', () async {
    when(() => dashboardService.getProprietaireDashboard())
        .thenAnswer((_) async => ProprietaireDashboard.fromJson({
              'nbLogementsTotaux': 3,
              'nbLogementsActifs': 2,
              'nbLocatairesActifs': 1,
              'tauxOccupation': 50.0,
              'logements': [
                logementJson(id: 'l1', statut: 'ACTIF', occupe: true),
                logementJson(id: 'l2', statut: 'ACTIF', occupe: false),
                logementJson(id: 'l3', statut: 'BROUILLON', occupe: false),
              ],
            }));

    await viewModel.load();

    expect(viewModel.dashboard!.tauxOccupation, 50.0);
    expect(viewModel.dashboard!.logements, hasLength(3));
  });

  test('alertes dérivées : brouillons non publiés + actifs vacants',
      () async {
    when(() => dashboardService.getProprietaireDashboard())
        .thenAnswer((_) async => ProprietaireDashboard.fromJson({
              'nbLogementsTotaux': 3,
              'nbLogementsActifs': 2,
              'nbLocatairesActifs': 1,
              'tauxOccupation': 50.0,
              'logements': [
                logementJson(id: 'l1', statut: 'ACTIF', occupe: true),
                logementJson(id: 'l2', statut: 'ACTIF', occupe: false),
                logementJson(id: 'l3', statut: 'BROUILLON', occupe: false),
              ],
            }));

    await viewModel.load();

    expect(viewModel.alertes, hasLength(2));
    expect(viewModel.alertes[0], contains('brouillon'));
    expect(viewModel.alertes[1], contains('sans locataire'));
  });

  test('aucune alerte quand tout est publié et occupé', () async {
    when(() => dashboardService.getProprietaireDashboard())
        .thenAnswer((_) async => ProprietaireDashboard.fromJson({
              'nbLogementsTotaux': 1,
              'nbLogementsActifs': 1,
              'nbLocatairesActifs': 1,
              'tauxOccupation': 100.0,
              'logements': [
                logementJson(id: 'l1', statut: 'ACTIF', occupe: true),
              ],
            }));

    await viewModel.load();

    expect(viewModel.alertes, isEmpty);
  });

  test('erreur API : message stocké', () async {
    when(() => dashboardService.getProprietaireDashboard()).thenThrow(
        const ApiException(
            code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

    await viewModel.load();

    expect(viewModel.errorMessage, 'Hors ligne');
    expect(viewModel.alertes, isEmpty);
  });
}
