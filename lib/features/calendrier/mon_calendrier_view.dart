import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/mes_semaines.dart';
import '../../shared/widgets/semaine_card.dart';
import 'mon_calendrier_viewmodel.dart';

/// Mon calendrier d'alternance — liste verticale de semaines groupées
/// par mois, avec résumé du rythme et override par tap sur une semaine.
class MonCalendrierView extends StackedView<MonCalendrierViewModel> {
  const MonCalendrierView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MonCalendrierViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon calendrier')),
      body: SafeArea(child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, MonCalendrierViewModel viewModel) {
    if (viewModel.isBusy && viewModel.data == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.data == null) {
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

    final data = viewModel.data!;
    final groupes = viewModel.semainesParMois;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _RythmeSummary(data: data),
          const SizedBox(height: AppSpacing.lg),
          for (final entry in groupes.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            ...entry.value.map((s) => SemaineCard(
                  semaine: s,
                  ville: data.villeFor(s.label),
                  modifiable: viewModel.isModifiable(s),
                  onTap: () => _showOverrideSheet(context, viewModel, s),
                )),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  /// Bottom sheet de modification d'une semaine (label + raison)
  Future<void> _showOverrideSheet(
    BuildContext context,
    MonCalendrierViewModel viewModel,
    AlternanceSemaine semaine,
  ) async {
    final result = await showModalBottomSheet<({String label, String reason})>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OverrideSheet(
        semaine: semaine,
        villeA: viewModel.data!.villeA,
        villeB: viewModel.data!.villeB,
      ),
    );

    if (result == null) return;

    final error = await viewModel.override(
      semaine: semaine,
      label: result.label,
      reason: result.reason,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Semaine modifiée ✓'),
        backgroundColor:
            error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  MonCalendrierViewModel viewModelBuilder(BuildContext context) =>
      MonCalendrierViewModel();

  @override
  void onViewModelReady(MonCalendrierViewModel viewModel) => viewModel.load();
}

// ─── Résumé du rythme en tête d'écran ─────────────────────────────

class _RythmeSummary extends StatelessWidget {
  final MesSemaines data;

  const _RythmeSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final partA = data.partVilleA;
    final pctA = (partA * 100).round();

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
          Text('Rythme ${data.rythme.label}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          // Barre bicolore : proportion villeA (foncé) / villeB (gris)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: pctA,
                  child: Container(height: 8, color: AppColors.villeA),
                ),
                Expanded(
                  flex: 100 - pctA,
                  child: Container(height: 8, color: AppColors.villeB),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${data.villeA} $pctA% · ${data.villeB} ${100 - pctA}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet d'override ──────────────────────────────────────

class _OverrideSheet extends StatefulWidget {
  final AlternanceSemaine semaine;
  final String villeA;
  final String villeB;

  const _OverrideSheet({
    required this.semaine,
    required this.villeA,
    required this.villeB,
  });

  @override
  State<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends State<_OverrideSheet> {
  late String _label = widget.semaine.label;
  String _reason = 'conges';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modifier cette semaine',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),

          // Choix de la ville (label A/B)
          Row(
            children: [
              _labelChip('A', widget.villeA),
              const SizedBox(width: AppSpacing.sm),
              _labelChip('B', widget.villeB),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Raison de la modification
          DropdownButtonFormField<String>(
            initialValue: _reason,
            items: const [
              DropdownMenuItem(value: 'conges', child: Text('Congés')),
              DropdownMenuItem(
                  value: 'rattrapage', child: Text('Rattrapage')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _reason = v ?? 'autre'),
          ),
          const SizedBox(height: AppSpacing.lg),

          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, (label: _label, reason: _reason)),
            child: const Text('Confirmer'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _labelChip(String label, String ville) {
    final selected = _label == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _label = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
                color:
                    selected ? AppColors.textPrimary : AppColors.border),
          ),
          child: Text(
            '$label — $ville',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
