import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/widgets/confirmation_dialog.dart';
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
                    tooltip: 'Ajouter un logement',
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
            tooltip: 'Ajouter un logement',
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
  final VoidCallback onSupprimer;
  final VoidCallback onModifier;

  const _LogementCard({
    required this.logement,
    required this.isAlternant,
    required this.villeEcole,
    required this.villeEntreprise,
    required this.onPublish,
    required this.onSupprimer,
    required this.onModifier,
  });

  /// Pourquoi ce logement publié n'entre pas dans le matching.
  /// Deux causes possibles, et l'utilisateur ne peut agir que sur la seconde.
  String get _raisonHorsMatching {
    final ville = logement.ville;
    final estUneVilleDuProfil =
        ville.toLowerCase() == (villeEcole ?? '').toLowerCase() ||
            ville.toLowerCase() == (villeEntreprise ?? '').toLowerCase();
    return estUneVilleDuProfil
        ? 'Tu as déjà un autre logement rattaché à $ville : seul le premier '
            'entre dans le matching.'
        : "$ville n'est ni ta ville d'école ni celle de ton entreprise : ce "
            "logement n'entre pas dans le matching.";
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await confirmerAction(
      context,
      titre: 'Supprimer ce logement ?',
      message: '${logement.type.label} · ${logement.ville} sera définitivement '
          'supprimé. Cette action est irréversible.',
      confirmer: 'Supprimer',
      destructif: true,
    );
    if (confirmed) onSupprimer();
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
          // ─── Grande photo 16:9 en tête ────────────────────
          // Remplace l'ancienne vignette 56×56 : l'annonce devient visuelle,
          // cohérente avec l'accueil et l'écran Recherche.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: logement.photoUrls.isNotEmpty
                  ? Image.network(logement.photoUrls.first,
                      fit: BoxFit.cover,
                      semanticLabel:
                          'Photo du logement à ${logement.ville}',
                      errorBuilder: (_, _, _) => const _PhotoFallback())
                  : const _PhotoFallback(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Infos (prix mis en avant) ────────────────────
          Text('${logement.loyer.toStringAsFixed(0)} € / mois',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
              '${logement.type.label} · '
              '${logement.surface.toStringAsFixed(0)} m² · ${logement.ville}',
              style: Theme.of(context).textTheme.bodySmall),
          Text(logement.adresse,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
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

          // APP-120 : le bouton « Associer à une ville » a disparu. Le choix
          // n'en était pas un — la ville se déduit du logement et du profil, et
          // le backend le fait maintenant tout seul à la publication.
          // Reste à prévenir quand le logement sort des deux villes : il
          // n'entre alors pas dans le matching, et rien ne le disait avant.
          if (isAlternant &&
              logement.statut == LogementStatut.ACTIF &&
              logement.villeAssociee == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.chevauchementLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.chevauchement),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _raisonHorsMatching,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── Actions selon l'état ──────────────────────────
          if (logement.statut == LogementStatut.BROUILLON) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPublish,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
                child: const Text('Publier', style: TextStyle(fontSize: 13)),
              ),
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

}

/// Visuel de repli quand l'annonce n'a pas de photo (ou qu'elle ne charge pas).
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      alignment: Alignment.center,
      child:
          const Icon(Icons.apartment, size: 32, color: AppColors.textTertiary),
    );
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
