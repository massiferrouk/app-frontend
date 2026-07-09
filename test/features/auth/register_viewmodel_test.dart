import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/auth/register/register_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/user.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAuthService auth;
  late MockNavigationService nav;
  late RegisterViewModel viewModel;

  const fakeUser = User(
    id: 'uuid-1',
    email: 'alice@studup.fr',
    firstName: 'Alice',
    lastName: 'Martin',
    role: UserRole.ALTERNANT,
    isVerified: false,
  );

  setUpAll(() {
    // mocktail exige une valeur de repli pour utiliser any() sur un
    // type non primitif comme UserRole
    registerFallbackValue(UserRole.ALTERNANT);
  });

  setUp(() {
    auth = MockAuthService();
    nav = MockNavigationService();
    viewModel = RegisterViewModel(authService: auth, navigationService: nav);
  });

  void fillValidForm() {
    viewModel.firstNameController.text = 'Alice';
    viewModel.lastNameController.text = 'Martin';
    viewModel.emailController.text = 'alice@studup.fr';
    viewModel.passwordController.text = 'motdepasse123';
  }

  group('RegisterViewModel.register', () {
    test('champ requis manquant : erreur locale, aucun appel réseau',
        () async {
      viewModel.lastNameController.text = 'Martin';
      viewModel.emailController.text = 'alice@studup.fr';
      viewModel.passwordController.text = 'motdepasse123';
      // prénom manquant

      await viewModel.register();

      expect(viewModel.errorMessage, 'Le prénom est requis');
      verifyNever(() => auth.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            role: any(named: 'role'),
          ));
    });

    test('succès : emailSent passe à true, le rôle sélectionné est envoyé',
        () async {
      fillValidForm();
      viewModel.selectRole(UserRole.PROPRIETAIRE);

      when(() => auth.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => fakeUser);

      await viewModel.register();

      expect(viewModel.emailSent, isTrue);
      expect(viewModel.errorMessage, isNull);
      verify(() => auth.register(
            email: 'alice@studup.fr',
            password: 'motdepasse123',
            firstName: 'Alice',
            lastName: 'Martin',
            role: UserRole.PROPRIETAIRE,
          )).called(1);
    });

    test('409 : message email en doublon, emailSent reste false', () async {
      fillValidForm();

      when(() => auth.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            role: any(named: 'role'),
          )).thenThrow(const ApiException(
        code: 'DUPLICATE_EMAIL',
        message: 'Un compte existe déjà avec cet email',
        statusCode: 409,
      ));

      await viewModel.register();

      expect(viewModel.emailSent, isFalse);
      expect(viewModel.errorMessage, 'Un compte existe déjà avec cet email');
    });

    test('le rôle par défaut est ALTERNANT', () {
      expect(viewModel.selectedRole, UserRole.ALTERNANT);
    });
  });
}
