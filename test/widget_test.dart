import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/app/app.locator.dart';
import 'package:studup_app/main.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/onboarding_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late MockOnboardingService mockOnboarding;

  setUpAll(() {
    setupLocator();
    // Remplace les services qui lisent le secure storage (indisponible
    // en test widget) par des mocks.
    locator.unregister<AuthService>();
    final mockAuth = MockAuthService();
    when(() => mockAuth.isLoggedIn()).thenAnswer((_) async => false);
    locator.registerSingleton<AuthService>(mockAuth);

    locator.unregister<OnboardingService>();
    mockOnboarding = MockOnboardingService();
    when(() => mockOnboarding.marquerVu()).thenAnswer((_) async {});
    locator.registerSingleton<OnboardingService>(mockOnboarding);
  });

  tearDownAll(() => locator.reset());

  testWidgets('splash affiché puis redirection vers le login',
      (tester) async {
    // Onboarding déjà vu → direction login
    when(() => mockOnboarding.dejaVu()).thenAnswer((_) async => true);

    await tester.pumpWidget(const StudUpApp());

    // 1. Le splash s'affiche
    expect(find.text('StudUp'), findsOneWidget);
    expect(find.text("L'échange de logement pour alternants"), findsOneWidget);

    // 2. Après le délai du splash (800 ms) : redirection vers Login
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('premier lancement : splash puis onboarding (APP-105)',
      (tester) async {
    when(() => mockOnboarding.dejaVu()).thenAnswer((_) async => false);

    await tester.pumpWidget(const StudUpApp());
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Premier écran de l'onboarding : le problème des deux loyers
    expect(find.text('Deux villes.\nDeux loyers.'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });
}
