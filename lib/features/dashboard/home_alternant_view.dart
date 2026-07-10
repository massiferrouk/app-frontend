import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/accord_summary.dart';
import 'home_alternant_viewmodel.dart';

/// Dashboard alternant — onglet Accueil du shell.
/// [onSeeMatches] permet de basculer sur l'onglet Matches du shell.
class HomeAlternantView extends StackedView<HomeAlternantViewModel> {
  final VoidCallback? onSeeMatches;

  const HomeAlternantView({super.key, this.onSeeMatches});

  @override
  Widget builder(
    BuildContext context,
    HomeAlternantViewModel viewModel,
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

  Widget _buildBody(BuildContext context, HomeAlternantViewModel viewModel) {
    if (viewModel.isBusy && viewModel.dashboard == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.dashboard == null) {
      return _ErrorState(
          message: viewModel.errorMessage!, onRetry: viewModel.load);
    }

    final dash = viewModel.dashboard!;
    final prochain =
        dash.prochainAccords.isNotEmpty ? dash.prochainAccords.first : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('Bonjour 👋',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Voici où tu en es',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),

        // ─── KPIs ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${dash.economiesEstimees.toStringAsFixed(0)} €',
                label: 'économisés',
                valueColor: AppColors.echange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                value: '${dash.nbAccordsTermines}',
                label: dash.nbAccordsTermines > 1
                    ? 'échanges terminés'
                    : 'échange terminé',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Prochain échange ───────────────────────────────────
        Text('Prochain échange',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (prochain != null)
          _AccordTile(accord: prochain)
        else
          const _EmptyCard(
              text: 'Aucun échange programmé.\nTrouve ton prochain match !'),
        const SizedBox(height: AppSpacing.lg),

        // ─── Accords en attente ─────────────────────────────────
        if (dash.accordsEnAttente.isNotEmpty) ...[
          Text('En attente de réponse',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...dash.accordsEnAttente.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AccordTile(accord: a, showCountdown: true),
              )),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── Actions rapides ────────────────────────────────────
        ElevatedButton.icon(
          onPressed: onSeeMatches,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Voir mes matches'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: viewModel.goToCalendrier,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Mon calendrier d\'alternance'),
        ),
      ],
    );
  }

  @override
  HomeAlternantViewModel viewModelBuilder(BuildContext context) =>
      HomeAlternantViewModel();

  @override
  void onViewModelReady(HomeAlternantViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AccordTile extends StatelessWidget {
  final AccordSummary accord;
  final bool showCountdown;

  const _AccordTile({required this.accord, this.showCountdown = false});

  @override
  Widget build(BuildContext context) {
    final dates = '${DateFormat('dd/MM').format(accord.dateDebut)} → '
        '${DateFormat('dd/MM/yyyy').format(accord.dateFin)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.echangeLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: AppColors.echange),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(accord.type.label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(dates, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (showCountdown && accord.heuresAvantExpiration != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.chevauchementLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              ),
              child: Text(
                '${accord.heuresAvantExpiration}h restantes',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chevauchement),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_outlined,
            size: 48, color: AppColors.textTertiary),
        const SizedBox(height: AppSpacing.md),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
              onPressed: onRetry, child: const Text('Réessayer')),
        ),
      ],
    );
  }
}
