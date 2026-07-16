import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/onboarding/onboarding_viewmodel.dart';
import 'package:studup_app/services/onboarding_service.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockOnboardingService onboarding;
  late MockNavigationService nav;
  late OnboardingViewModel viewModel;

  setUp(() {
    onboarding = MockOnboardingService();
    nav = MockNavigationService();
    when(() => onboarding.marquerVu()).thenAnswer((_) async {});
    when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);
    viewModel = OnboardingViewModel(
      onboardingService: onboarding,
      navigationService: nav,
    );
  });

  group('OnboardingViewModel', () {
    test('démarre sur la première page', () {
      expect(viewModel.pageCourante, 0);
      expect(viewModel.dernierePage, isFalse);
    });

    test('onPageChanged suit le swipe', () {
      viewModel.onPageChanged(2);

      expect(viewModel.pageCourante, 2);
      expect(viewModel.dernierePage, isTrue);
    });

    test('terminer : marque vu puis va au login sans retour possible',
        () async {
      await viewModel.terminer();

      verify(() => onboarding.marquerVu()).called(1);
      verify(() => nav.clearStackAndShow(Routes.loginView)).called(1);
    });

    test('suivant sur la dernière page = terminer', () async {
      viewModel.onPageChanged(OnboardingViewModel.nbPages - 1);

      await viewModel.suivant();

      verify(() => onboarding.marquerVu()).called(1);
      verify(() => nav.clearStackAndShow(Routes.loginView)).called(1);
    });
  });
}
