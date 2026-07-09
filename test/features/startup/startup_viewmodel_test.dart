import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/startup/startup_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAuthService auth;
  late MockNavigationService nav;
  late StartupViewModel viewModel;

  setUp(() {
    auth = MockAuthService();
    nav = MockNavigationService();
    viewModel = StartupViewModel(authService: auth, navigationService: nav);

    when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);
  });

  group('StartupViewModel.runStartupLogic', () {
    test('session existante : redirige vers Home', () async {
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
  });
}
