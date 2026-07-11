import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/accords/mes_accords_viewmodel.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockAccordService extends Mock implements AccordService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAccordService accordService;
  late MockProfileService profileService;
  late MesAccordsViewModel viewModel;

  Accord build({
    required String id,
    required AccordStatut statut,
    String initiatorId = 'moi',
    String receiverId = 'lui',
  }) =>
      Accord.fromJson({
        'id': id,
        'initiatorId': initiatorId,
        'receiverId': receiverId,
        'logementAId': null,
        'logementBId': null,
        'type': 'ECHANGE_TOTAL',
        'statut': statut.toJson(),
        'dateDebut': '2026-09-01',
        'dateFin': '2026-12-31',
        'montantLoyer': null,
        'messageInitial': null,
        'createdAt': DateTime.now().toIso8601String(),
      });

  setUp(() {
    accordService = MockAccordService();
    profileService = MockProfileService();
    viewModel = MesAccordsViewModel(
      accordService: accordService,
      profileService: profileService,
      navigationService: MockNavigationService(),
    );
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
  });

  group('tabs', () {
    test('en cours / terminés / tous filtrent par statut', () async {
      when(() => accordService.getMesAccords()).thenAnswer((_) async => [
            build(id: 'a1', statut: AccordStatut.EN_ATTENTE),
            build(id: 'a2', statut: AccordStatut.EN_COURS),
            build(id: 'a3', statut: AccordStatut.TERMINE),
            build(id: 'a4', statut: AccordStatut.REFUSE),
          ]);

      await viewModel.load();

      // onglet par défaut : en cours
      expect(viewModel.accords.map((a) => a.id), ['a1', 'a2']);

      viewModel.setTab(AccordTab.termines);
      expect(viewModel.accords.map((a) => a.id), ['a3', 'a4']);

      viewModel.setTab(AccordTab.tous);
      expect(viewModel.accords, hasLength(4));
    });
  });

  group('règles d\'action', () {
    test('le destinataire peut accepter/refuser, pas l\'initiateur',
        () async {
      when(() => accordService.getMesAccords()).thenAnswer((_) async => [
            // je suis DESTINATAIRE de a1
            build(
                id: 'a1',
                statut: AccordStatut.EN_ATTENTE,
                initiatorId: 'lui',
                receiverId: 'moi'),
            // je suis INITIATEUR de a2
            build(
                id: 'a2',
                statut: AccordStatut.EN_ATTENTE,
                initiatorId: 'moi',
                receiverId: 'lui'),
          ]);

      await viewModel.load();
      final recu = viewModel.accords[0];
      final envoye = viewModel.accords[1];

      expect(viewModel.canAcceptOrRefuse(recu), isTrue);
      expect(viewModel.canCancel(recu), isFalse);

      expect(viewModel.canAcceptOrRefuse(envoye), isFalse);
      expect(viewModel.canCancel(envoye), isTrue);
    });

    test('aucune action sur un accord non EN_ATTENTE', () async {
      when(() => accordService.getMesAccords()).thenAnswer((_) async => [
            build(
                id: 'a1',
                statut: AccordStatut.EN_COURS,
                initiatorId: 'lui',
                receiverId: 'moi'),
          ]);

      await viewModel.load();
      final accord = viewModel.accords.first;

      expect(viewModel.canAcceptOrRefuse(accord), isFalse);
      expect(viewModel.canCancel(accord), isFalse);
    });
  });

  group('actions', () {
    test('accept : appelle le service puis recharge', () async {
      final accord = build(
          id: 'a1',
          statut: AccordStatut.EN_ATTENTE,
          initiatorId: 'lui',
          receiverId: 'moi');
      when(() => accordService.getMesAccords())
          .thenAnswer((_) async => [accord]);
      await viewModel.load();

      when(() => accordService.accept('a1')).thenAnswer(
          (_) async => build(id: 'a1', statut: AccordStatut.ACCEPTE));

      final error = await viewModel.accept(accord);

      expect(error, isNull);
      verify(() => accordService.getMesAccords()).called(2);
    });

    test('erreur backend : message retourné', () async {
      final accord = build(id: 'a1', statut: AccordStatut.EN_ATTENTE);
      when(() => accordService.getMesAccords())
          .thenAnswer((_) async => [accord]);
      await viewModel.load();

      when(() => accordService.refuse('a1')).thenThrow(const ApiException(
          code: 'FORBIDDEN', message: 'Action non autorisée', statusCode: 403));

      final error = await viewModel.refuse(accord);

      expect(error, 'Action non autorisée');
    });
  });

  group('countdown', () {
    test('72h après création, heuresAvantExpiration décroît', () {
      final frais = build(id: 'a1', statut: AccordStatut.EN_ATTENTE);
      expect(frais.heuresAvantExpiration, inInclusiveRange(70, 72));

      final termine = build(id: 'a2', statut: AccordStatut.TERMINE);
      expect(termine.heuresAvantExpiration, isNull);
    });
  });
}
