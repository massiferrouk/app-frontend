import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/accords/accord_detail_viewmodel.dart';
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

  Accord build({
    AccordStatut statut = AccordStatut.EN_ATTENTE,
    String initiatorId = 'lui',
    String receiverId = 'moi',
  }) =>
      Accord.fromJson({
        'id': 'a1',
        'initiatorId': initiatorId,
        'receiverId': receiverId,
        'type': 'ECHANGE_TOTAL',
        'statut': statut.toJson(),
        'dateDebut': '2026-09-01',
        'dateFin': '2026-12-31',
        'createdAt': DateTime.now().toIso8601String(),
      });

  AccordDetailViewModel makeViewModel(Accord accord) => AccordDetailViewModel(
        accord: accord,
        accordService: accordService,
        profileService: profileService,
        navigationService: MockNavigationService(),
      );

  setUp(() {
    accordService = MockAccordService();
    profileService = MockProfileService();
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
  });

  test('destinataire d\'une demande en attente : peut répondre', () async {
    final viewModel = makeViewModel(build());
    await viewModel.init();

    expect(viewModel.canAcceptOrRefuse, isTrue);
    expect(viewModel.canCancel, isFalse);
    expect(viewModel.jeSuisInitiateur, isFalse);
  });

  test('initiateur : peut seulement annuler', () async {
    final viewModel =
        makeViewModel(build(initiatorId: 'moi', receiverId: 'lui'));
    await viewModel.init();

    expect(viewModel.canAcceptOrRefuse, isFalse);
    expect(viewModel.canCancel, isTrue);
    expect(viewModel.jeSuisInitiateur, isTrue);
  });

  test('contacter : possible seulement une fois l\'accord accepté', () async {
    final enAttente = makeViewModel(build());
    await enAttente.init();
    expect(enAttente.canContact, isFalse);

    final accepte = makeViewModel(build(statut: AccordStatut.ACCEPTE));
    await accepte.init();
    expect(accepte.canContact, isTrue);
  });

  test('accept : l\'accord local est remplacé par la réponse serveur',
      () async {
    final viewModel = makeViewModel(build());
    await viewModel.init();

    when(() => accordService.accept('a1'))
        .thenAnswer((_) async => build(statut: AccordStatut.ACCEPTE));

    final error = await viewModel.accept();

    expect(error, isNull);
    expect(viewModel.accord.statut, AccordStatut.ACCEPTE);
    // Plus aucune action possible après acceptation
    expect(viewModel.canAcceptOrRefuse, isFalse);
  });

  test('erreur backend : message retourné, accord inchangé', () async {
    final viewModel = makeViewModel(build());
    await viewModel.init();

    when(() => accordService.accept('a1')).thenThrow(const ApiException(
        code: 'CONFLICT', message: 'Accord déjà traité', statusCode: 409));

    final error = await viewModel.accept();

    expect(error, 'Accord déjà traité');
    expect(viewModel.accord.statut, AccordStatut.EN_ATTENTE);
  });
}
