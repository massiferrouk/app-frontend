import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/avis/avis_viewmodel.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/services/review_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/review.dart';

class MockReviewService extends Mock implements ReviewService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockReviewService reviewService;
  late MockProfileService profileService;
  late MockNavigationService nav;

  final review = Review.fromJson({
    'id': 'r1',
    'authorId': 'moi',
    'targetType': 'USER',
    'rating': 4,
    'comment': 'Super échange',
    'createdAt': DateTime.now().toIso8601String(),
  });

  Accord buildAccord({
    String initiatorId = 'moi',
    String receiverId = 'lui',
    String? logementAId,
    String? logementBId,
  }) =>
      Accord.fromJson({
        'id': 'a1',
        'initiatorId': initiatorId,
        'receiverId': receiverId,
        'logementAId': logementAId,
        'logementBId': logementBId,
        'type': 'ECHANGE_TOTAL',
        'statut': 'TERMINE',
        'dateDebut': '2026-01-01',
        'dateFin': '2026-06-30',
        'createdAt': DateTime.now().toIso8601String(),
      });

  AvisViewModel makeViewModel(Accord accord) => AvisViewModel(
        accord: accord,
        reviewService: reviewService,
        profileService: profileService,
        navigationService: nav,
      );

  setUpAll(() => registerFallbackValue(ReviewTargetType.USER));

  setUp(() {
    reviewService = MockReviewService();
    profileService = MockProfileService();
    nav = MockNavigationService();
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
  });

  group('partenaire et logement cible', () {
    test('initiateur : le partenaire est le destinataire, son logement le B',
        () async {
      final viewModel = makeViewModel(buildAccord(
          initiatorId: 'moi', receiverId: 'lui', logementBId: 'log-b'));
      await viewModel.init();

      expect(viewModel.partnerId, 'lui');
      expect(viewModel.partnerLogementId, 'log-b');
      expect(viewModel.peutNoterLogement, isTrue);
    });

    test('destinataire : le partenaire est l\'initiateur, son logement le A',
        () async {
      final viewModel = makeViewModel(buildAccord(
          initiatorId: 'lui', receiverId: 'moi', logementAId: 'log-a'));
      await viewModel.init();

      expect(viewModel.partnerId, 'lui');
      expect(viewModel.partnerLogementId, 'log-a');
    });

    test('pas de logement partenaire : cible LOGEMENT indisponible',
        () async {
      final viewModel = makeViewModel(buildAccord());
      await viewModel.init();

      expect(viewModel.peutNoterLogement, isFalse);
    });
  });

  group('submit', () {
    test('sans note : erreur locale, aucun appel', () async {
      final viewModel = makeViewModel(buildAccord());
      await viewModel.init();

      await viewModel.submit();

      expect(viewModel.errorMessage, contains('note'));
      verifyNever(() => reviewService.createReview(
            accordId: any(named: 'accordId'),
            targetType: any(named: 'targetType'),
            targetUserId: any(named: 'targetUserId'),
            targetLogementId: any(named: 'targetLogementId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          ));
    });

    test('avis USER : envoie le partnerId, pas de logement', () async {
      final viewModel = makeViewModel(buildAccord());
      await viewModel.init();
      viewModel.setRating(5);
      viewModel.commentController.text = 'Top !';

      when(() => reviewService.createReview(
            accordId: any(named: 'accordId'),
            targetType: any(named: 'targetType'),
            targetUserId: any(named: 'targetUserId'),
            targetLogementId: any(named: 'targetLogementId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          )).thenAnswer((_) async => review);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit();

      verify(() => reviewService.createReview(
            accordId: 'a1',
            targetType: ReviewTargetType.USER,
            targetUserId: 'lui',
            targetLogementId: null,
            rating: 5,
            comment: 'Top !',
          )).called(1);
      verify(() => nav.back(result: true)).called(1);
    });

    test('avis LOGEMENT : envoie le logement du partenaire', () async {
      final viewModel =
          makeViewModel(buildAccord(logementBId: 'log-b'));
      await viewModel.init();
      viewModel.setRating(4);
      viewModel.setTargetType(ReviewTargetType.LOGEMENT);

      when(() => reviewService.createReview(
            accordId: any(named: 'accordId'),
            targetType: any(named: 'targetType'),
            targetUserId: any(named: 'targetUserId'),
            targetLogementId: any(named: 'targetLogementId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          )).thenAnswer((_) async => review);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit();

      verify(() => reviewService.createReview(
            accordId: 'a1',
            targetType: ReviewTargetType.LOGEMENT,
            targetUserId: null,
            targetLogementId: 'log-b',
            rating: 4,
            comment: null,
          )).called(1);
    });

    test('409 doublon : message métier clair', () async {
      final viewModel = makeViewModel(buildAccord());
      await viewModel.init();
      viewModel.setRating(3);

      when(() => reviewService.createReview(
            accordId: any(named: 'accordId'),
            targetType: any(named: 'targetType'),
            targetUserId: any(named: 'targetUserId'),
            targetLogementId: any(named: 'targetLogementId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          )).thenThrow(const ApiException(
        code: 'CONFLICT',
        message: 'Conflit',
        statusCode: 409,
      ));

      await viewModel.submit();

      expect(viewModel.errorMessage,
          'Tu as déjà laissé un avis pour cet accord');
      verifyNever(() => nav.back(result: any(named: 'result')));
    });
  });
}
