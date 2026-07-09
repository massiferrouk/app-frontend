import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/startup/startup_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/profile_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAuthService auth;
  late MockProfileService profile;
  late MockNavigationService nav;
  late StartupViewModel viewModel;

  setUp(() {
    auth = MockAuthService();
    profile = MockProfileService();
    nav = MockNavigationService();
    viewModel = StartupViewModel(
      authService: auth,
      profileService: profile,
      navigationService: nav,
    );

    when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);
    when(() => profile.needsAlternantProfile())
        .thenAnswer((_) async => false);
  });

  group('StartupViewModel.runStartupLogic', () {
    test('session existante avec profil : redirige vers Home', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => true);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.homeView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.loginView));
    });

    test('pas de session : redirige vers Login', () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => false);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.loginView)).called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.homeView));
    });

    test('alternant sans profil : redirige vers la création de profil',
        () async {
      when(() => auth.isLoggedIn()).thenAnswer((_) async => true);
      when(() => profile.needsAlternantProfile())
          .thenAnswer((_) async => true);

      await viewModel.runStartupLogic();

      verify(() => nav.clearStackAndShow(Routes.profilCreationView))
          .called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.homeView));
    });
  });
}
