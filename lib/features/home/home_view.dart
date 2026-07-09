import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Écran d'accueil PROVISOIRE — point d'atterrissage après connexion.
/// Sera remplacé par les vrais dashboards (APP-65/APP-66).
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.echange),
            const SizedBox(height: 16),
            Text(
              'Connecté !',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dashboard à venir (APP-66)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
