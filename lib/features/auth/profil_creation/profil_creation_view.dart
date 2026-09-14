import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/alternant_profile.dart';
import '../../../shared/models/enums.dart';
import 'profil_creation_viewmodel.dart';

/// Formulaire de création — ou de modification (APP-117 · A-04) — du profil
/// alternant : villes (école / entreprise), rythme, période d'alternance.
class ProfilCreationView extends StackedView<ProfilCreationViewModel> {
  /// Profil à modifier — null pour une création (parcours d'inscription).
  final AlternantProfile? profile;

  /// Rôle à rétablir si l'utilisateur annule (APP-119) — renseigné uniquement
  /// à l'ouverture via « Changer de mode », null sinon (création obligatoire).
  final UserRole? roleAnnulation;

  const ProfilCreationView({super.key, this.profile, this.roleAnnulation});

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
        // Inscription : création obligatoire, pas de retour.
        // Édition : retour standard. Changement de mode : croix Annuler qui
        // RÉTABLIT l'ancien rôle — le compte est déjà passé alternant côté
        // serveur, un simple retour laisserait un état incohérent (APP-119).
        automaticallyImplyLeading: viewModel.isEdition,
        leading: viewModel.peutAnnuler
            ? IconButton(
                tooltip: 'Annuler le changement de mode',
                onPressed:
                    viewModel.isBusy ? null : viewModel.annulerChangementMode,
                icon: const Icon(Icons.close),
              )
            : null,
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

              // ─── Villes ─────────────────────────────────────
              // Autocomplétion sur la liste des communes (APP-122) : on
              // sélectionne une ville canonique au lieu de la taper librement,
              // pour ne pas rater un match à cause d'une faute de frappe.
              _VilleField(
                controller: viewModel.villeAController,
                focusNode: viewModel.villeAFocus,
                hint: 'Ville de ton école',
                rechercher: viewModel.rechercherVilles,
                errorText: viewModel.villeAErreur,
                valide: viewModel.villeAValide,
                onSelected: viewModel.verifierVilleA,
              ),
              const SizedBox(height: AppSpacing.md),
              _VilleField(
                controller: viewModel.villeBController,
                focusNode: viewModel.villeBFocus,
                hint: 'Ville de ton entreprise',
                rechercher: viewModel.rechercherVilles,
                errorText: viewModel.villeBErreur,
                valide: viewModel.villeBValide,
                onSelected: viewModel.verifierVilleB,
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
                // Cas « même ville » : on donne une porte de sortie actionnable
                // vers le mode étudiant (APP-122).
                if (viewModel.proposerModeEtudiant) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: viewModel.isBusy
                        ? null
                        : viewModel.passerEnModeEtudiant,
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: const Text('Passer en mode étudiant'),
                  ),
                ],
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

    // Le sélecteur ne propose que des jours de semaine (APP-122). L'alternance
    // se raisonne en semaines et le backend ramène toute date au lundi de sa
    // semaine : griser samedi/dimanche évite qu'un dimanche choisi par erreur
    // fasse « reculer » la date de début à la semaine d'avant.
    bool estJourSemaine(DateTime d) =>
        d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;

    // initialDate DOIT être sélectionnable : si on tombe un week-end, on avance
    // au prochain jour de semaine.
    DateTime base = initial ?? now;
    while (!estJourSemaine(base)) {
      base = base.add(const Duration(days: 1));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      selectableDayPredicate: estJourSemaine,
    );
    onPicked(picked);
  }

  @override
  ProfilCreationViewModel viewModelBuilder(BuildContext context) =>
      ProfilCreationViewModel(
          existingProfile: profile, roleAnnulation: roleAnnulation);
}

/// Champ ville avec autocomplétion sur la liste des communes (APP-122).
/// L'utilisateur tape le début du nom et choisit dans la liste filtrée — ou
/// sélectionne directement. Le controller reçoit le nom canonique choisi.
class _VilleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final Future<Iterable<String>> Function(String) rechercher;

  /// Message d'erreur sous le champ (null = pas d'erreur) — APP-122.
  final String? errorText;

  /// true = ville reconnue → ✓ vert à la place de la loupe.
  final bool valide;

  /// Appelé quand une ville est choisie dans la liste (revalide → ✓ direct).
  final VoidCallback? onSelected;

  const _VilleField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.rechercher,
    this.errorText,
    this.valide = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) => rechercher(value.text),
      onSelected: (_) => onSelected?.call(),
      fieldViewBuilder:
          (context, textController, node, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: node,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: valide
                ? const Icon(Icons.check_circle,
                    size: 20, color: AppColors.echange)
                : const Icon(Icons.search, size: 20),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final ville = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(ville),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(ville,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
