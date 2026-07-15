import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/dashboard/home_etudiant_viewmodel.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockAccordService extends Mock implements AccordService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockLogementService logementService;
  late MockAccordService accordService;
  late MockNotificationService notificationService;
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
    // Badge cloche : le load() rafraîchit aussi le compteur non-lues
    when(() => notificationService.getUnreadCount())
        .thenAnswer((_) async => 3);
    viewModel = HomeEtudiantViewModel(
      logementService: logementService,
      accordService: accordService,
      notificationService: notificationService,
      navigationService: MockNavigationService(),
    );
  });

  test('load rafraîchit le compteur de notifications non lues (APP-102)',
      () async {
    when(() => logementService.search()).thenAnswer(
        (_) async => (logements: <Logement>[], hasNext: false));
    when(() => accordService.getMesAccords()).thenAnswer((_) async => []);

    await viewModel.load();

    expect(viewModel.unreadCount, 3);
  });

  test('charge vedettes (max 5) et accords en cours uniquement', () async {
    when(() => logementService.search()).thenAnswer((_) async => (
          logements: List.generate(8, (i) => logement('l$i')),
          hasNext: true,
        ));
    when(() => accordService.getMesAccords()).thenAnswer((_) async => [
          accord(AccordStatut.EN_COURS),
          accord(AccordStatut.TERMINE),
          accord(AccordStatut.EN_ATTENTE),
        ]);

    await viewModel.load();

    expect(viewModel.vedettes, hasLength(5));
    expect(viewModel.accordsEnCours.map((a) => a.statut),
        [AccordStatut.EN_COURS, AccordStatut.EN_ATTENTE]);
  });

  test('échec des accords : les vedettes s\'affichent quand même', () async {
    when(() => logementService.search())
        .thenAnswer((_) async => (logements: [logement('l1')], hasNext: false));
    when(() => accordService.getMesAccords()).thenThrow(const ApiException(
        code: 'ERROR', message: 'Erreur', statusCode: 500));

    await viewModel.load();

    expect(viewModel.vedettes, hasLength(1));
    expect(viewModel.accordsEnCours, isEmpty);
  });
}
