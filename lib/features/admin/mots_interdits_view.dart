import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/mot_interdit.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'mots_interdits_viewmodel.dart';

/// Écran Mots interdits — filtrage de la messagerie (APP-121).
class MotsInterditsView extends StackedView<MotsInterditsViewModel> {
  const MotsInterditsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MotsInterditsViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mots interdits')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                  AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
              child: Text(
                'Un message contenant l\'un de ces mots est refusé à l\'envoi. '
                'La casse n\'a pas d\'importance : tout est comparé en minuscules.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: _ChampAjout(
                onAjouter: (mot) => _ajouter(context, viewModel, mot),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            Expanded(child: _buildListe(context, viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(BuildContext context, MotsInterditsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.mots.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.mots.isEmpty) {
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

    if (viewModel.mots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Aucun mot filtré pour l\'instant.\n'
            'Les messages passent tous sans contrôle de contenu.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: viewModel.mots.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final mot = viewModel.mots[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(mot.mot, style: const TextStyle(fontSize: 15)),
          trailing: IconButton(
            tooltip: 'Retirer de la liste',
            onPressed: () => _supprimer(context, viewModel, mot),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        );
      },
    );
  }

  Future<void> _ajouter(BuildContext context, MotsInterditsViewModel viewModel,
      String mot) async {
    final error = await viewModel.ajouter(mot);
    if (context.mounted) _feedback(context, error, 'Mot ajouté ✓');
  }

  Future<void> _supprimer(BuildContext context,
      MotsInterditsViewModel viewModel, MotInterdit mot) async {
    final confirme = await confirmerAction(
      context,
      titre: 'Retirer « ${mot.mot} » ?',
      message: 'Les messages contenant ce mot passeront de nouveau.',
      confirmer: 'Retirer',
      destructif: true,
    );
    if (!confirme) return;

    final error = await viewModel.supprimer(mot);
    if (context.mounted) _feedback(context, error, 'Mot retiré ✓');
  }

  void _feedback(BuildContext context, String? error, String succes) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? succes),
      backgroundColor: error == null ? AppColors.echange : AppColors.error,
    ));
  }

  @override
  MotsInterditsViewModel viewModelBuilder(BuildContext context) =>
      MotsInterditsViewModel();

  @override
  void onViewModelReady(MotsInterditsViewModel viewModel) => viewModel.load();
}

// ─── Champ de saisie ──────────────────────────────────────────────

class _ChampAjout extends StatefulWidget {
  final Future<void> Function(String mot) onAjouter;

  const _ChampAjout({required this.onAjouter});

  @override
  State<_ChampAjout> createState() => _ChampAjoutState();
}

class _ChampAjoutState extends State<_ChampAjout> {
  final _controller = TextEditingController();

  bool get _valide => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_valide) return;
    final mot = _controller.text.trim();
    // Le champ est vidé avant l'appel : la liste rechargée montrera le mot
    // tel qu'il a été normalisé, pas la saisie.
    _controller.clear();
    setState(() {});
    await widget.onAjouter(mot);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: 100,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _envoyer(),
            decoration: const InputDecoration(
              hintText: 'Ajouter un mot',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Ajouter',
          onPressed: _valide ? _envoyer : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
