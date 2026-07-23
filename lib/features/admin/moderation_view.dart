import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/logement_report.dart';
import '../../shared/models/message_report.dart';
import 'moderation_viewmodel.dart';

/// Écran Modération — file des messages signalés (APP-121).
class ModerationView extends StackedView<ModerationViewModel> {
  const ModerationView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ModerationViewModel viewModel,
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
                    child: Text('Modération',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  if (viewModel.total > 0)
                    Text('${viewModel.total} en attente',
                        style: Theme.of(context).textTheme.bodySmall),
                  IconButton(
                    tooltip: 'Mots interdits',
                    onPressed: viewModel.ouvrirMotsInterdits,
                    icon: const Icon(Icons.block_outlined),
                  ),
                ],
              ),
            ),
            _Bascule(viewModel: viewModel),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Expanded(
              child: viewModel.file == FileModeration.messages
                  ? _buildListe(context, viewModel)
                  : _buildListeAnnonces(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(BuildContext context, ModerationViewModel viewModel) {
    if (viewModel.isBusy && viewModel.signalements.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.signalements.isEmpty) {
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

    if (viewModel.signalements.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.load,
        color: AppColors.echange,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.verified_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucun signalement en attente.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount:
            viewModel.signalements.length + (viewModel.peutChargerPlus ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= viewModel.signalements.length) {
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
          final signalement = viewModel.signalements[index];
          return _SignalementCard(
            signalement: signalement,
            onMasquer: () => _masquer(context, viewModel, signalement),
          );
        },
      ),
    );
  }

  Widget _buildListeAnnonces(
      BuildContext context, ModerationViewModel viewModel) {
    if (viewModel.isBusy && viewModel.annoncesSignalees.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.annoncesSignalees.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.load,
        color: AppColors.echange,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.verified_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('Aucune annonce signalée.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: viewModel.annoncesSignalees.length +
            (viewModel.peutChargerPlus ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= viewModel.annoncesSignalees.length) {
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
          final signalement = viewModel.annoncesSignalees[index];
          return _SignalementAnnonceCard(
            signalement: signalement,
            onRetirer: () => _retirerAnnonce(context, viewModel, signalement),
          );
        },
      ),
    );
  }

  /// Retirer l'annonce depuis la file : elle en sort d'elle-même ensuite,
  /// le serveur excluant les annonces suspendues des signalements en attente.
  Future<void> _retirerAnnonce(
    BuildContext context,
    ModerationViewModel viewModel,
    LogementReport signalement,
  ) async {
    final motif = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NoteSheet(titre: 'Retirer cette annonce'),
    );
    if (motif == null) return;

    final error = await viewModel.retirerAnnonce(signalement, motif);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Annonce retirée ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  /// Masquer exige une note : c'est la trace de la décision, et le backend
  /// la refuse vide (400). On la demande donc avant d'envoyer quoi que ce soit.
  Future<void> _masquer(
    BuildContext context,
    ModerationViewModel viewModel,
    MessageReport signalement,
  ) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // laisse la place au clavier
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NoteSheet(),
    );
    if (note == null) return;

    final error = await viewModel.masquer(signalement, note);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Message masqué ✓'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  ModerationViewModel viewModelBuilder(BuildContext context) =>
      ModerationViewModel();

  @override
  void onViewModelReady(ModerationViewModel viewModel) => viewModel.load();
}

// ─── Carte d'un signalement ───────────────────────────────────────

class _SignalementCard extends StatelessWidget {
  final MessageReport signalement;
  final VoidCallback onMasquer;

  const _SignalementCard(
      {required this.signalement, required this.onMasquer});

  @override
  Widget build(BuildContext context) {
    final dateMessage = signalement.messageCreeLe;

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
          // ─── Motif du signalement ─────────────────────────
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  signalement.motif,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Le message concerné ──────────────────────────
          // C'est la pièce sur laquelle le modérateur décide.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: signalement.contenuDisponible
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signalement.auteurNom ?? 'Auteur inconnu',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(signalement.contenuMessage!,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  )
                : const Text(
                    'Ce message n\'existe plus : impossible de le consulter.',
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Qui a signalé, et quand ──────────────────────
          Text(
            [
              'Signalé par ${signalement.signalePar ?? 'un utilisateur'}',
              DateFormat('dd/MM/yyyy').format(signalement.createdAt),
              if (dateMessage != null)
                'message du ${DateFormat('dd/MM/yyyy').format(dateMessage)}',
            ].join(' · '),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onMasquer,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: const Text('Masquer', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saisie de la note de modération ──────────────────────────────

class _NoteSheet extends StatefulWidget {
  /// Le libellé change selon la décision : masquer un message ou retirer
  /// une annonce. La mécanique (note obligatoire) est la même.
  final String titre;

  const _NoteSheet({this.titre = 'Masquer ce message'});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _controller = TextEditingController();

  /// Le bouton reste inactif tant que la note est vide : le backend la
  /// refuserait (400), autant l'empêcher ici plutôt que de faire un
  /// aller-retour pour rien.
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
            Text(widget.titre,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Le message reste enregistré mais n\'est plus visible. '
              'La note garde la trace de ta décision.',
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
                hintText: 'Motif de la décision',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _valide
                  ? () => Navigator.pop(context, _controller.text.trim())
                  : null,
              child: const Text('Confirmer'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Bascule entre les deux files ─────────────────────────────────

class _Bascule extends StatelessWidget {
  final ModerationViewModel viewModel;

  const _Bascule({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          for (final file in FileModeration.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => viewModel.setFile(file),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: viewModel.file == file
                        ? AppColors.textPrimary
                        : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                    border: Border.all(
                        color: viewModel.file == file
                            ? AppColors.textPrimary
                            : AppColors.border),
                  ),
                  child: Text(
                    file.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: viewModel.file == file
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: viewModel.file == file
                          ? AppColors.background
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Carte d'une annonce signalée ─────────────────────────────────

class _SignalementAnnonceCard extends StatelessWidget {
  final LogementReport signalement;
  final VoidCallback onRetirer;

  const _SignalementAnnonceCard(
      {required this.signalement, required this.onRetirer});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(signalement.motif,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: signalement.annonceDisponible
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signalement.logementLibelle!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      if (signalement.proprietaire != null) ...[
                        const SizedBox(height: 2),
                        Text('Publiée par ${signalement.proprietaire}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  )
                : const Text(
                    "Cette annonce n'existe plus : rien à modérer.",
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Signalé par ${signalement.signalePar ?? 'un utilisateur'} · '
            '${DateFormat('dd/MM/yyyy').format(signalement.createdAt)}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          if (signalement.annonceDisponible) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetirer,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Retirer', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
