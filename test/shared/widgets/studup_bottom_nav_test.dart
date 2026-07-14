import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/widgets/studup_bottom_nav.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(bottomNavigationBar: child));

  group('StudUpBottomNav — un onglet par rôle', () {
    testWidgets('alternant : Accueil, Matches, Recherche, Messages, Profil',
        (tester) async {
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.ALTERNANT,
        currentIndex: 0,
        onTap: (_) {},
      )));

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Recherche'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('étudiant : Recherche et Accords à la place de Matches',
        (tester) async {
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.ETUDIANT,
        currentIndex: 0,
        onTap: (_) {},
      )));

      expect(find.text('Recherche'), findsOneWidget);
      expect(find.text('Accords'), findsOneWidget);
      expect(find.text('Matches'), findsNothing);
    });

    testWidgets('propriétaire : Logements et Alertes', (tester) async {
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.PROPRIETAIRE,
        currentIndex: 0,
        onTap: (_) {},
      )));

      expect(find.text('Logements'), findsOneWidget);
      expect(find.text('Alertes'), findsOneWidget);
      expect(find.text('Matches'), findsNothing);
      expect(find.text('Recherche'), findsNothing);
    });

    testWidgets('le tap remonte l\'index sélectionné', (tester) async {
      int? tapped;
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.ALTERNANT,
        currentIndex: 0,
        onTap: (i) => tapped = i,
      )));

      await tester.tap(find.text('Messages'));

      expect(tapped, 3);
    });
  });
}
