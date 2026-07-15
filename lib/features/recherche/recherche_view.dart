import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import 'recherche_viewmodel.dart';

/// Recherche de logements.
/// Onglet Recherche de l'étudiant, ou écran empilé ([standalone] = true,
/// avec AppBar) pour les autres rôles (ex: alternant qui cherche une
/// location classique en plus du matching).
class RechercheView extends StackedView<RechercheViewModel> {
  final bool standalone;

  /// Bascule sur l'onglet Matches (carte matching, APP-104).
  /// null = pas de carte (étudiants, écran empilé sans shell).
  final VoidCallback? onSeeMatches;

  const RechercheView({super.key, this.standalone = false, this.onSeeMatches});

  @override
  Widget builder(
    BuildContext context,
    RechercheViewModel viewModel,
    Widget? child,
  ) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre interne masqué en mode standalone (l'AppBar le porte déjà)
          if (!standalone)
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

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rechercher un logement')),
      body: content,
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

    // Carte matching éventuelle, en tête de liste (APP-104)
    final promo = _matchingPromo(viewModel);

    if (viewModel.resultats.isEmpty) {
      // Liste vide mais rafraîchissable : un ListView (scrollable) permet le
      // pull-to-refresh même sans résultat (tirer vers le bas pour réessayer).
      // La carte matching reste affichée : "aucune annonce mais 3 alternants
      // compatibles" est exactement le message différenciant de StudUp.
      return RefreshIndicator(
        onRefresh: viewModel.search,
        color: AppColors.echange,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            ?promo,
            const SizedBox(height: 60),
            const Icon(Icons.search_off,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucun logement ne correspond à ta recherche.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Tire vers le bas pour rafraîchir.',
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
          // +1 pour la carte matching en tête si présente
          itemCount: (promo != null ? 1 : 0) +
              viewModel.resultats.length +
              (viewModel.hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (promo != null && index == 0) return promo;
            final i = promo != null ? index - 1 : index;
            if (i >= viewModel.resultats.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(
                      color: AppColors.echange, strokeWidth: 2),
                ),
              );
            }
            final l = viewModel.resultats[i];
            return _ResultCard(
                logement: l, onTap: () => viewModel.goToDetail(l));
          },
        ),
      ),
    );
  }

  /// Carte "X alternants compatibles cherchent aussi à {ville}" — le pont
  /// entre la recherche classique et le matching (APP-104).
  /// null si rien à promouvoir (pas alternant, pas de matchs, pas de shell).
  Widget? _matchingPromo(RechercheViewModel viewModel) {
    if (viewModel.matchsCompatibles == 0 || onSeeMatches == null) return null;
    return _MatchingPromoCard(
      nbMatchs: viewModel.matchsCompatibles,
      ville: viewModel.villeMatchs,
      economieMax: viewModel.economieMaxMatchs,
      onTap: onSeeMatches!,
    );
  }

  @override
  RechercheViewModel viewModelBuilder(BuildContext context) =>
      RechercheViewModel();

  @override
  void onViewModelReady(RechercheViewModel viewModel) => viewModel.search();
}

/// Carte promo matching injectée dans les résultats de recherche
class _MatchingPromoCard extends StatelessWidget {
  final int nbMatchs;
  final String ville;
  final int economieMax;
  final VoidCallback onTap;

  const _MatchingPromoCard({
    required this.nbMatchs,
    required this.ville,
    required this.economieMax,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pluriel = nbMatchs > 1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.echangeLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.echange),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, color: AppColors.echange, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nbMatchs alternant${pluriel ? 's' : ''} compatible'
                    '${pluriel ? 's' : ''} avec ton rythme '
                    '${pluriel ? 'cherchent' : 'cherche'} aussi à $ville',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    economieMax > 0
                        ? 'Économise jusqu\'à ≈ $economieMax €/mois '
                            'avec un échange'
                        : 'Découvre l\'échange de logements entre alternants',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.echange),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.echange),
          ],
        ),
      ),
    );
  }
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
