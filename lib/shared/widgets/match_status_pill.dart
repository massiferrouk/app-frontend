import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Pastille de statut d'un match : « Actif » (vert) ou « Potentiel » (gris).
///
/// APP-122 — Une seule couleur d'accent par carte = le statut. Un petit point
/// coloré + un mot, plutôt qu'une grosse pastille pleine, pour désencombrer
/// l'écran Matches. L'info n'est jamais portée par la seule couleur : le point
/// est toujours doublé du libellé texte (règle OPQUAST).
class MatchStatusPill extends StatelessWidget {
  final bool isActif;

  const MatchStatusPill({super.key, required this.isActif});

  @override
  Widget build(BuildContext context) {
    final color = isActif ? AppColors.echange : AppColors.textSecondary;
    final background = isActif ? AppColors.echangeLight : AppColors.surfaceDark;
    final dot = isActif ? AppColors.echange : AppColors.villeB;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActif ? 'Actif' : 'Potentiel',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
