import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/logement_apercu.dart';
import '../models/matching_suggestion.dart';
import '../models/scenario.dart';
import 'logement_vignette.dart';
import 'match_status_pill.dart';

/// Carte du meilleur match — version allégée (APP-122).
///
/// Design épuré : une seule couleur d'accent = le statut (pastille + point),
/// le vert réservé à l'économie (le seul argument coloré), le score et les
/// avatars en neutre. Fini l'empilement de pastilles colorées par type.
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
    final actif = suggestion.isMatchActif;
    // Neutre : le score et l'avatar ne portent plus de couleur de type. Ils
    // se distinguent par la taille et le poids, pas par la teinte.
    final neutre = actif ? AppColors.textPrimary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── En-tête : avatar, nom/villes, score ───────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceDark,
                  child: Text(
                    suggestion.initials,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: neutre),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.displayName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      // Rythme de l'autre alternant (APP-122) : « 3 sem. Paris /
                      // 1 sem. Lyon ». Remplace l'ancienne ligne des villes —
                      // elle contient déjà les deux villes, mais en dit plus.
                      Text(
                        suggestion.rythmeLigne,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Score + légende de ce qu'il mesure (APP-122)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${suggestion.scorePercent}%',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: neutre),
                    ),
                    const Text('compatibilité',
                        style: TextStyle(
                            fontSize: 9, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ─── Statut + arrangement (une seule ligne) ────────
            Row(
              children: [
                MatchStatusPill(isActif: actif),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    suggestion.arrangementLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),

            // ─── Économie : le seul repère coloré (APP-103) ────
            if (suggestion.hasEconomie) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 16, color: AppColors.echange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      suggestion.economieLabelCourt,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.echange),
                    ),
                  ),
                ],
              ),
            ],

            // ─── Aperçu du logement de l'autre (APP-122) ───────
            // Vignette + infos. Le tap sur la carte (onTap) ouvre déjà la fiche.
            if (suggestion.logementBApercu != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _ApercuLogementTile(apercu: suggestion.logementBApercu!),
            ],

            // ─── Scénario du moteur, repli message générique ───
            if (!actif && _messagePotentiel != null) ...[
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

            // ─── CTA de déblocage : je publie mon logement ─────
            if (!actif && _peutPublier && onPublier != null) ...[
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

            // ─── Actions : compatibilité (vert) + contacter ────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: onSeeCalendar,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        // Noir neutre : le bouton principal se distingue par son
                        // fond plein, pas par une couleur. Le vert reste réservé
                        // à l'économie (le seul argument coloré) — APP-122.
                        backgroundColor: AppColors.textPrimary),
                    child: const Text('Voir la compatibilité',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
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
    );
  }
}

/// Sous-carte « Son logement à … » sur le meilleur match (APP-122) : vignette
/// + ville + type · loyer. Purement visuelle — l'ouverture de la fiche est
/// portée par le tap sur la carte parente.
class _ApercuLogementTile extends StatelessWidget {
  final LogementApercu apercu;

  const _ApercuLogementTile({required this.apercu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          LogementVignette(photoUrl: apercu.photoUrl, width: 66, height: 50),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Son logement à ${apercu.ville}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_infoLine(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  String _infoLine() {
    final parts = <String>[
      if (apercu.type != null) apercu.type!.label,
      '${apercu.loyer.toStringAsFixed(0)} €/mois',
    ];
    return parts.join(' · ');
  }
}
