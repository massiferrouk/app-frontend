import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/features/dashboard/home_etudiant_viewmodel.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/candidature.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockCandidatureService extends Mock implements CandidatureService {}

void main() {
  late MockLogementService logementService;
  late MockNotificationService notificationService;
  late MockCandidatureService candidatureService;
  late HomeEtudiantViewModel viewModel;

  Logement logement(String id) => Logement.fromJson({
        'id': id,
        'ownerId': 'o',
        'adresse': '1 rue Test',
        'ville': 'Paris',
        'codePostal': '75001',
        'type': 'STUDIO',
        'surface': 25.0,
        'nbPieces': 1,
        'loyer': 700.0,
        'charges': 0,
        'statut': 'ACTIF',
        'isVerified': false,
        'isMeuble': true,
      });

  Candidature candidature(String logementId) => Candidature(
        id: 'c-$logementId',
        statut: CandidatureStatut.A_CONTACTER,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        logement: logement(logementId),
      );

  setUp(() {
    logementService = MockLogementService();
    notificationService = MockNotificationService();
    candidatureService = MockCandidatureService();
    // Badge cloche : le load() rafraîchit aussi le compteur non-lues
    when(() => notificationService.getUnreadCount())
        .thenAnswer((_) async => 3);
    // Par défaut : aucune annonce suivie → aucun badge de statut
    when(() => candidatureService.getMesCandidatures())
        .thenAnswer((_) async => []);
    viewModel = HomeEtudiantViewModel(
      logementService: logementService,
      notificationService: notificationService,
      candidatureService: candidatureService,
      navigationService: MockNavigationService(),
    );
  });

  test('load rafraîchit le compteur de notifications non lues (APP-102)',
      () async {
    when(() => logementService.search()).thenAnswer(
        (_) async => (logements: <Logement>[], hasNext: false, total: 0));

    await viewModel.load();

    expect(viewModel.unreadCount, 3);
  });

  test('charge un aperçu de 3 annonces au maximum', () async {
    when(() => logementService.search()).thenAnswer((_) async => (
          logements: List.generate(8, (i) => logement('l$i')),
          hasNext: true,
          total: 8,
        ));

    await viewModel.load();

    // Aperçu limité à 3 : la liste complète est sur l'écran Recherche
    expect(viewModel.vedettes, hasLength(3));
  });

  test('isNouveau : true sans annonce suivie, false sinon (APP-120)',
      () async {
    when(() => logementService.search()).thenAnswer(
        (_) async => (logements: <Logement>[], hasNext: false, total: 0));

    // Aucune candidature → compte « neuf » → bloc « Bien démarrer » affiché
    await viewModel.load();
    expect(viewModel.isNouveau, isTrue);

    // Une annonce suivie → plus « neuf »
    when(() => candidatureService.getMesCandidatures())
        .thenAnswer((_) async => [candidature('l1')]);
    await viewModel.load();
    expect(viewModel.isNouveau, isFalse);
  });
}
