import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import 'recherche_viewmodel.dart';

/// Recherche de logements — onglet Recherche de l'étudiant.
class RechercheView extends StackedView<RechercheViewModel> {
  const RechercheView({super.key});

  @override
  Widget builder(
    BuildContext context,
    RechercheViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
            child: Text('Rechercher un logement',
                style: Theme.of(context).textTheme.headlineMedium),
          ),

          // ─── Barre de recherche ville ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: TextField(
              controller: viewModel.villeController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => viewModel.search(),
              decoration: InputDecoration(
                hintText: 'Ville (Paris, Lyon…)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: viewModel.search,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Chips de filtres ───────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              children: [
                for (final loyer in RechercheViewModel.loyersMax)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: '≤ ${loyer.toStringAsFixed(0)} €',
                      selected: viewModel.loyerMax == loyer,
                      onTap: () => viewModel.setLoyerMax(loyer),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    label: 'Meublé',
                    selected: viewModel.meubleUniquement,
                    onTap: viewModel.toggleMeuble,
                  ),
                ),
                for (final t in [
                  LogementType.STUDIO,
                  LogementType.T1,
                  LogementType.T2
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: t.label,
                      selected: viewModel.type == t,
                      onTap: () => viewModel.setType(t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Expanded(child: _buildResults(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, RechercheViewModel viewModel) {
    if (viewModel.isBusy && viewModel.resultats.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.resultats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton(
                onPressed: viewModel.search,
                child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (viewModel.resultats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucun logement ne correspond à ta recherche.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    // Infinite scroll : charge la page suivante en approchant du bas
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 300) {
          viewModel.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: viewModel.search,
        color: AppColors.echange,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount:
              viewModel.resultats.length + (viewModel.hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= viewModel.resultats.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(
                      color: AppColors.echange, strokeWidth: 2),
                ),
              );
            }
            final l = viewModel.resultats[index];
            return _ResultCard(
                logement: l, onTap: () => viewModel.goToDetail(l));
          },
        ),
      ),
    );
  }

  @override
  RechercheViewModel viewModelBuilder(BuildContext context) =>
      RechercheViewModel();

  @override
  void onViewModelReady(RechercheViewModel viewModel) => viewModel.search();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Logement logement;
  final VoidCallback onTap;

  const _ResultCard({required this.logement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusCard),
                bottomLeft: Radius.circular(AppSpacing.radiusCard),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: logement.photoUrls.isNotEmpty
                    ? Image.network(logement.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceDark,
                            child: const Icon(Icons.apartment,
                                color: AppColors.textTertiary)))
                    : Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(Icons.apartment,
                            color: AppColors.textTertiary)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${logement.loyer.toStringAsFixed(0)} € / mois',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                        '${logement.type.label} · ${logement.surface.toStringAsFixed(0)} m² · ${logement.ville}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (logement.isMeuble)
                          const _MiniBadge(label: 'Meublé'),
                        if (logement.isVerified)
                          const _MiniBadge(
                              label: 'Vérifié ✓',
                              color: AppColors.echange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge(
      {required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
