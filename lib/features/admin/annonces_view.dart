import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'annonces_viewmodel.dart';

/// Écran Annonces — modération des logements publiés (APP-121).
class AnnoncesView extends StackedView<AnnoncesViewModel> {
  const AnnoncesView({super.key});

  @override
  Widget builder(
    BuildContext context,
    AnnoncesViewModel viewModel,
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
                    child: Text('Annonces',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
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

  Widget _buildListe(BuildContext context, AnnoncesViewModel viewModel) {
    if (viewModel.isBusy && viewModel.annonces.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.annonces.isEmpty) {
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

    if (viewModel.annonces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('Aucune annonce ne correspond à ce filtre.',
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
        itemCount:
            viewModel.annonces.length + (viewModel.peutChargerPlus ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= viewModel.annonces.length) {
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
          final annonce = viewModel.annonces[index];
          return _AnnonceCard(
            logement: annonce,
            onSuspendre: () => _suspendre(context, viewModel, annonce),
            onRepublier: () => _republier(context, viewModel, annonce),
          );
        },
      ),
    );
  }

  /// Le motif part au propriétaire pour lui expliquer le retrait — le backend
  /// le refuse vide (400), on le demande donc avant d'envoyer.
  Future<void> _suspendre(BuildContext context, AnnoncesViewModel viewModel,
      Logement logement) async {
    final motif = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _MotifSheet(),
    );
    if (motif == null) return;

    final error = await viewModel.suspendre(logement, motif);
    if (context.mounted) _feedback(context, error, 'Annonce retirée ✓');
  }

  Future<void> _republier(BuildContext context, AnnoncesViewModel viewModel,
      Logement logement) async {
    final confirme = await confirmerAction(
      context,
      titre: 'Remettre cette annonce en ligne ?',
      message: '${logement.type.label} · ${logement.ville} redeviendra visible '
          'dans la recherche et le matching.',
      confirmer: 'Republier',
    );
    if (!confirme) return;

    final error = await viewModel.republier(logement);
    if (context.mounted) _feedback(context, error, 'Annonce republiée ✓');
  }

  void _feedback(BuildContext context, String? error, String succes) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? succes),
      backgroundColor: error == null ? AppColors.echange : AppColors.error,
    ));
  }

  @override
  AnnoncesViewModel viewModelBuilder(BuildContext context) =>
      AnnoncesViewModel();

  @override
  void onViewModelReady(AnnoncesViewModel viewModel) => viewModel.load();
}

// ─── Filtres de statut ────────────────────────────────────────────

class _Filtres extends StatelessWidget {
  final AnnoncesViewModel viewModel;

  const _Filtres({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          for (final statut in LogementStatut.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _Chip(
                label: statut.label,
                selected: viewModel.filtreStatut == statut,
                onTap: () => viewModel.setFiltreStatut(statut),
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

// ─── Carte d'une annonce ──────────────────────────────────────────

class _AnnonceCard extends StatelessWidget {
  final Logement logement;
  final VoidCallback onSuspendre;
  final VoidCallback onRepublier;

  const _AnnonceCard({
    required this.logement,
    required this.onSuspendre,
    required this.onRepublier,
  });

  /// Couleurs du statut. Le libellé est toujours affiché à côté : le statut
  /// ne se lit jamais à la seule couleur.
  (Color, Color) get _couleursStatut => switch (logement.statut) {
        LogementStatut.ACTIF => (AppColors.echange, AppColors.echangeLight),
        LogementStatut.SUSPENDU => (AppColors.error, AppColors.errorLight),
        _ => (AppColors.textSecondary, AppColors.surfaceDark),
      };

  @override
  Widget build(BuildContext context) {
    final (couleur, fond) = _couleursStatut;
    final suspendue = logement.statut == LogementStatut.SUSPENDU;

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
                    Text('${logement.type.label} · ${logement.ville}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${logement.adresse} · ${logement.loyer.round()} €'
                      '${logement.ownerPrenom != null ? ' · ${logement.ownerPrenom}' : ''}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Badge(
                  label: logement.statut.label,
                  color: couleur,
                  background: fond),
            ],
          ),

          // ─── Motif de la suspension ───────────────────────
          if (suspendue && logement.moderationNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Motif : ${logement.moderationNote}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary)),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          _actions(suspendue),
        ],
      ),
    );
  }

  /// Une annonce en brouillon n'a jamais été publiée : la suspendre n'aurait
  /// aucun effet, on ne propose donc rien.
  Widget _actions(bool suspendue) {
    if (logement.statut == LogementStatut.BROUILLON ||
        logement.statut == LogementStatut.ARCHIVE) {
      return const Text('Aucune action : cette annonce n\'est pas en ligne.',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary));
    }

    return SizedBox(
      width: double.infinity,
      child: suspendue
          ? ElevatedButton(
              onPressed: onRepublier,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
              child: const Text('Republier', style: TextStyle(fontSize: 13)),
            )
          : OutlinedButton(
              onPressed: onSuspendre,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Retirer', style: TextStyle(fontSize: 13)),
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
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ─── Saisie du motif ──────────────────────────────────────────────

class _MotifSheet extends StatefulWidget {
  const _MotifSheet();

  @override
  State<_MotifSheet> createState() => _MotifSheetState();
}

class _MotifSheetState extends State<_MotifSheet> {
  final _controller = TextEditingController();

  bool get _valide => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Retirer cette annonce',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elle disparaîtra de la recherche et du matching. Le motif est '
              'envoyé au propriétaire : sans explication, il ne comprendra pas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Motif du retrait',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _valide
                  ? () => Navigator.pop(context, _controller.text.trim())
                  : null,
              child: const Text('Retirer'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
