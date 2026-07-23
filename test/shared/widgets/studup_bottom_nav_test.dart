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

    testWidgets('étudiant : Recherche et Candidatures à la place de Matches',
        (tester) async {
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.ETUDIANT,
        currentIndex: 0,
        onTap: (_) {},
      )));

      expect(find.text('Recherche'), findsOneWidget);
      // APP-117 : Candidatures a remplacé Accords (toujours vide côté étudiant)
      expect(find.text('Candidatures'), findsOneWidget);
      expect(find.text('Accords'), findsNothing);
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

    testWidgets('admin : sa propre nav, plus celle du propriétaire',
        (tester) async {
      await tester.pumpWidget(wrap(StudUpBottomNav(
        role: UserRole.ADMIN,
        currentIndex: 0,
        onTap: (_) {},
      )));

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Comptes'), findsOneWidget);
      expect(find.text('Annonces'), findsOneWidget);
      expect(find.text('Modération'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      // APP-121 : l'admin héritait de la nav propriétaire et atterrissait sur
      // des écrans qui ne le concernent pas.
      expect(find.text('Alertes'), findsNothing);
      expect(find.text('Messages'), findsNothing);
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
