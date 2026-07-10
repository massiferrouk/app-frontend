import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/mes_semaines.dart';

/// Carte d'une semaine du calendrier personnel.
/// Anatomie (cf. design validé) : barre colorée gauche (A=foncé, B=gris),
/// numéro de semaine + dates, ville en gras, badge A/B,
/// badge orange "Modifié" si override.
class SemaineCard extends StatelessWidget {
  final AlternanceSemaine semaine;
  final String ville;
  final bool modifiable;
  final VoidCallback? onTap;

  const SemaineCard({
    super.key,
    required this.semaine,
    required this.ville,
    this.modifiable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isA = semaine.label == 'A';
    final barColor = isA ? AppColors.villeA : AppColors.villeB;
    final finSemaine = semaine.semaine.add(const Duration(days: 6));
    final dates = '${DateFormat('dd/MM').format(semaine.semaine)} — '
        '${DateFormat('dd/MM').format(finSemaine)}';
    final numSemaine = _isoWeekNumber(semaine.semaine);

    return GestureDetector(
      onTap: modifiable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barre colorée gauche : foncé = école, gris = entreprise
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('S$numSemaine',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    Text(dates,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  ville.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (semaine.isOverridden)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chevauchementLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 11,
                          color: AppColors.chevauchement),
                      SizedBox(width: 3),
                      Text('Modifié',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.chevauchement)),
                    ],
                  ),
                ),
              // Badge A/B
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  semaine.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Numéro de semaine ISO-8601 (le backend garantit des lundis)
  static int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    if (woy > 52 && DateTime(date.year, 12, 28).weekday < 4) return 1;
    return woy;
  }
}
