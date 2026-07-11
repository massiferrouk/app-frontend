import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';
import 'accord_detail_viewmodel.dart';
import 'mes_accords_view.dart' show AccordCardColors;

/// Détail complet d'un accord : type, statut, parties, dates,
/// conditions, actions selon le rôle.
class AccordDetailView extends StackedView<AccordDetailViewModel> {
  final Accord accord;

  const AccordDetailView({super.key, required this.accord});

  @override
  Widget builder(
    BuildContext context,
    AccordDetailViewModel viewModel,
    Widget? child,
  ) {
    final a = viewModel.accord;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail de l\'accord')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // ─── Type + statut ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(a.type.label,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                _StatutBadge(statut: a.statut),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              viewModel.jeSuisInitiateur
                  ? 'Demande envoyée par toi'
                  : 'Demande reçue',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Période ────────────────────────────────────
            _Section(
              title: 'Période',
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(a.dateDebut)}  →  '
                    '${DateFormat('dd/MM/yyyy').format(a.dateFin)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ─── Loyer (locations classiques uniquement) ────
            if (a.montantLoyer != null)
              _Section(
                title: 'Loyer',
                child: Text('${a.montantLoyer!.toStringAsFixed(0)} € / mois',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              )
            else
              _Section(
                title: 'Loyer',
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism_outlined,
                        size: 18, color: AppColors.echange),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Échange gratuit — aucun loyer entre vous',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.echange)),
                  ],
                ),
              ),

            // ─── Message initial ────────────────────────────
            if (a.messageInitial != null && a.messageInitial!.isNotEmpty)
              _Section(
                title: 'Message',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(a.messageInitial!,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic)),
                ),
              ),

            // ─── Countdown ──────────────────────────────────
            if (a.heuresAvantExpiration != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AccordCardColors.attenteBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_bottom,
                        size: 18, color: AccordCardColors.attente),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Sans réponse, cette demande expire dans '
                        '${a.heuresAvantExpiration}h.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AccordCardColors.attente),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // ─── Actions ────────────────────────────────────
            if (viewModel.canAcceptOrRefuse) ...[
              ElevatedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _confirm(context, 'Accepter cet accord ?',
                        viewModel.accept),
                child: const Text('Accepter'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _confirm(context, 'Refuser cet accord ?',
                        viewModel.refuse),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error),
                child: const Text('Refuser'),
              ),
            ] else if (viewModel.canCancel)
              OutlinedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _confirm(context, 'Annuler ta demande ?',
                        viewModel.cancel),
                child: const Text('Annuler ma demande'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, String question,
      Future<String?> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question),
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
    if (confirmed != true) return;

    final error = await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'C\'est fait ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  AccordDetailViewModel viewModelBuilder(BuildContext context) =>
      AccordDetailViewModel(accord: accord);

  @override
  void onViewModelReady(AccordDetailViewModel viewModel) => viewModel.init();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final AccordStatut statut;

  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (statut) {
      AccordStatut.EN_ATTENTE => (
          AccordCardColors.attente,
          AccordCardColors.attenteBg
        ),
      AccordStatut.ACCEPTE ||
      AccordStatut.EN_COURS =>
        (AppColors.echange, AppColors.echangeLight),
      AccordStatut.REFUSE ||
      AccordStatut.ANNULE ||
      AccordStatut.LITIGE =>
        (AppColors.error, AppColors.errorLight),
      AccordStatut.TERMINE => (AppColors.textSecondary, AppColors.surfaceDark),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(statut.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
