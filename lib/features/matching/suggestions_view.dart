import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/scenario.dart';
import 'suggestions_viewmodel.dart';
import '../../shared/widgets/match_card.dart';

/// Mes matches — onglet Matches du shell alternant (refonte APP-107).
/// Hiérarchie : économies possibles en sous-titre, tuiles filtrantes,
/// meilleur match mis en avant, autres matchs en cartes compactes.
class SuggestionsView extends StackedView<SuggestionsViewModel> {
  const SuggestionsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    SuggestionsViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header : titre + promesse économique ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, 0),
            child: Text('Mes matches',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: viewModel.economieMax > 0
                ? Text.rich(TextSpan(
                    text: 'Jusqu\'à ',
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: '${viewModel.economieMax} €/mois',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.echange),
                      ),
                      const TextSpan(text: ' d\'économies possibles'),
                    ],
                  ))
                : Text('Trouve ton échange ou ta coloc',
                    style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Tuiles filtrantes (pattern écran Compatibilité) ─
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: viewModel.nbActifs,
                    label: viewModel.nbActifs > 1
                        ? 'prêts à signer'
                        : 'prêt à signer',
                    color: AppColors.echange,
                    background: AppColors.echangeLight,
                    selected: viewModel.filter == SuggestionFilter.actifs,
                    dimmed: viewModel.filter == SuggestionFilter.potentiels,
                    onTap: () =>
                        viewModel.setFilter(SuggestionFilter.actifs),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    value: viewModel.nbPotentiels,
                    label: viewModel.nbPotentiels > 1
                        ? 'potentiels'
                        : 'potentiel',
                    color: AppColors.textSecondary,
                    background: AppColors.surfaceDark,
                    selected:
                        viewModel.filter == SuggestionFilter.potentiels,
                    dimmed: viewModel.filter == SuggestionFilter.actifs,
                    onTap: () =>
                        viewModel.setFilter(SuggestionFilter.potentiels),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Liste ──────────────────────────────────────────
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, SuggestionsViewModel viewModel) {
    // Skeleton loader : silhouettes de cartes au lieu d'un spinner
    if (viewModel.isBusy && viewModel.suggestions.isEmpty) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: const [
          _SkeletonCard(height: 150),
          _SkeletonCard(height: 72),
          _SkeletonCard(height: 72),
          _SkeletonCard(height: 72),
        ],
      );
    }

    if (viewModel.errorMessage != null && viewModel.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton(
                onPressed: viewModel.load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (viewModel.suggestions.isEmpty) {
      return _EmptyState(viewModel: viewModel);
    }

    final meilleur = viewModel.meilleurMatch;
    final autres = viewModel.autresSuggestions;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ─── Meilleur match : carte complète mise en avant ──
          if (meilleur != null) ...[
            const _SectionLabel('MEILLEUR MATCH'),
            MatchCard(
              suggestion: meilleur,
              onSeeCalendar: () => viewModel.goToCompatibilite(meilleur),
              onContact: () => viewModel.goToChat(meilleur),
              onPublier: viewModel.publierLogement,
              onTap: meilleur.logementBId != null
                  ? () => viewModel.goToLogement(meilleur)
                  : null,
            ),
            if (autres.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const _SectionLabel('AUTRES MATCHS'),
            ],
          ],

          // ─── Autres matchs : cartes compactes ───────────────
          for (final s in autres)
            _CompactMatchCard(
              suggestion: s,
              onTap: () => viewModel.goToCompatibilite(s),
              onContact: () => viewModel.goToChat(s),
              // CTA publier piloté par le scénario principal (APP-109),
              // repli sur l'ancienne règle si le backend n'en envoie pas
              onPublier: !s.isMatchActif &&
                      (s.scenarioPrincipal != null
                          ? s.scenarioPrincipal!.action ==
                              ScenarioAction.publierLogement
                          : s.logementAId == null)
                  ? viewModel.publierLogement
                  : null,
            ),
        ],
      ),
    );
  }

  @override
  SuggestionsViewModel viewModelBuilder(BuildContext context) =>
      SuggestionsViewModel();

  @override
  void onViewModelReady(SuggestionsViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

/// Petit label de section en capitales espacées
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.textTertiary)),
    );
  }
}

/// Tuile chiffrée filtrante — même pattern que l'écran Compatibilité
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color background;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actif = value > 0;
    return InkWell(
      onTap: actif ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      child: AnimatedOpacity(
        opacity: dimmed ? 0.45 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: actif ? background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: actif ? color : AppColors.textTertiary)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: actif ? color : AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte compacte d'un match — le détail complet vit sur l'écran
/// Compatibilité. Trois lignes d'info aérées + contacter (APP-107).
class _CompactMatchCard extends StatelessWidget {
  final MatchingSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback onContact;
  final VoidCallback? onPublier;

  const _CompactMatchCard({
    required this.suggestion,
    required this.onTap,
    required this.onContact,
    this.onPublier,
  });

  @override
  Widget build(BuildContext context) {
    final actif = suggestion.isMatchActif;
    final accent = actif ? AppColors.echange : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      actif ? AppColors.echangeLight : AppColors.surfaceDark,
                  child: Text(suggestion.initials,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.displayName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz,
                              size: 15, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                '${suggestion.villeA} ⇄ ${suggestion.villeB}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Anneau de score — repère visuel fort du match
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        actif ? AppColors.echangeLight : AppColors.surfaceDark,
                  ),
                  child: Text('${suggestion.scorePercent}%',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Statut + type d'arrangement, en pastilles
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _MatchTag(
                  label: actif ? 'Match actif' : 'Match potentiel',
                  color: actif ? AppColors.echange : AppColors.textSecondary,
                  background:
                      actif ? AppColors.echangeLight : AppColors.surfaceDark,
                ),
                _MatchTag(
                  label: suggestion.typePropose.label,
                  color: AppColors.colocation,
                  background: AppColors.colocationLight,
                ),
              ],
            ),

            // Économie mise en valeur (le cœur de la proposition)
            if (suggestion.hasEconomie) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 18, color: AppColors.echange),
                  const SizedBox(width: AppSpacing.sm),
                  // Expanded : sans lui le texte débordait de la carte
                  // (les libellés de coloc sont longs — APP-120)
                  Expanded(
                    child: Text(suggestion.economieLabel,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.echange)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Actions : déblocage des potentiels + contacter
            Row(
              children: [
                if (onPublier != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPublier,
                      icon: const Icon(Icons.add_home_outlined, size: 16),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: AppColors.echange,
                        side: const BorderSide(color: AppColors.echange),
                      ),
                      label: const Text('Publier pour débloquer',
                          style: TextStyle(fontSize: 12)),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Contacter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille (statut du match, type d'arrangement). L'info n'est jamais portée
/// par la seule couleur : le libellé texte l'accompagne toujours (OPQUAST).
class _MatchTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _MatchTag(
      {required this.label, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Silhouette grise pulsante d'une carte en chargement
class _SkeletonCard extends StatefulWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.4,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
    );
  }
}

/// Aucun match : illustration pastille + CTA (style onboarding)
class _EmptyState extends StatelessWidget {
  final SuggestionsViewModel viewModel;

  const _EmptyState({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.echangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz,
                  size: 56, color: AppColors.echange),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun match pour l\'instant',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Les suggestions apparaissent dès qu\'un alternant a une ville '
            'en commun avec toi. Publie ton logement pour être prêt le '
            'moment venu !',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: viewModel.publierLogement,
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('Publier mon logement'),
          ),
        ],
      ),
    );
  }
}
