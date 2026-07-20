import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/candidature.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/logement_card.dart';
import 'mes_candidatures_viewmodel.dart';

/// Mes candidatures — onglet de l'étudiant (APP-117).
/// Remplace le Trello : la liste des annonces suivies, avec un statut que
/// l'utilisateur fait évoluer lui-même.
/// [standalone] = true : écran empilé avec AppBar. L'alternant y accède depuis
/// son Profil (sa bottom nav est pleine), alors que l'étudiant a un onglet
/// dédié. Un alternant cherche aussi une location classique : il crée donc des
/// candidatures et doit pouvoir les consulter (APP-117).
class MesCandidaturesView extends StackedView<MesCandidaturesViewModel> {
  /// Bascule sur l'onglet Recherche (état vide). null en mode empilé.
  final VoidCallback? onSearch;

  final bool standalone;

  const MesCandidaturesView({
    super.key,
    this.onSearch,
    this.standalone = false,
  });

  @override
  Widget builder(
    BuildContext context,
    MesCandidaturesViewModel viewModel,
    Widget? child,
  ) {
    final content = SafeArea(child: _buildBody(context, viewModel));

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes candidatures')),
      body: content,
    );
  }

  Widget _buildBody(BuildContext context, MesCandidaturesViewModel viewModel) {
    if (viewModel.isBusy && viewModel.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: viewModel.load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre interne masqué en mode empilé (l'AppBar le porte déjà)
        if (!standalone)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, AppSpacing.xs),
            child: Text('Mes candidatures',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Text('Garde le fil des annonces auxquelles tu as postulé.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: AppSpacing.md),

        if (viewModel.isEmpty)
          Expanded(child: _etatVide(context, viewModel))
        else ...[
          _filtres(context, viewModel),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _liste(context, viewModel)),
        ],
      ],
    );
  }

  /// Chips de filtre — uniquement les statuts réellement présents, avec compteur.
  Widget _filtres(BuildContext context, MesCandidaturesViewModel viewModel) {
    final statutsPresents = CandidatureStatut.values
        .where((s) => viewModel.countFor(s) > 0)
        .toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        children: [
          for (final s in statutsPresents)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _Chip(
                label: '${s.label} · ${viewModel.countFor(s)}',
                selected: viewModel.filtre == s,
                onTap: () => viewModel.toggleFiltre(s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _liste(BuildContext context, MesCandidaturesViewModel viewModel) {
    final items = viewModel.candidatures;
    if (items.isEmpty) {
      return Center(
        child: Text('Aucune candidature dans ce filtre.',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final c = items[i];
          return LogementCard(
            logement: c.logement,
            onTap: () => viewModel.goToDetail(c.logement),
            footer: Row(
              children: [
                // Le statut est cliquable : il ouvre la feuille de changement
                Expanded(
                  child: InkWell(
                    onTap: () => _changerStatut(context, viewModel, c),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatutPastille(statut: c.statut),
                        const SizedBox(width: AppSpacing.sm),
                        Text(c.statut.label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 2),
                        const Icon(Icons.expand_more,
                            size: 18, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer du suivi',
                  onPressed: () => _retirer(context, viewModel, c),
                  // Action destructive → rouge (convention mobile)
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.error),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// État vide, mais rafraîchissable : le ListView reste scrollable pour que
  /// le pull-to-refresh fonctionne même sans aucune candidature.
  Widget _etatVide(BuildContext context, MesCandidaturesViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.fact_check_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('Tu ne suis encore aucune annonce.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'Quand tu contactes un propriétaire, l\'annonce arrive ici '
              'automatiquement. Tu peux aussi suivre une annonce depuis son détail.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          // Pas de bouton en mode empilé : il n'y a pas d'onglet Recherche
          // vers lequel basculer depuis un écran poussé.
          if (onSearch != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Rechercher un logement'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Feuille de choix du statut — même pattern mobile que le tri de la recherche.
  Future<void> _changerStatut(BuildContext context,
      MesCandidaturesViewModel viewModel, Candidature c) async {
    final choix = await showModalBottomSheet<CandidatureStatut>(
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
              child: Text('Où en es-tu ?',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final s in CandidatureStatut.values)
              ListTile(
                leading: _StatutPastille(statut: s),
                title: Text(s.label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: c.statut == s
                            ? FontWeight.w600
                            : FontWeight.w400)),
                trailing: c.statut == s
                    ? const Icon(Icons.check, color: AppColors.echange)
                    : null,
                onTap: () => Navigator.pop(sheetContext, s),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (choix == null || choix == c.statut) return;
    final erreur = await viewModel.changerStatut(c, choix);
    if (erreur != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erreur)));
    }
  }

  Future<void> _retirer(BuildContext context,
      MesCandidaturesViewModel viewModel, Candidature c) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer du suivi ?'),
        content: const Text(
            'Cette annonce ne sera plus dans tes candidatures. '
            'Tu pourras la re-suivre depuis la recherche.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Retirer')),
        ],
      ),
    );
    if (confirme != true) return;
    final erreur = await viewModel.retirer(c);
    if (erreur != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erreur)));
    }
  }

  @override
  MesCandidaturesViewModel viewModelBuilder(BuildContext context) =>
      MesCandidaturesViewModel();

  @override
  void onViewModelReady(MesCandidaturesViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

/// Pastille de couleur du statut. L'information n'est jamais portée par la
/// seule couleur : le libellé texte l'accompagne toujours (règle OPQUAST).
class _StatutPastille extends StatelessWidget {
  final CandidatureStatut statut;

  const _StatutPastille({required this.statut});

  Color get _couleur => switch (statut) {
        CandidatureStatut.A_CONTACTER => AppColors.textTertiary,
        CandidatureStatut.CONTACTE => AppColors.colocation,
        CandidatureStatut.VISITE_PREVUE => AppColors.chevauchement,
        CandidatureStatut.VISITEE => AppColors.chevauchement,
        CandidatureStatut.SANS_SUITE => AppColors.error,
        CandidatureStatut.ACCEPTEE => AppColors.echange,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _couleur),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
