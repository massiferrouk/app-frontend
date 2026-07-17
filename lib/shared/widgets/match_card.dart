import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/enums.dart';
import '../models/matching_suggestion.dart';
import '../models/scenario.dart';

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

  /// CTA « Publier mon logement » des matchs potentiels (APP-106).
  /// Affiché uniquement quand c'est MON logement qui manque.
  final VoidCallback? onPublier;

  const MatchCard({
    super.key,
    required this.suggestion,
    this.onSeeCalendar,
    this.onContact,
    this.onTap,
    this.onPublier,
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

  /// Message affiché sur un match potentiel : le scénario principal du
  /// moteur (APP-109), sinon l'ancien message générique du backend.
  String? get _messagePotentiel =>
      suggestion.scenarioPrincipal?.message ??
      suggestion.messageMatchPotentiel;

  /// Le CTA « Publier » ne s'affiche que si le scénario le propose —
  /// repli sur l'ancienne règle (mon logement manque) sans scénarios.
  bool get _peutPublier => suggestion.scenarioPrincipal != null
      ? suggestion.scenarioPrincipal!.action == ScenarioAction.publierLogement
      : suggestion.logementAId == null;

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

                    // Scénario principal du moteur (APP-109), avec repli sur
                    // l'ancien message générique si le backend n'en envoie pas
                    if (isPotentiel && _messagePotentiel != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _messagePotentiel!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],

                    // CTA de déblocage : uniquement quand le scénario dit
                    // que JE peux agir en publiant (APP-106 / APP-109)
                    if (isPotentiel && _peutPublier && onPublier != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onPublier,
                        icon: const Icon(Icons.add_home_outlined, size: 18),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          foregroundColor: AppColors.echange,
                          side: const BorderSide(color: AppColors.echange),
                        ),
                        label: const Text(
                            'Publier mon logement pour débloquer ce match',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        // Action principale : la compatibilité est le cœur
                        // du parcours — contacter vient après l'avoir vue
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: onSeeCalendar,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: isPotentiel
                                    ? AppColors.textPrimary
                                    : accent),
                            child: const Text('Voir la compatibilité',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: onContact,
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 16),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            label: const Text('Contacter',
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
