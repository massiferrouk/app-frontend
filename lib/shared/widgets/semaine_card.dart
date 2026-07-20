import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/mes_semaines.dart';

/// Style visuel d'une semaine selon le lieu (label 'A' = école, 'B' = entreprise).
/// Partagé par la carte, le bandeau et la heatmap du calendrier (APP-118).
/// L'info n'est jamais portée par la seule couleur (règle OPQUAST) : l'icône
/// et le libellé [tag] accompagnent toujours la couleur.
({Color color, Color light, IconData icon, String tag}) styleSemaineLieu(
        String label) =>
    label == 'A'
        ? (
            color: AppColors.colocation,
            light: AppColors.colocationLight,
            icon: Icons.school_outlined,
            tag: 'École',
          )
        : (
            color: AppColors.echange,
            light: AppColors.echangeLight,
            icon: Icons.work_outline,
            tag: 'Entreprise',
          );

/// Carte d'une semaine du calendrier personnel.
/// Anatomie (cf. design validé) : barre colorée gauche (A=foncé, B=gris),
/// numéro de semaine + dates, ville en gras, badge A/B,
/// badge orange "Modifié" si override.
class SemaineCard extends StatelessWidget {
  final AlternanceSemaine semaine;
  final String ville;
  final bool modifiable;

  /// Semaine en cours → bordure pleine pour la repérer d'un œil (APP-118)
  final bool courante;
  final VoidCallback? onTap;

  const SemaineCard({
    super.key,
    required this.semaine,
    required this.ville,
    this.modifiable = false,
    this.courante = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = styleSemaineLieu(semaine.label);
    final barColor = style.color;
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
          border: Border.all(
              color: courante ? AppColors.textPrimary : AppColors.border,
              width: courante ? 2 : 1),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              // Pastille lieu : icône + « École » / « Entreprise »
              // (le sens ne dépend jamais de la seule couleur — OPQUAST)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: style.light,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 14, color: style.color),
                    const SizedBox(width: 4),
                    Text(style.tag,
                        style: TextStyle(
                            color: style.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
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
