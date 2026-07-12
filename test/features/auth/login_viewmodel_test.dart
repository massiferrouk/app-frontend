import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/auth/login/login_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/profile_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAuthService auth;
  late MockProfileService profile;
  late MockNavigationService nav;
  late LoginViewModel viewModel;

  setUp(() {
    auth = MockAuthService();
    profile = MockProfileService();
    nav = MockNavigationService();
    viewModel = LoginViewModel(
      authService: auth,
      profileService: profile,
      navigationService: nav,
    );

    // Par défaut : pas besoin de créer de profil
    when(() => profile.needsAlternantProfile())
        .thenAnswer((_) async => false);
  });

  group('LoginViewModel.login', () {
    test('email invalide : erreur locale, aucun appel réseau', () async {
      viewModel.emailController.text = 'pas-un-email';
      viewModel.passwordController.text = 'motdepasse123';

      await viewModel.login();

      expect(viewModel.errorMessage, 'Format d\'email invalide');
      verifyNever(() => auth.login(
          email: any(named: 'email'), password: any(named: 'password')));
    });

    test('mot de passe trop court : erreur locale', () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'court';

      await viewModel.login();

      expect(viewModel.errorMessage, 'Au moins 8 caractères');
    });

    test('succès : login puis navigation vers Home (pile vidée)', () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'motdepasse123';

      when(() => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'))).thenAnswer((_) async {});
      when(() => nav.clearStackAndShow(any()))
          .thenAnswer((_) async => null);

      await viewModel.login();

      expect(viewModel.errorMessage, isNull);
      verify(() => auth.login(
          email: 'alice@studup.fr', password: 'motdepasse123')).called(1);
      verify(() => nav.clearStackAndShow(Routes.mainView)).called(1);
    });

    test('alternant sans profil : redirection vers la création de profil',
        () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'motdepasse123';

      when(() => auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'))).thenAnswer((_) async {});
      when(() => profile.needsAlternantProfile())
          .thenAnswer((_) async => true);
      when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);

      await viewModel.login();

      verify(() => nav.clearStackAndShow(Routes.profilCreationView))
          .called(1);
      verifyNever(() => nav.clearStackAndShow(Routes.mainView));
    });

    test('401 : message "email ou mot de passe incorrect", pas de navigation',
        () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'mauvais-mdp';

      when(() => auth.login(
              email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ApiException(
        code: 'BAD_CREDENTIALS',
        message: 'Bad credentials',
        statusCode: 401,
      ));

      await viewModel.login();

      expect(viewModel.errorMessage, 'Email ou mot de passe incorrect');
      expect(viewModel.isBusy, isFalse);
      verifyNever(() => nav.clearStackAndShow(any()));
    });

    test('401 EMAIL_NOT_CONFIRMED : message dédié, pas "mot de passe incorrect"',
        () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'motdepasse123';

      when(() => auth.login(
              email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ApiException(
        code: 'EMAIL_NOT_CONFIRMED',
        message: 'Confirme ton adresse email avant de te connecter',
        statusCode: 401,
      ));

      await viewModel.login();

      expect(viewModel.errorMessage, contains('Confirme ton adresse email'));
      expect(viewModel.errorMessage,
          isNot(contains('mot de passe incorrect')));
      verifyNever(() => nav.clearStackAndShow(any()));
    });

    test('erreur réseau : le message ApiException est affiché', () async {
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'motdepasse123';

      when(() => auth.login(
              email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur. Vérifie ta connexion.',
        statusCode: 0,
      ));

      await viewModel.login();

      expect(viewModel.errorMessage, contains('Impossible de joindre'));
    });
  });
}
