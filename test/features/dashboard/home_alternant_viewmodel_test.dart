import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/dashboard/home_alternant_viewmodel.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/services/calendrier_service.dart';
import 'package:studup_app/services/dashboard_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/alternant_dashboard.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';
import 'package:studup_app/shared/models/mes_semaines.dart';

class MockDashboardService extends Mock implements DashboardService {}

class MockAccordService extends Mock implements AccordService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockCalendrierService extends Mock implements CalendrierService {}

class MockLogementService extends Mock implements LogementService {}

void main() {
  late MockDashboardService dashboardService;
  late MockNotificationService notificationService;
  late MockCalendrierService calendrierService;
  late MockLogementService logementService;
  late HomeAlternantViewModel viewModel;

  setUp(() {
    dashboardService = MockDashboardService();
    notificationService = MockNotificationService();
    calendrierService = MockCalendrierService();
    logementService = MockLogementService();
    // Badge cloche : le load() rafraîchit aussi le compteur non-lues
    when(() => notificationService.getUnreadCount())
        .thenAnswer((_) async => 2);
    // Enrichissements par défaut : calendrier indisponible, aucun logement
    // (surchargés dans les tests dédiés).
    when(() => calendrierService.getMesSemaines()).thenThrow(
        const ApiException(code: 'X', message: 'no cal', statusCode: 404));
    when(() => logementService.getMesLogements())
        .thenAnswer((_) async => const []);
    viewModel = HomeAlternantViewModel(
      dashboardService: dashboardService,
      accordService: MockAccordService(),
      calendrierService: calendrierService,
      logementService: logementService,
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

  group('accueil enrichi (APP-117)', () {
    Future<void> loadWithEmptyDash() async {
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      await viewModel.load();
    }

    test('carte cette semaine : ville courante (école) et suivante (entreprise)',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final nextMonday = monday.add(const Duration(days: 7));
      final mes = MesSemaines(
        profileId: 'p1',
        villeA: 'Paris',
        villeB: 'Lyon',
        rythme: RythmeAlternance.SEMAINE_1_1,
        semaines: [
          AlternanceSemaine(
              id: 's1', semaine: monday, label: 'A', isOverridden: false),
          AlternanceSemaine(
              id: 's2', semaine: nextMonday, label: 'B', isOverridden: false),
        ],
      );
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => mes);

      await viewModel.load();

      expect(viewModel.semaineCourante, isNotNull);
      // label 'A' → villeA (école)
      expect(viewModel.villeDe(viewModel.semaineCourante!), 'Paris');
      expect(viewModel.estEcole(viewModel.semaineCourante!), isTrue);
      // label 'B' → villeB (entreprise)
      expect(viewModel.villeDe(viewModel.semaineProchaine!), 'Lyon');
      expect(viewModel.estEcole(viewModel.semaineProchaine!), isFalse);
    });

    test('isNouveau : true sans aucun accord', () async {
      await loadWithEmptyDash();
      expect(viewModel.isNouveau, isTrue);
    });

    test('isNouveau : false dès qu\'un prochain accord existe', () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [
                  {
                    'id': 'a',
                    'type': 'ECHANGE_TOTAL',
                    'statut': 'EN_COURS',
                    'dateDebut': '2026-07-14',
                    'dateFin': '2026-09-30',
                    'partnerId': 'u2',
                    'heuresAvantExpiration': null,
                  }
                ],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      await viewModel.load();
      expect(viewModel.isNouveau, isFalse);
    });

    test('hasPublishedLogement : true si un logement est ACTIF', () async {
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      when(() => logementService.getMesLogements()).thenAnswer((_) async => [
            Logement.fromJson(const {
              'id': 'l1',
              'ownerId': 'u1',
              'adresse': '1 rue',
              'ville': 'Paris',
              'codePostal': '75001',
              'type': 'STUDIO',
              'statut': 'ACTIF',
            })
          ]);

      await viewModel.load();

      expect(viewModel.hasPublishedLogement, isTrue);
    });

    test('alternance pas commencée : affiche la 1re semaine future', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final future1 = monday.add(const Duration(days: 21)); // dans 3 semaines
      final future2 = monday.add(const Duration(days: 28));
      // Insérées dans le désordre : semaineAAfficher doit prendre la plus proche
      final mes = MesSemaines(
        profileId: 'p1',
        villeA: 'Paris',
        villeB: 'Lyon',
        rythme: RythmeAlternance.SEMAINE_1_1,
        semaines: [
          AlternanceSemaine(
              id: 's2', semaine: future2, label: 'B', isOverridden: false),
          AlternanceSemaine(
              id: 's1', semaine: future1, label: 'A', isOverridden: false),
        ],
      );
      when(() => dashboardService.getAlternantDashboard())
          .thenAnswer((_) async => AlternantDashboard.fromJson(const {
                'prochainAccords': [],
                'accordsEnAttente': [],
                'economiesEstimees': 0,
                'nbAccordsTermines': 0,
              }));
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => mes);

      await viewModel.load();

      expect(viewModel.alternanceCommencee, isFalse);
      expect(viewModel.semaineCourante, isNull);
      expect(viewModel.semaineAAfficher, isNotNull);
      expect(viewModel.semaineAAfficher!.id, 's1');
    });
  });
}
