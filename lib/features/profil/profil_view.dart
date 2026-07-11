import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/review.dart';
import 'profil_viewmodel.dart';

/// Mon profil — onglet Profil du shell (tous rôles).
class ProfilView extends StackedView<ProfilViewModel> {
  const ProfilView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ProfilViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(child: _buildBody(context, viewModel));
  }

  Widget _buildBody(BuildContext context, ProfilViewModel viewModel) {
    if (viewModel.isBusy && viewModel.user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.user == null) {
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

    final user = viewModel.user!;
    final rep = viewModel.reputation;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ─── En-tête identité ───────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.echangeLight,
                  child: Text(user.initials,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.echange)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(user.fullName,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Badge(
                        label: user.role.name,
                        color: AppColors.colocation,
                        background: AppColors.colocationLight),
                    if (user.isVerified)
                      const _Badge(
                          label: 'Vérifié ✓',
                          color: AppColors.echange,
                          background: AppColors.echangeLight),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Réputation ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: rep == null
                ? Text(
                    'Pas encore d\'avis — termine ton premier échange !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rep.avgRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                                color: AppColors.chevauchement,
                              ),
                            ),
                          ),
                          Text(
                              '${rep.avgRating.toStringAsFixed(1)}/5 · ${rep.totalReviews} avis',
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      _Badge(
                          label: rep.badge,
                          color: AppColors.echange,
                          background: AppColors.echangeLight),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Mes logements ──────────────────────────────────
          if (viewModel.logements.isNotEmpty) ...[
            Text('Mes logements',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...viewModel.logements.map((l) => _LogementLine(logement: l)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─── Avis reçus ─────────────────────────────────────
          if (viewModel.avisRecus.isNotEmpty) ...[
            Text('Avis reçus',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...viewModel.avisRecus.take(3).map((r) => _AvisLine(review: r)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─── Actions ────────────────────────────────────────
          if (viewModel.isAlternant) ...[
            OutlinedButton.icon(
              onPressed: viewModel.goToCalendrier,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Mon calendrier d\'alternance'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, viewModel),
            style:
                OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, ProfilViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui')),
        ],
      ),
    );
    if (confirmed == true) await viewModel.logout();
  }

  @override
  ProfilViewModel viewModelBuilder(BuildContext context) => ProfilViewModel();

  @override
  void onViewModelReady(ProfilViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Badge(
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

class _LogementLine extends StatelessWidget {
  final Logement logement;

  const _LogementLine({required this.logement});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.apartment_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('${logement.type.label} · ${logement.ville}',
                style: const TextStyle(fontSize: 14)),
          ),
          if (logement.villeAssociee != null)
            _Badge(
                label: logement.villeAssociee!.label,
                color: AppColors.colocation,
                background: AppColors.colocationLight),
        ],
      ),
    );
  }
}

class _AvisLine extends StatelessWidget {
  final Review review;

  const _AvisLine({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: AppColors.chevauchement,
                ),
              ),
              const Spacer(),
              Text(DateFormat('dd/MM/yyyy').format(review.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment!,
                style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
