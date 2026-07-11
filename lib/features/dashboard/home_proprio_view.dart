import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/proprietaire_dashboard.dart';
import 'home_proprio_viewmodel.dart';

/// Dashboard propriétaire — onglet Accueil.
/// [onSeeLogements] bascule sur l'onglet Logements.
class HomeProprioView extends StackedView<HomeProprioViewModel> {
  final VoidCallback? onSeeLogements;

  const HomeProprioView({super.key, this.onSeeLogements});

  @override
  Widget builder(
    BuildContext context,
    HomeProprioViewModel viewModel,
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

  Widget _buildBody(BuildContext context, HomeProprioViewModel viewModel) {
    if (viewModel.isBusy && viewModel.dashboard == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.dashboard == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 120),
          Text(viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
                onPressed: viewModel.load, child: const Text('Réessayer')),
          ),
        ],
      );
    }

    final d = viewModel.dashboard!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('Bonjour 👋',
            style: Theme.of(context).textTheme.headlineMedium),
        Text('Ton parc en un coup d\'œil',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),

        // ─── KPIs ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                value: '${d.tauxOccupation.toStringAsFixed(0)}%',
                label: 'occupation',
                valueColor: d.tauxOccupation >= 50
                    ? AppColors.echange
                    : AppColors.chevauchement,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiCard(
                value: '${d.nbLogementsActifs}/${d.nbLogementsTotaux}',
                label: 'logements actifs',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiCard(
                value: '${d.nbLocatairesActifs}',
                label: d.nbLocatairesActifs > 1
                    ? 'locataires'
                    : 'locataire',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Alertes ────────────────────────────────────────
        if (viewModel.alertes.isNotEmpty) ...[
          Text('Alertes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...viewModel.alertes.map((a) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.chevauchementLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 18, color: AppColors.chevauchement),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(a,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.chevauchement)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Logements ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text('Mes logements',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton(
                onPressed: onSeeLogements, child: const Text('Gérer')),
          ],
        ),
        if (d.logements.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Aucun logement.\nAjoute ton premier bien pour commencer !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...d.logements.map((l) => _LogementLine(logement: l)),
      ],
    );
  }

  @override
  HomeProprioViewModel viewModelBuilder(BuildContext context) =>
      HomeProprioViewModel();

  @override
  void onViewModelReady(HomeProprioViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _KpiCard({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LogementLine extends StatelessWidget {
  final LogementSummary logement;

  const _LogementLine({required this.logement});

  @override
  Widget build(BuildContext context) {
    final (statutColor, statutBg) = switch (logement.statut) {
      LogementStatut.ACTIF => (AppColors.echange, AppColors.echangeLight),
      LogementStatut.SUSPENDU => (
          AppColors.chevauchement,
          AppColors.chevauchementLight
        ),
      _ => (AppColors.textSecondary, AppColors.surfaceDark),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${logement.type.label} · ${logement.ville}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                    '${logement.loyer.toStringAsFixed(0)} € / mois · '
                    '${logement.isOccupe ? "Occupé" : "Vacant"}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statutBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
            ),
            child: Text(logement.statut.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statutColor)),
          ),
        ],
      ),
    );
  }
}
