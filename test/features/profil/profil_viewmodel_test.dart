import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/profil/profil_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/services/review_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/reputation_score.dart';
import 'package:studup_app/shared/models/user.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockLogementService extends Mock implements LogementService {}

class MockReviewService extends Mock implements ReviewService {}

class MockAuthService extends Mock implements AuthService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockProfileService profileService;
  late MockLogementService logementService;
  late MockReviewService reviewService;
  late MockAuthService authService;
  late MockNavigationService nav;
  late ProfilViewModel viewModel;

  const user = User(
    id: 'user-1',
    email: 'alice@studup.fr',
    firstName: 'Alice',
    lastName: 'Martin',
    role: UserRole.ALTERNANT,
    isVerified: true,
  );

  setUp(() {
    profileService = MockProfileService();
    logementService = MockLogementService();
    reviewService = MockReviewService();
    authService = MockAuthService();
    nav = MockNavigationService();
    viewModel = ProfilViewModel(
      profileService: profileService,
      logementService: logementService,
      reviewService: reviewService,
      authService: authService,
      navigationService: nav,
    );
  });

  group('load', () {
    test('charge identité + enrichissements', () async {
      when(() => profileService.getMe()).thenAnswer((_) async => user);
      when(() => logementService.getReputation('user-1'))
          .thenAnswer((_) async => ReputationScore.fromJson(const {
                'userId': 'user-1',
                'avgRating': 4.2,
                'totalReviews': 12,
                'logementScore': 4.0,
                'nbAccords': 5,
                'badge': 'Fiable',
              }));
      when(() => reviewService.getReviewsForUser('user-1'))
          .thenAnswer((_) async => []);
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => []);

      await viewModel.load();

      expect(viewModel.user!.fullName, 'Alice Martin');
      expect(viewModel.isAlternant, isTrue);
      expect(viewModel.reputation!.badge, 'Fiable');
    });

    test('échec des enrichissements : profil affiché quand même', () async {
      when(() => profileService.getMe()).thenAnswer((_) async => user);
      when(() => logementService.getReputation(any())).thenThrow(
          const ApiException(
              code: 'NOT_FOUND', message: 'Pas de score', statusCode: 404));
      when(() => reviewService.getReviewsForUser(any())).thenThrow(
          const ApiException(
              code: 'ERROR', message: 'Erreur', statusCode: 500));
      when(() => logementService.getMesLogements()).thenThrow(
          const ApiException(
              code: 'ERROR', message: 'Erreur', statusCode: 500));

      await viewModel.load();

      expect(viewModel.user, isNotNull);
      expect(viewModel.reputation, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('échec de l\'identité : erreur bloquante', () async {
      when(() => profileService.getMe()).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.load();

      expect(viewModel.user, isNull);
      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('logout', () {
    test('révoque, purge et retourne au login', () async {
      when(() => authService.logout()).thenAnswer((_) async {});
      when(() => nav.clearStackAndShow(any()))
          .thenAnswer((_) async => null);

      await viewModel.logout();

      verify(() => authService.logout()).called(1);
      verify(() => nav.clearStackAndShow(any())).called(1);
    });
  });
}
