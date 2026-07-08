import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/app/app.locator.dart';
import 'package:studup_app/main.dart';

void main() {
  // Le locator doit être initialisé avant de monter l'app dans les tests
  setUpAll(() => setupLocator());
  tearDownAll(() => locator.reset());

  testWidgets('StartupView affiche le logo StudUp', (tester) async {
    await tester.pumpWidget(const StudUpApp());

    expect(find.text('StudUp'), findsOneWidget);
    expect(find.text("L'échange de logement pour alternants"), findsOneWidget);
  });
}
