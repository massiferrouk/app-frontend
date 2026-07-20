import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/alternant_profile.dart';
import '../../../shared/models/enums.dart';
import 'profil_creation_viewmodel.dart';

/// Formulaire de création — ou de modification (APP-117 · A-04) — du profil
/// alternant : villes, école, entreprise, rythme, période d'alternance.
class ProfilCreationView extends StackedView<ProfilCreationViewModel> {
  /// Profil à modifier — null pour une création (parcours d'inscription).
  final AlternantProfile? profile;

  const ProfilCreationView({super.key, this.profile});

  @override
  Widget builder(
    BuildContext context,
    ProfilCreationViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(viewModel.isEdition
            ? 'Modifier mon alternance'
            : 'Mon profil alternant'),
        // Création = étape obligatoire (pas de retour) ; édition = retour permis
        automaticallyImplyLeading: viewModel.isEdition,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                viewModel.isEdition
                    ? 'Corrige tes informations. Ton calendrier et tes matchs '
                        'seront recalculés automatiquement.'
                    : 'Ces informations alimentent le calcul de tes matchs.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // APP-117 (A-07) : avertissement si un accord vivant existe — on
              // autorise la modif mais on explique qu'elle n'affecte pas l'accord.
              if (viewModel.isEdition && viewModel.hasLivingAccord) ...[
                const _AccordWarningBanner(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ─── Villes ─────────────────────────────────────
              TextField(
                controller: viewModel.villeAController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'Ville de ton école'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: viewModel.villeBController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'Ville de ton entreprise'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── École / entreprise ─────────────────────────
              TextField(
                controller: viewModel.ecoleController,
                decoration: const InputDecoration(hintText: 'Nom de l\'école'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: viewModel.entrepriseController,
                decoration:
                    const InputDecoration(hintText: 'Nom de l\'entreprise'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Rythme ─────────────────────────────────────
              Text('Rythme d\'alternance',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<RythmeAlternance>(
                initialValue: viewModel.selectedRythme,
                // selectable : AUTRE n'est plus proposé (APP-110)
                items: RythmeAlternance.selectable
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: viewModel.selectRythme,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Première semaine (APP-110) ─────────────────
              // L'ordre de départ inverse tout le calendrier : « 3 semaines
              // entreprise puis 1 école » ≠ « 1 école puis 3 entreprise »
              Text('Ta première semaine d\'alternance',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<PremiereSemaine>(
                segments: PremiereSemaine.values
                    .map((p) => ButtonSegment(
                          value: p,
                          label: Text(p.label),
                          icon: Icon(p == PremiereSemaine.ECOLE
                              ? Icons.school_outlined
                              : Icons.business_outlined),
                        ))
                    .toList(),
                selected: {viewModel.selectedPremiereSemaine},
                onSelectionChanged: (selection) =>
                    viewModel.selectPremiereSemaine(selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Dates ──────────────────────────────────────
              Text('Période d\'alternance',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Début',
                      value: viewModel.dateDebut,
                      onPick: (context) => _pickDate(
                        context,
                        initial: viewModel.dateDebut,
                        onPicked: viewModel.setDateDebut,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateField(
                      label: 'Fin',
                      value: viewModel.dateFin,
                      onPick: (context) => _pickDate(
                        context,
                        initial: viewModel.dateFin,
                        onPicked: viewModel.setDateFin,
                      ),
                    ),
                  ),
                ],
              ),

              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: viewModel.isBusy ? null : viewModel.submit,
                child: viewModel.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(viewModel.isEdition
                        ? 'Enregistrer'
                        : 'Créer mon profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    DateTime? initial,
    required void Function(DateTime?) onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    onPicked(picked);
  }

  @override
  void onViewModelReady(ProfilCreationViewModel viewModel) => viewModel.init();

  @override
  ProfilCreationViewModel viewModelBuilder(BuildContext context) =>
      ProfilCreationViewModel(existingProfile: profile);
}

/// Bandeau d'avertissement (APP-117 · A-07) affiché en édition quand
/// l'utilisateur a un accord vivant. Orange = avertissement (design system).
class _AccordWarningBanner extends StatelessWidget {
  const _AccordWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.chevauchementLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.chevauchement),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 20, color: AppColors.chevauchement),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tu as un accord en cours. Le modifier ici ne changera pas cet '
              'accord (il est déjà figé) — seuls tes futurs matchs seront '
              'recalculés.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ date cliquable affichant la valeur choisie
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(BuildContext) onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Text(
              value == null
                  ? 'Choisir…'
                  : DateFormat('dd/MM/yyyy').format(value!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: value == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
