import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/enums.dart';
import '../models/matching_suggestion.dart';

/// Carte d'un match — 4 variantes selon le type :
/// ÉCHANGE TOTAL (bordure verte), ÉCHANGE PARTIEL (orange),
/// COLOCATION TOURNANTE (bleue), MATCH POTENTIEL (grise pointillée).
class MatchCard extends StatelessWidget {
  final MatchingSuggestion suggestion;
  final VoidCallback? onSeeCalendar;
  final VoidCallback? onContact;

  /// Tap sur toute la carte → détail du logement de l'autre alternant.
  /// null si aucun logement à afficher (match potentiel).
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.suggestion,
    this.onSeeCalendar,
    this.onContact,
    this.onTap,
  });

  /// Couleur d'accent selon le type d'accord proposé
  Color get _accentColor => switch (suggestion.typePropose) {
        AccordType.ECHANGE_TOTAL => AppColors.echange,
        AccordType.ECHANGE_PARTIEL => AppColors.chevauchement,
        AccordType.COLOCATION_TOURNANTE => AppColors.colocation,
        _ => AppColors.textTertiary,
      };

  Color get _accentLight => switch (suggestion.typePropose) {
        AccordType.ECHANGE_TOTAL => AppColors.echangeLight,
        AccordType.ECHANGE_PARTIEL => AppColors.chevauchementLight,
        AccordType.COLOCATION_TOURNANTE => AppColors.colocationLight,
        _ => AppColors.surface,
      };

  @override
  Widget build(BuildContext context) {
    final isPotentiel = !suggestion.isMatchActif;
    final accent = isPotentiel ? AppColors.textTertiary : _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bordure colorée gauche — le code visuel du type de match
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusCard),
                  bottomLeft: Radius.circular(AppSpacing.radiusCard),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar initiales
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              isPotentiel ? AppColors.surface : _accentLight,
                          child: Text(
                            suggestion.initials,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(suggestion.displayName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${suggestion.villeA} ⇄ ${suggestion.villeB}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Score en %
                        Text(
                          '${suggestion.scorePercent}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Badge type + badge actif/potentiel
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Chip(
                          label: suggestion.typePropose.label,
                          color: accent,
                          background: isPotentiel
                              ? AppColors.surface
                              : _accentLight,
                        ),
                        if (isPotentiel)
                          const _Chip(
                            label: 'Match potentiel',
                            color: AppColors.textSecondary,
                            background: AppColors.surfaceDark,
                          )
                        else
                          const _Chip(
                            label: 'Match actif',
                            color: AppColors.echange,
                            background: AppColors.echangeLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Résumé des semaines
                    Text(
                      _resumeSemaines(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    // Argument massue : l'économie estimée en euros (APP-103)
                    if (suggestion.hasEconomie) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.savings_outlined,
                              size: 15, color: AppColors.echange),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              suggestion.economieLabel,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.echange),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Message match potentiel ("Si tu publies un logement...")
                    if (isPotentiel &&
                        suggestion.messageMatchPotentiel != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          suggestion.messageMatchPotentiel!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSeeCalendar,
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40)),
                            child: const Text('Voir calendrier',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onContact,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                backgroundColor: isPotentiel
                                    ? AppColors.textPrimary
                                    : accent),
                            child: const Text('Contacter',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _resumeSemaines() {
    final parts = <String>[];
    if (suggestion.nbSemainesEchange > 0) {
      parts.add('${suggestion.nbSemainesEchange} sem. échange');
    }
    if (suggestion.nbSemainesColocation > 0) {
      parts.add('${suggestion.nbSemainesColocation} sem. coloc');
    }
    if (suggestion.nbSemainesChevauchement > 0) {
      parts.add('${suggestion.nbSemainesChevauchement} sem. chevauchement');
    }
    return parts.isEmpty ? 'Aucune semaine commune' : parts.join(' · ');
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
