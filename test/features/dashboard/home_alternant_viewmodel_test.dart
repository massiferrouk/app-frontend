import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/dashboard/home_alternant_viewmodel.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/services/dashboard_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/alternant_dashboard.dart';

class MockDashboardService extends Mock implements DashboardService {}

class MockAccordService extends Mock implements AccordService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockDashboardService dashboardService;
  late MockNotificationService notificationService;
  late HomeAlternantViewModel viewModel;

  setUp(() {
    dashboardService = MockDashboardService();
    notificationService = MockNotificationService();
    // Badge cloche : le load() rafraîchit aussi le compteur non-lues
    when(() => notificationService.getUnreadCount())
        .thenAnswer((_) async => 2);
    viewModel = HomeAlternantViewModel(
      dashboardService: dashboardService,
      accordService: MockAccordService(),
      notificationService: notificationService,
      navigationService: MockNavigationService(),
    );
  });

  group('HomeAlternantViewModel.load', () {
    test('charge le dashboard avec succès', () async {
      final dash = AlternantDashboard.fromJson(const {
        'prochainAccords': [
          {
            'id': 'accord-1',
            'type': 'ECHANGE_TOTAL',
            'statut': 'EN_COURS',
            'dateDebut': '2026-07-14',
            'dateFin': '2026-09-30',
            'partnerId': 'user-2',
            'heuresAvantExpiration': null,
          }
        ],
        'accordsEnAttente': [],
        'economiesEstimees': 2700.50,
        'nbAccordsTermines': 3,
      });
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => dash);

      await viewModel.load();

      expect(viewModel.dashboard, isNotNull);
      expect(viewModel.dashboard!.economiesEstimees, 2700.50);
      expect(viewModel.dashboard!.nbAccordsTermines, 3);
      expect(viewModel.dashboard!.prochainAccords, hasLength(1));
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isBusy, isFalse);
    });

    test('erreur API : message stocké, pas de crash', () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur. Vérifie ta connexion.',
        statusCode: 0,
      ));

      await viewModel.load();

      expect(viewModel.dashboard, isNull);
      expect(viewModel.errorMessage, contains('Impossible de joindre'));
      expect(viewModel.isBusy, isFalse);
    });

    test('load rafraîchit le compteur de notifications non lues', () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));

      await viewModel.load();

      expect(viewModel.unreadCount, 2);
    });

    test('erreur sur le compteur de notifs : silencieuse, dashboard intact',
        () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      when(() => notificationService.getUnreadCount())
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Réseau indisponible',
        statusCode: 0,
      ));

      await viewModel.load();

      // Le badge est secondaire : pas d'erreur affichée, badge à 0
      expect(viewModel.dashboard, isNotNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.unreadCount, 0);
    });

    test('un rechargement réussi efface l\'erreur précédente', () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Réseau indisponible',
        statusCode: 0,
      ));
      await viewModel.load();
      expect(viewModel.errorMessage, isNotNull);

      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      await viewModel.load();

      expect(viewModel.errorMessage, isNull);
      expect(viewModel.dashboard, isNotNull);
    });
  });
}
