import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/dashboard/home_etudiant_viewmodel.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockAccordService extends Mock implements AccordService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockCandidatureService extends Mock implements CandidatureService {}

void main() {
  late MockLogementService logementService;
  late MockAccordService accordService;
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

  Accord accord(AccordStatut statut) => Accord.fromJson({
        'id': 'a-${statut.name}',
        'initiatorId': 'moi',
        'receiverId': 'lui',
        'type': 'LOCATION_CLASSIQUE',
        'statut': statut.toJson(),
        'dateDebut': '2026-09-01',
        'dateFin': '2027-06-30',
        'createdAt': DateTime.now().toIso8601String(),
      });

  setUp(() {
    logementService = MockLogementService();
    accordService = MockAccordService();
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
      accordService: accordService,
      notificationService: notificationService,
      candidatureService: candidatureService,
      navigationService: MockNavigationService(),
    );
  });

  test('load rafraîchit le compteur de notifications non lues (APP-102)',
      () async {
    when(() => logementService.search()).thenAnswer(
        (_) async => (logements: <Logement>[], hasNext: false, total: 0));
    when(() => accordService.getMesAccords()).thenAnswer((_) async => []);

    await viewModel.load();

    expect(viewModel.unreadCount, 3);
  });

  test('charge un aperçu de 3 annonces et les accords en cours uniquement',
      () async {
    when(() => logementService.search()).thenAnswer((_) async => (
          logements: List.generate(8, (i) => logement('l$i')),
          hasNext: true,
          total: 8,
        ));
    when(() => accordService.getMesAccords()).thenAnswer((_) async => [
          accord(AccordStatut.EN_COURS),
          accord(AccordStatut.TERMINE),
          accord(AccordStatut.EN_ATTENTE),
        ]);

    await viewModel.load();

    // Aperçu limité à 3 : la liste complète est sur l'écran Recherche
    expect(viewModel.vedettes, hasLength(3));
    expect(viewModel.accordsEnCours.map((a) => a.statut),
        [AccordStatut.EN_COURS, AccordStatut.EN_ATTENTE]);
  });

  test('échec des accords : les vedettes s\'affichent quand même', () async {
    when(() => logementService.search())
        .thenAnswer((_) async =>
            (logements: [logement('l1')], hasNext: false, total: 1));
    when(() => accordService.getMesAccords()).thenThrow(const ApiException(
        code: 'ERROR', message: 'Erreur', statusCode: 500));

    await viewModel.load();

    expect(viewModel.vedettes, hasLength(1));
    expect(viewModel.accordsEnCours, isEmpty);
  });

  test('isNouveau : true sans accord en cours, false sinon (APP-117)',
      () async {
    when(() => logementService.search())
        .thenAnswer((_) async => (logements: <Logement>[], hasNext: false, total: 0));

    // Aucun accord → compte « neuf » → bloc « Bien démarrer » affiché
    when(() => accordService.getMesAccords()).thenAnswer((_) async => []);
    await viewModel.load();
    expect(viewModel.isNouveau, isTrue);

    // Un accord en cours → plus « neuf »
    when(() => accordService.getMesAccords())
        .thenAnswer((_) async => [accord(AccordStatut.EN_COURS)]);
    await viewModel.load();
    expect(viewModel.isNouveau, isFalse);
  });
}
