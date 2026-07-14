import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import 'mes_logements_viewmodel.dart';

/// Mes logements — onglet Logement du propriétaire, ou écran empilé
/// ([standalone] = true, avec AppBar) accessible depuis le Profil de
/// l'alternant (dont la nav n'a plus d'onglet Logement).
class MesLogementsView extends StackedView<MesLogementsViewModel> {
  final bool standalone;

  const MesLogementsView({super.key, this.standalone = false});

  @override
  Widget builder(
    BuildContext context,
    MesLogementsViewModel viewModel,
    Widget? child,
  ) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header interne (titre + ajout) masqué en standalone : l'AppBar le porte
          if (!standalone)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                  AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Mes logements',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  IconButton(
                    onPressed: viewModel.goToAjouter,
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes logements'),
        actions: [
          IconButton(
            onPressed: viewModel.goToAjouter,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildList(BuildContext context, MesLogementsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.logements.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.logements.isEmpty) {
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
      child: viewModel.logements.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.apartment_outlined,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun logement pour l\'instant.\n'
                  'Ajoute ton logement pour activer les échanges !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: viewModel.logements.length,
              itemBuilder: (context, index) {
                final l = viewModel.logements[index];
                return GestureDetector(
                  onTap: () => viewModel.goToDetail(l),
                  child: _LogementCard(
                    logement: l,
                    isAlternant: viewModel.isAlternant,
                    villeEcole: viewModel.villeEcole,
                    villeEntreprise: viewModel.villeEntreprise,
                    onPublish: () => _handleAction(
                        context, () => viewModel.publish(l)),
                    onAssocier: (ville) => _handleAction(
                        context, () => viewModel.associer(l, ville)),
                    onSupprimer: () => _handleAction(
                        context, () => viewModel.supprimer(l)),
                    onModifier: () => viewModel.goToModifier(l),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, Future<String?> Function() action) async {
    final error = await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'C\'est fait ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  MesLogementsViewModel viewModelBuilder(BuildContext context) =>
      MesLogementsViewModel();

  @override
  void onViewModelReady(MesLogementsViewModel viewModel) => viewModel.load();
}

// ─── Carte d'un logement ──────────────────────────────────────────

class _LogementCard extends StatelessWidget {
  final Logement logement;
  final bool isAlternant;
  final String? villeEcole; // villeA du profil
  final String? villeEntreprise; // villeB du profil
  final VoidCallback onPublish;
  final void Function(VilleAssociee) onAssocier;
  final VoidCallback onSupprimer;
  final VoidCallback onModifier;

  const _LogementCard({
    required this.logement,
    required this.isAlternant,
    required this.villeEcole,
    required this.villeEntreprise,
    required this.onPublish,
    required this.onAssocier,
    required this.onSupprimer,
    required this.onModifier,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce logement ?'),
        content: Text(
            '${logement.type.label} · ${logement.ville} sera définitivement '
            'supprimé. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) onSupprimer();
  }

  (Color, Color) get _statutColors => switch (logement.statut) {
        LogementStatut.ACTIF => (AppColors.echange, AppColors.echangeLight),
        LogementStatut.SUSPENDU => (
            AppColors.chevauchement,
            AppColors.chevauchementLight
          ),
        _ => (AppColors.textSecondary, AppColors.surfaceDark),
      };

  @override
  Widget build(BuildContext context) {
    final (statutColor, statutBg) = _statutColors;

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
              // Vignette photo ou placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: logement.photoUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(logement.photoUrls.first,
                            fit: BoxFit.cover),
                      )
                    : const Icon(Icons.apartment,
                        color: AppColors.textTertiary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${logement.type.label} · ${logement.surface.toStringAsFixed(0)} m²',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${logement.ville} — ${logement.adresse}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                        '${logement.loyer.toStringAsFixed(0)} € / mois',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Badges statut + ville associée ───────────────
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _Badge(
                  label: logement.statut.label,
                  color: statutColor,
                  background: statutBg),
              if (logement.villeAssociee != null)
                _Badge(
                  label:
                      '${logement.villeAssociee!.label} · ${logement.ville}',
                  color: AppColors.colocation,
                  background: AppColors.colocationLight,
                ),
            ],
          ),

          // ─── Actions selon l'état ──────────────────────────
          if (logement.statut == LogementStatut.BROUILLON ||
              (isAlternant && logement.villeAssociee == null)) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (logement.statut == LogementStatut.BROUILLON)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPublish,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40)),
                      child: const Text('Publier',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (logement.statut == LogementStatut.BROUILLON &&
                    isAlternant &&
                    logement.villeAssociee == null)
                  const SizedBox(width: AppSpacing.sm),
                if (isAlternant && logement.villeAssociee == null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showAssocierDialog(context),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40)),
                      child: const Text('Associer à une ville',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ],

          // ─── Modifier / Supprimer (toujours dispo pour le propriétaire) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onModifier,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier', style: TextStyle(fontSize: 13)),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                label: const Text('Supprimer',
                    style: TextStyle(fontSize: 13, color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAssocierDialog(BuildContext context) async {
    // On affiche les vrais noms de villes du profil pour lever toute
    // ambiguïté : « Paris (ville de ton école) » plutôt que « Ville A ».
    final labelEcole = villeEcole != null
        ? '$villeEcole (ville de ton école)'
        : 'Ville de ton école';
    final labelEntreprise = villeEntreprise != null
        ? '$villeEntreprise (ville de ton entreprise)'
        : 'Ville de ton entreprise';

    final ville = await showDialog<VilleAssociee>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Associer ce logement à…'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, VilleAssociee.VILLE_A),
            child: Text(labelEcole),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, VilleAssociee.VILLE_B),
            child: Text(labelEntreprise),
          ),
        ],
      ),
    );
    if (ville != null) onAssocier(ville);
  }
}

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
