import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/logement_card.dart';
import 'home_etudiant_viewmodel.dart';

/// Dashboard étudiant — onglet Accueil.
/// [onSearch] bascule sur l'onglet Recherche, [onAccords] sur Accords.
class HomeEtudiantView extends StackedView<HomeEtudiantViewModel> {
  final VoidCallback? onSearch;
  final VoidCallback? onAccords;

  const HomeEtudiantView({super.key, this.onSearch, this.onAccords});

  @override
  Widget builder(
    BuildContext context,
    HomeEtudiantViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: viewModel.load,
        color: AppColors.echange,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeEtudiantViewModel viewModel) {
    if (viewModel.isBusy && viewModel.vedettes.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Bonjour 👋',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            Badge(
              label: Text('${viewModel.unreadCount}'),
              isLabelVisible: viewModel.unreadCount > 0,
              backgroundColor: AppColors.error,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: viewModel.goToNotifications,
                icon: const Icon(Icons.notifications_outlined, size: 26),
              ),
            ),
          ],
        ),
        Text('Trouve ton prochain logement',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),

        // ─── Fausse barre de recherche → onglet Recherche ────
        GestureDetector(
          onTap: onSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 20, color: AppColors.textTertiary),
                SizedBox(width: AppSpacing.sm),
                Text('Dans quelle ville cherches-tu ?',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Carte de bienvenue (APP-117) : compte neuf/inactif ───
        // Une seule carte avec un CTA clair, plutôt qu'une check-list scolaire.
        if (viewModel.isNouveau) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.echangeLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_outlined,
                    size: 28, color: AppColors.echange),
                const SizedBox(height: AppSpacing.sm),
                Text('Trouve ton logement étudiant',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                    'Parcours les annonces et contacte directement '
                    'les propriétaires.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── Accords en cours ────────────────────────────────
        if (viewModel.accordsEnCours.isNotEmpty) ...[
          Text('Mes accords en cours',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...viewModel.accordsEnCours.take(2).map((a) => GestureDetector(
                onTap: onAccords,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.echangeLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined,
                          color: AppColors.echange),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.type.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${a.statut.label} · '
                              '${DateFormat('dd/MM').format(a.dateDebut)} → '
                              '${DateFormat('dd/MM/yyyy').format(a.dateFin)}',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textTertiary),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── Aperçu des annonces (APP-117) ───────────────────
        // L'accueil ne montre qu'un aperçu (3 annonces) : l'écran Recherche
        // est l'outil complet (filtres, tri, scroll infini). D'où « Voir tout ».
        Row(
          children: [
            Expanded(
              child: Text('Dernières annonces',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton(
              onPressed: onSearch,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (viewModel.vedettes.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  viewModel.errorMessage ??
                      'Aucun logement publié pour l\'instant.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher un logement'),
                ),
              ],
            ),
          )
        else
          ...viewModel.vedettes.map((l) => LogementCard(
                logement: l,
                onTap: () => viewModel.goToDetail(l),
                // Même badge de suivi que sur la Recherche (APP-119)
                statut: viewModel.statutPour(l.id),
              )),
      ],
    );
  }

  @override
  HomeEtudiantViewModel viewModelBuilder(BuildContext context) =>
      HomeEtudiantViewModel();

  @override
  void onViewModelReady(HomeEtudiantViewModel viewModel) => viewModel.load();
}

// La carte d'annonce vit dans shared/widgets/logement_card.dart (LogementCard),
// partagée avec l'écran Recherche.
