import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/admin_user.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'comptes_viewmodel.dart';

/// Écran Comptes — gestion des utilisateurs par l'administration (APP-121).
class ComptesView extends StackedView<ComptesViewModel> {
  const ComptesView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ComptesViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                  AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Comptes',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  // Le total vient du serveur : il compte tous les résultats du
                  // filtre, pas seulement la page chargée.
                  if (viewModel.total > 0)
                    Text('${viewModel.total}',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _Filtres(viewModel: viewModel),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Expanded(child: _buildListe(context, viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(BuildContext context, ComptesViewModel viewModel) {
    if (viewModel.isBusy && viewModel.comptes.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.comptes.isEmpty) {
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

    if (viewModel.comptes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('Aucun compte ne correspond à ces filtres.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        // Une ligne de plus quand une page suivante existe : le bouton
        // « Charger plus ».
        itemCount:
            viewModel.comptes.length + (viewModel.peutChargerPlus ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= viewModel.comptes.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: TextButton(
                  onPressed: viewModel.chargerPlus,
                  child: const Text('Charger plus'),
                ),
              ),
            );
          }
          return _CompteCard(
            user: viewModel.comptes[index],
            onSuspendre: () => _confirmer(context, viewModel,
                user: viewModel.comptes[index], action: _Action.suspendre),
            onBannir: () => _confirmer(context, viewModel,
                user: viewModel.comptes[index], action: _Action.bannir),
            onReactiver: () => _confirmer(context, viewModel,
                user: viewModel.comptes[index], action: _Action.reactiver),
          );
        },
      ),
    );
  }

  /// Toute sanction passe par une confirmation. Le bannissement est présenté
  /// comme destructif : c'est le seul geste qu'on ne défait pas d'un clic.
  Future<void> _confirmer(
    BuildContext context,
    ComptesViewModel viewModel, {
    required AdminUser user,
    required _Action action,
  }) async {
    final (titre, message, libelle, destructif) = switch (action) {
      _Action.suspendre => (
          'Suspendre ce compte ?',
          '${user.fullName} perdra l\'accès immédiatement. '
              'Tu pourras lever la suspension à tout moment.',
          'Suspendre',
          false,
        ),
      _Action.bannir => (
          'Bannir ce compte ?',
          '${user.fullName} sera exclu définitivement et son compte marqué '
              'comme supprimé. Cette action est lourde de conséquences.',
          'Bannir',
          true,
        ),
      _Action.reactiver => (
          'Réactiver ce compte ?',
          '${user.fullName} retrouvera l\'accès. Il devra se reconnecter.',
          'Réactiver',
          false,
        ),
    };

    final confirme = await confirmerAction(context,
        titre: titre,
        message: message,
        confirmer: libelle,
        destructif: destructif);
    if (!confirme) return;

    final error = await switch (action) {
      _Action.suspendre => viewModel.suspendre(user),
      _Action.bannir => viewModel.bannir(user),
      _Action.reactiver => viewModel.reactiver(user),
    };

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'C\'est fait ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  ComptesViewModel viewModelBuilder(BuildContext context) => ComptesViewModel();

  @override
  void onViewModelReady(ComptesViewModel viewModel) => viewModel.load();
}

enum _Action { suspendre, bannir, reactiver }

// ─── Barre de filtres ─────────────────────────────────────────────

class _Filtres extends StatelessWidget {
  final ComptesViewModel viewModel;

  const _Filtres({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          for (final etat in EtatCompte.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _Chip(
                label: etat.label,
                selected: viewModel.filtreEtat == etat,
                onTap: () => viewModel.setFiltreEtat(etat),
              ),
            ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
          ),
          for (final role in UserRole.values.where((r) => r != UserRole.ADMIN))
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _Chip(
                label: role.label,
                selected: viewModel.filtreRole == role,
                onTap: () => viewModel.setFiltreRole(role),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Carte d'un compte ────────────────────────────────────────────

class _CompteCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onSuspendre;
  final VoidCallback onBannir;
  final VoidCallback onReactiver;

  const _CompteCard({
    required this.user,
    required this.onSuspendre,
    required this.onBannir,
    required this.onReactiver,
  });

  /// Couleurs de l'état. Le libellé est toujours affiché à côté : l'état ne
  /// doit jamais se lire à la seule couleur (règle d'accessibilité du projet).
  (Color, Color) get _couleursEtat => switch (user.etat) {
        EtatCompte.actif => (AppColors.echange, AppColors.echangeLight),
        EtatCompte.suspendu => (
            AppColors.chevauchement,
            AppColors.chevauchementLight
          ),
        EtatCompte.banni => (AppColors.error, AppColors.errorLight),
      };

  @override
  Widget build(BuildContext context) {
    final (couleur, fond) = _couleursEtat;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Badge(label: user.etat.label, color: couleur, background: fond),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _Badge(
                label: user.role.label,
                color: AppColors.textSecondary,
                background: AppColors.surfaceDark,
              ),
              _Badge(
                label: 'Inscrit le ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
                color: AppColors.textTertiary,
                background: AppColors.surface,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _actions(),
        ],
      ),
    );
  }

  /// Les actions dépendent de l'état : on ne propose jamais un geste sans
  /// effet (suspendre un compte déjà suspendu, réactiver un compte actif).
  Widget _actions() {
    return switch (user.etat) {
      EtatCompte.actif => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSuspendre,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
                child:
                    const Text('Suspendre', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: onBannir,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Bannir', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      EtatCompte.suspendu => Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onReactiver,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
                child:
                    const Text('Réactiver', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: onBannir,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Bannir', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      EtatCompte.banni => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onReactiver,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40)),
            child: const Text('Réactiver', style: TextStyle(fontSize: 13)),
          ),
        ),
    };
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
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
