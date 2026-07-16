import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'suggestions_viewmodel.dart';
import '../../shared/widgets/match_card.dart';

/// Mes matches — onglet Matches du shell alternant.
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.sm),
            child: Text('Mes matches',
                style: Theme.of(context).textTheme.headlineMedium),
          ),

          // ─── Filtres ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: viewModel.filter == SuggestionFilter.tous,
                  onTap: () => viewModel.setFilter(SuggestionFilter.tous),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Actifs (${viewModel.nbActifs})',
                  selected: viewModel.filter == SuggestionFilter.actifs,
                  onTap: () => viewModel.setFilter(SuggestionFilter.actifs),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Potentiels (${viewModel.nbPotentiels})',
                  selected:
                      viewModel.filter == SuggestionFilter.potentiels,
                  onTap: () =>
                      viewModel.setFilter(SuggestionFilter.potentiels),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Liste ──────────────────────────────────────────
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, SuggestionsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.suggestions.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
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

    final suggestions = viewModel.suggestions;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: suggestions.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.search_off,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun match pour l\'instant.\n'
                  'Les suggestions apparaissent dès qu\'un alternant '
                  'a une ville en commun avec toi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return MatchCard(
                  suggestion: s,
                  onSeeCalendar: () => viewModel.goToCompatibilite(s),
                  onContact: () => viewModel.goToChat(s),
                  // CTA de déblocage des matchs potentiels (APP-106)
                  onPublier: viewModel.publierLogement,
                  // Tap sur la carte → détail du logement de l'autre alternant
                  // (seulement s'il en a publié un).
                  onTap: s.logementBId != null
                      ? () => viewModel.goToLogement(s)
                      : null,
                );
              },
            ),
    );
  }

  @override
  SuggestionsViewModel viewModelBuilder(BuildContext context) =>
      SuggestionsViewModel();

  @override
  void onViewModelReady(SuggestionsViewModel viewModel) => viewModel.load();
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
