import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/logement.dart';
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
        Text('Bonjour 👋',
            style: Theme.of(context).textTheme.headlineMedium),
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

        // ─── Logements en vedette ────────────────────────────
        Text('Derniers logements publiés',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (viewModel.vedettes.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              viewModel.errorMessage ??
                  'Aucun logement publié pour l\'instant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...viewModel.vedettes.map((l) => _VedetteCard(
              logement: l, onTap: () => viewModel.goToDetail(l))),
      ],
    );
  }

  @override
  HomeEtudiantViewModel viewModelBuilder(BuildContext context) =>
      HomeEtudiantViewModel();

  @override
  void onViewModelReady(HomeEtudiantViewModel viewModel) => viewModel.load();
}

class _VedetteCard extends StatelessWidget {
  final Logement logement;
  final VoidCallback onTap;

  const _VedetteCard({required this.logement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: logement.photoUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(logement.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.apartment,
                              color: AppColors.textTertiary)))
                  : const Icon(Icons.apartment,
                      color: AppColors.textTertiary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${logement.type.label} · ${logement.ville}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                      '${logement.loyer.toStringAsFixed(0)} € / mois · ${logement.surface.toStringAsFixed(0)} m²',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
