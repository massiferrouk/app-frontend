import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'mes_accords_viewmodel.dart';

/// Mes accords — tabs par statut, actions accepter/refuser/annuler.
///
/// [standalone] = true : écran empilé avec AppBar (accès depuis le Profil).
/// Depuis APP-117, l'étudiant n'a plus d'onglet Accords — les accords formels
/// sont devenus rares (décision « messagerie-first »), on y accède par le Profil.
class MesAccordsView extends StackedView<MesAccordsViewModel> {
  final bool standalone;

  const MesAccordsView({super.key, this.standalone = false});

  @override
  Widget builder(
    BuildContext context,
    MesAccordsViewModel viewModel,
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
              child: Text('Mes accords',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                _TabChip(
                    label: 'En cours',
                    selected: viewModel.tab == AccordTab.enCours,
                    onTap: () => viewModel.setTab(AccordTab.enCours)),
                const SizedBox(width: AppSpacing.sm),
                _TabChip(
                    label: 'Terminés',
                    selected: viewModel.tab == AccordTab.termines,
                    onTap: () => viewModel.setTab(AccordTab.termines)),
                const SizedBox(width: AppSpacing.sm),
                _TabChip(
                    label: 'Tous',
                    selected: viewModel.tab == AccordTab.tous,
                    onTap: () => viewModel.setTab(AccordTab.tous)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes accords')),
      body: content,
    );
  }

  Widget _buildList(BuildContext context, MesAccordsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.accords.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.accords.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: viewModel.accords.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.description_outlined,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun accord dans cette catégorie.\n'
                  'Envoie une demande depuis un match !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: viewModel.accords.length,
              itemBuilder: (context, index) {
                final a = viewModel.accords[index];
                return GestureDetector(
                  onTap: () => viewModel.goToDetail(a),
                  child: _AccordCard(
                  accord: a,
                  canAcceptOrRefuse: viewModel.canAcceptOrRefuse(a),
                  canCancel: viewModel.canCancel(a),
                  onAccept: () => _confirm(context, viewModel,
                      'Accepter cet accord ?', () => viewModel.accept(a)),
                  onRefuse: () => _confirm(context, viewModel,
                      'Refuser cet accord ?', () => viewModel.refuse(a)),
                  onCancel: () => _confirm(context, viewModel,
                      'Annuler ta demande ?', () => viewModel.cancel(a)),
                  onAvis: () => viewModel.goToAvis(a),
                  ),
                );
              },
            ),
    );
  }

  /// Dialog de confirmation avant toute action irréversible
  Future<void> _confirm(
    BuildContext context,
    MesAccordsViewModel viewModel,
    String question,
    Future<String?> Function() action,
  ) async {
    final confirmed = await confirmerAction(
      context,
      titre: question,
      confirmer: 'Oui',
      annuler: 'Non',
    );
    if (!confirmed) return;

    final error = await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'C\'est fait ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  MesAccordsViewModel viewModelBuilder(BuildContext context) =>
      MesAccordsViewModel();

  @override
  void onViewModelReady(MesAccordsViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip(
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

class _AccordCard extends StatelessWidget {
  final Accord accord;
  final bool canAcceptOrRefuse;
  final bool canCancel;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onCancel;
  final VoidCallback onAvis;

  const _AccordCard({
    required this.accord,
    required this.canAcceptOrRefuse,
    required this.canCancel,
    required this.onAccept,
    required this.onRefuse,
    required this.onCancel,
    required this.onAvis,
  });

  (Color, Color) get _statutColors => switch (accord.statut) {
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
        AccordStatut.TERMINE => (
            AppColors.textSecondary,
            AppColors.surfaceDark
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (statutColor, statutBg) = _statutColors;
    final dates = '${DateFormat('dd/MM/yyyy').format(accord.dateDebut)} → '
        '${DateFormat('dd/MM/yyyy').format(accord.dateFin)}';
    final heures = accord.heuresAvantExpiration;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(accord.type.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(accord.statut.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statutColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(dates, style: Theme.of(context).textTheme.bodySmall),
          if (accord.montantLoyer != null)
            Text('${accord.montantLoyer!.toStringAsFixed(0)} € / mois',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),

          // Countdown expiration 72h
          if (heures != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.hourglass_bottom,
                    size: 14, color: AccordCardColors.attente),
                const SizedBox(width: 4),
                Text(
                  heures == 0
                      ? 'Expiration imminente'
                      : 'Expire dans ${heures}h',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AccordCardColors.attente),
                ),
              ],
            ),
          ],

          // ─── Actions selon le rôle dans l'accord ──────────
          if (canAcceptOrRefuse) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefuse,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: AppColors.error),
                    child: const Text('Refuser',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40)),
                    child: const Text('Accepter',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else if (canCancel) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
              child: const Text('Annuler ma demande',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
          // Bouton « Laisser un avis » retiré (APP-119) : un accord n'atteint
          // jamais le statut TERMINE dans cette version — dépôt d'avis
          // reporté en V2, backend et écran conservés.
        ],
      ),
    );
  }
}

/// Jaune "en attente" — propre aux accords, pas dans la palette matching
class AccordCardColors {
  AccordCardColors._();

  static const attente = Color(0xFFB7791F);
  static const attenteBg = Color(0xFFFDF6E3);
}
