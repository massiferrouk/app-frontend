import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import 'accueil_admin_viewmodel.dart';

/// Accueil administrateur — l'état de la plateforme en un écran (APP-121).
class AccueilAdminView extends StackedView<AccueilAdminViewModel> {
  /// Bascule sur l'onglet Modération depuis la carte des signalements.
  final VoidCallback? onSeeModeration;

  const AccueilAdminView({super.key, this.onSeeModeration});

  @override
  Widget builder(
    BuildContext context,
    AccueilAdminViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, AccueilAdminViewModel viewModel) {
    if (viewModel.isBusy && viewModel.dashboard == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.errorMessage ?? 'Chiffres indisponibles',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton(
                onPressed: viewModel.load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final d = viewModel.dashboard!;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text('Administration',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),

          // ─── Ce qui demande une action, en premier ────────
          if (viewModel.aDesSignalements) ...[
            _AlerteCard(
              nb: viewModel.totalSignalements,
              onTap: onSeeModeration,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─── Comptes ──────────────────────────────────────
          _Section(titre: 'Comptes', total: d.totalComptes),
          const SizedBox(height: AppSpacing.sm),
          _Repartition(
            entrees: [
              for (final role in UserRole.values)
                if (role != UserRole.ADMIN)
                  (role.label, d.comptesParRole[role] ?? 0),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  valeur: '${d.comptesSuspendus}',
                  libelle: 'suspendus',
                  couleur: AppColors.chevauchement,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tuile(
                  valeur: '${d.comptesBannis}',
                  libelle: 'bannis',
                  couleur: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  valeur: '${d.inscriptions7Jours}',
                  libelle: 'inscrits · 7 jours',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tuile(
                  valeur: '${d.inscriptions30Jours}',
                  libelle: 'inscrits · 30 jours',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Annonces ─────────────────────────────────────
          _Section(titre: 'Annonces', total: d.totalAnnonces),
          const SizedBox(height: AppSpacing.sm),
          _Repartition(
            entrees: [
              for (final statut in LogementStatut.values)
                (statut.label, d.annoncesParStatut[statut] ?? 0),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Modération ───────────────────────────────────
          _Section(titre: 'Modération'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  valeur: '${d.signalementsEnAttente}',
                  libelle: 'messages signalés',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tuile(
                  valeur: '${d.annoncesSignalees}',
                  libelle: 'annonces signalées',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  valeur: '${d.motsInterdits}',
                  libelle: 'mots filtrés',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  @override
  AccueilAdminViewModel viewModelBuilder(BuildContext context) =>
      AccueilAdminViewModel();

  @override
  void onViewModelReady(AccueilAdminViewModel viewModel) => viewModel.load();
}

// ─── Composants ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String titre;
  final int? total;

  const _Section({required this.titre, this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (total != null)
          Text('$total au total',
              style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Répartition en barres proportionnelles.
/// Le nombre est toujours écrit à côté du libellé : la barre est une aide
/// visuelle, jamais le seul porteur de l'information.
class _Repartition extends StatelessWidget {
  final List<(String, int)> entrees;

  const _Repartition({required this.entrees});

  @override
  Widget build(BuildContext context) {
    final max = entrees.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (libelle, valeur) in entrees) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(libelle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // Aucune donnée : barres vides plutôt qu'une division
                        // par zéro
                        value: max == 0 ? 0 : valeur / max,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceDark,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 32,
                    child: Text('$valeur',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  final String valeur;
  final String libelle;
  final Color? couleur;

  const _Tuile({required this.valeur, required this.libelle, this.couleur});

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
          Text(valeur,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: couleur ?? AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(libelle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Mise en avant des signalements en attente — la seule chose de cet écran
/// qui appelle une action immédiate.
class _AlerteCard extends StatelessWidget {
  final int nb;
  final VoidCallback? onTap;

  const _AlerteCard({required this.nb, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                nb == 1
                    ? '1 signalement attend une décision'
                    : '$nb signalements attendent une décision',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
