import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/core/theme/app_colors.dart';

/// Tests d'accessibilité (APP-112, référentiel OPQUAST).
///
/// Flutter fournit des « guidelines » officielles vérifiables automatiquement :
/// contraste des textes, taille des zones tactiles, présence d'un intitulé sur
/// les éléments actionnables. On les exécute sur un écran représentatif
/// assemblé à partir des composants et couleurs réels de l'app.
///
/// Note : ce test échouait avec l'ancien gris #9E9E9E (ratio ~2.7:1, sous le
/// seuil AA) — il verrouille donc la correction de contraste.
void main() {
  // Écran type : les 3 niveaux de texte du design system sur fond blanc,
  // plus des boutons actionnables avec intitulé.
  Widget harness() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const Text('Titre principal',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            const Text('Texte secondaire',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const Text('Légende',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Créer mon profil'),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('contraste des textes conforme (AA)', (tester) async {
    await tester.pumpWidget(harness());
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('zones tactiles ≥ 48x48 dp (Android)', (tester) async {
    await tester.pumpWidget(harness());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('éléments actionnables tous étiquetés', (tester) async {
    await tester.pumpWidget(harness());
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
