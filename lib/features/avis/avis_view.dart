import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';
import 'avis_viewmodel.dart';

/// Dépôt d'un avis après un accord terminé :
/// étoiles interactives, commentaire, cible utilisateur ou logement.
class AvisView extends StackedView<AvisViewModel> {
  final Accord accord;

  const AvisView({super.key, required this.accord});

  @override
  Widget builder(
    BuildContext context,
    AvisViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laisser un avis')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Résumé de l'accord ─────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_outlined,
                        color: AppColors.echange),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(viewModel.accord.type.label,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(viewModel.accord.dateDebut)} → '
                            '${DateFormat('dd/MM/yyyy').format(viewModel.accord.dateFin)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Cible : utilisateur ou logement ────────────
              Text('Tu évalues…',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _TargetChip(
                    label: 'La personne',
                    selected:
                        viewModel.targetType == ReviewTargetType.USER,
                    onTap: () =>
                        viewModel.setTargetType(ReviewTargetType.USER),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (viewModel.peutNoterLogement)
                    _TargetChip(
                      label: 'Son logement',
                      selected:
                          viewModel.targetType == ReviewTargetType.LOGEMENT,
                      onTap: () => viewModel
                          .setTargetType(ReviewTargetType.LOGEMENT),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Étoiles interactives ───────────────────────
              Text('Ta note',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    // Accessibilité (APP-112) : chaque étoile annonce la note
                    // qu'elle attribue au lecteur d'écran
                    tooltip: 'Noter $star sur 5',
                    onPressed: () => viewModel.setRating(star),
                    iconSize: 40,
                    icon: Icon(
                      star <= viewModel.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.chevauchement,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Commentaire ────────────────────────────────
              TextField(
                controller: viewModel.commentController,
                maxLines: 4,
                maxLength: 500, // le compteur natif affiche "123/500"
                decoration: const InputDecoration(
                    hintText: 'Ton commentaire (optionnel)'),
                onChanged: (_) {}, // rebuild du compteur natif
              ),

              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(viewModel.errorMessage!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                // Désactivé tant qu'aucune étoile n'est choisie
                onPressed: (viewModel.rating < 1 || viewModel.isBusy)
                    ? null
                    : viewModel.submit,
                child: viewModel.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Publier mon avis'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  AvisViewModel viewModelBuilder(BuildContext context) =>
      AvisViewModel(accord: accord);

  @override
  void onViewModelReady(AvisViewModel viewModel) => viewModel.init();
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TargetChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
