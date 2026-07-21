import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/logement_card.dart';
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
                  tooltip: 'Lancer la recherche',
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

          // ─── En-tête résultats : compteur + tri + reset (APP-117) ──
          // C'est ce qui distingue la Recherche de l'aperçu de l'accueil :
          // on sait combien il y a de résultats et on peut les ordonner.
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(viewModel.resultatsLabel,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                if (viewModel.hasFiltresActifs)
                  TextButton(
                    onPressed: viewModel.resetFiltres,
                    child: const Text('Réinitialiser'),
                  ),
                // Chip de tri → ouvre une bottom sheet (pattern mobile),
                // pas un menu déroulant (pattern desktop).
                InkWell(
                  onTap: () => _showTriSheet(context, viewModel),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusChip),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(viewModel.triLabel,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

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

  /// Choix du tri en bottom sheet : grandes zones tactiles, coche sur l'option
  /// active, poignée de glissement — le standard mobile (vs menu déroulant).
  Future<void> _showTriSheet(
      BuildContext context, RechercheViewModel viewModel) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée de glissement
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                  AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.sm),
              child: Text('Trier par',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final e in RechercheViewModel.trisDisponibles.entries)
              ListTile(
                title: Text(e.value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: viewModel.tri == e.key
                            ? FontWeight.w600
                            : FontWeight.w400)),
                trailing: viewModel.tri == e.key
                    ? const Icon(Icons.check, color: AppColors.echange)
                    : null,
                onTap: () => Navigator.pop(sheetContext, e.key),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choix != null && choix != viewModel.tri) viewModel.setTri(choix);
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
            return LogementCard(
              logement: l,
              onTap: () => viewModel.goToDetail(l),
              // Badge « Contacté », « Visité »… sur les annonces déjà suivies
              statut: viewModel.statutPour(l.id),
            );
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

// La carte d'annonce vit désormais dans shared/widgets/logement_card.dart
// (LogementCard), partagée avec l'accueil étudiant.
