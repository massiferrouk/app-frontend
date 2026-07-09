import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/app/app.locator.dart';
import 'package:studup_app/main.dart';
import 'package:studup_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  setUpAll(() {
    setupLocator();
    // Remplace le vrai AuthService (qui lit le secure storage, indisponible
    // en test) par un mock : pas de session → redirection vers Login
    locator.unregister<AuthService>();
    final mockAuth = MockAuthService();
    when(() => mockAuth.isLoggedIn()).thenAnswer((_) async => false);
    locator.registerSingleton<AuthService>(mockAuth);
  });

  tearDownAll(() => locator.reset());

  testWidgets('splash affiché puis redirection vers le login',
      (tester) async {
    await tester.pumpWidget(const StudUpApp());

    // 1. Le splash s'affiche
    expect(find.text('StudUp'), findsOneWidget);
    expect(find.text("L'échange de logement pour alternants"), findsOneWidget);

    // 2. Après le délai du splash (800 ms) : redirection vers Login
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
  });
}
