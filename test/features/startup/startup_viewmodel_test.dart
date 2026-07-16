import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/startup/startup_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/onboarding_service.dart';
import 'package:studup_app/services/profile_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late MockAuthService auth;
  late MockProfileService profile;
  late MockNavigationService nav;
  late MockOnboardingService onboarding;
  late StartupViewModel viewModel;

  setUp(() {
    auth = MockAuthService();
    profile = MockProfileService();
    nav = MockNavigationService();
    onboarding = MockOnboardingService();
    viewModel = StartupViewModel(
      authService: auth,
      profileService: profile,
      onboardingService: onboarding,
      navigationService: nav,
    );

    when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);
    when(() => profile.needsAlternantProfile())
        .thenAnswer((_) async => false);
    // Par défaut : onboarding déjà vu (les tests existants restent valides)
    when(() => onboarding.dejaVu()).thenAnswer((_) async => true);
  });

  group('StartupViewModel.runStartupLogic', () {
    test('session existante avec profil : redirige vers Home', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => true);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.mainView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.loginView));
    });

    test('pas de session : redirige vers Login', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => false);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.loginView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.mainView));
    });

    test('premier lancement : redirige vers l\'onboarding (APP-105)',
        () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => false);
      when(() => onboarding.dejaVu()).thenAnswer((_) async => false);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.onboardingView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.loginView));
    });

    test('session existante : jamais d\'onboarding même si pas vu', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => true);
      when(() => onboarding.dejaVu()).thenAnswer((_) async => false);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.mainView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.onboardingView));
    });

    test('alternant sans profil : redirige vers la création de profil',
        () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => true);
      when(() => profile.needsAlternantProfile())
          .thenAnswer((_) async => true);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.profilCreationView))
          .called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.mainView));
    });
  });
}
