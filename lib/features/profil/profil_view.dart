import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/review.dart';
import 'profil_viewmodel.dart';

/// Mon profil — onglet Profil du shell (tous rôles).
/// Style « liste de réglages » : un en-tête d'identité, puis une carte-ligne
/// par paramètre (icône, titre, valeur, chevron) qui ouvre un écran ou une
/// action au tap. Objectif : épuré, familier, peu de texte.
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
    final isChercheur = user.role == UserRole.ETUDIANT ||
        user.role == UserRole.ALTERNANT;
    final isProprietaire = user.role == UserRole.PROPRIETAIRE;

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
                  radius: 40,
                  backgroundColor: AppColors.echangeLight,
                  child: Text(user.initials,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.echange)),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(user.fullName,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(user.email,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Badge(
                        label: user.role.label,
                        color: AppColors.colocation,
                        background: AppColors.colocationLight),
                    if (user.isVerified)
                      const _Badge(
                          label: 'Vérifié ✓',
                          color: AppColors.echange,
                          background: AppColors.echangeLight),
                  ],
                ),
                // Réputation compacte (masquée si aucun avis, pour rester épuré)
                if (rep != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < rep.avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: AppColors.chevauchement,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                          '${rep.avgRating.toStringAsFixed(1)} · '
                          '${rep.totalReviews} avis',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Cartes-lignes (une par paramètre) ──────────────

          // Suivi des candidatures — étudiant ET alternant (tous deux cherchent
          // une location classique). La valeur à droite = nombre suivi.
          if (isChercheur)
            _ProfilTile(
              icon: Icons.fact_check_outlined,
              title: 'Mes candidatures',
              trailing: viewModel.nbCandidatures > 0
                  ? '${viewModel.nbCandidatures}'
                  : null,
              onTap: viewModel.goToMesCandidatures,
            ),

          // Alternance : ouvre le formulaire d'édition (villes, rythme, dates)
          if (viewModel.isAlternant && viewModel.alternantProfile != null)
            _ProfilTile(
              icon: Icons.sync_alt,
              title: 'Mon alternance',
              onTap: viewModel.goToEditAlternance,
            ),

          if (viewModel.isAlternant)
            _ProfilTile(
              icon: Icons.calendar_month_outlined,
              title: 'Mon calendrier',
              onTap: viewModel.goToCalendrier,
            ),

          // Mes logements — l'alternant (pas d'onglet Logement) et le
          // propriétaire (dont c'est le cœur d'activité) gèrent leurs biens ici.
          if (viewModel.isAlternant || isProprietaire)
            _ProfilTile(
              icon: Icons.apartment_outlined,
              title: 'Mes logements',
              trailing: viewModel.logements.isEmpty
                  ? null
                  : '${viewModel.logements.length}',
              onTap: viewModel.goToGererLogements,
            ),

          // Mes accords : réservé aux modes chercheur (étudiant/alternant).
          // Un accord n'existe qu'entre deux alternants via le matching ; le
          // propriétaire (compte séparé, sans matching) n'en a jamais — la
          // tuile ouvrirait un écran toujours vide.
          if (isChercheur)
            _ProfilTile(
              icon: Icons.description_outlined,
              title: 'Mes accords',
              onTap: viewModel.goToMesAccords,
            ),

          // Mode : la valeur à droite montre le mode courant, le tap le change
          if (viewModel.canChangeMode)
            _ProfilTile(
              icon: Icons.swap_horiz,
              title: 'Mon mode',
              trailing: user.role.label,
              onTap: viewModel.isBusy
                  ? null
                  : () => _confirmChangeMode(context, viewModel),
            ),

          // ─── Avis reçus ─────────────────────────────────────
          // L'en-tête montre la note moyenne ; ici on déroule le détail des
          // avis (note, commentaire, date). Donnée déjà chargée, masquée si
          // aucun avis pour ne pas alourdir un profil neuf.
          if (viewModel.avisRecus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Avis reçus', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...viewModel.avisRecus.map((avis) => _AvisCard(avis: avis)),
          ],

          const SizedBox(height: AppSpacing.md),
          _ProfilTile(
            icon: Icons.logout,
            title: 'Se déconnecter',
            destructive: true,
            onTap: () => _confirmLogout(context, viewModel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, ProfilViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Non')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Oui')),
        ],
      ),
    );
    if (confirmed == true) await viewModel.logout();
  }

  Future<void> _confirmChangeMode(
      BuildContext context, ProfilViewModel viewModel) async {
    final target = viewModel.otherStudentMode;
    if (target == null) return;
    final becomeAlternant = target == UserRole.ALTERNANT;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(becomeAlternant
            ? 'Passer en mode alternant ?'
            : 'Passer en mode étudiant ?'),
        content: Text(becomeAlternant
            ? 'On te demandera de renseigner ton alternance (villes, rythme) juste après.'
            : 'Tu repasses en simple recherche de logement. Ton profil d\'alternance est conservé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed == true) await viewModel.changeMode(target);
  }

  @override
  ProfilViewModel viewModelBuilder(BuildContext context) => ProfilViewModel();

  @override
  void onViewModelReady(ProfilViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

/// Carte-ligne de réglage : icône · titre · (valeur) · chevron.
/// [destructive] la passe en rouge et retire le chevron (action, pas navigation).
class _ProfilTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const _ProfilTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = destructive ? AppColors.error : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: couleur),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: couleur)),
              ),
              if (trailing != null)
                Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
              if (!destructive) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'un avis reçu : rangée d'étoiles + date, puis le commentaire.
class _AvisCard extends StatelessWidget {
  final Review avis;

  const _AvisCard({required this.avis});

  @override
  Widget build(BuildContext context) {
    final aCommentaire =
        avis.comment != null && avis.comment!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < avis.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.chevauchement,
                ),
              ),
              const Spacer(),
              Text(DateFormat('dd/MM/yyyy').format(avis.createdAt),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (aCommentaire) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(avis.comment!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
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
