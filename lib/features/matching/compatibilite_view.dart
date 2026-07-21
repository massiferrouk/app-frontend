import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/scenario.dart';
import '../../shared/models/semaine_compatibilite.dart';
import 'compatibilite_viewmodel.dart';

/// Calendrier de compatibilité (refonte APP-100).
/// Lecture en deux colonnes « Toi | {prénom} » : une pastille ville par
/// personne et par semaine. Le texte explicatif vit dans une légende fixe
/// et une bottom sheet au tap — plus jamais répété sur les cartes.
class CompatibiliteView extends StackedView<CompatibiliteViewModel> {
  final MatchingSuggestion suggestion;

  const CompatibiliteView({super.key, required this.suggestion});

  @override
  Widget builder(
    BuildContext context,
    CompatibiliteViewModel viewModel,
    Widget? child,
  ) {
    final s = viewModel.suggestion;
    final groupes = viewModel.semainesParMois;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compatibilité'),
        actions: [
          // Cycle les 3 vues : liste → annuel → mensuel (expérim. APP-100)
          IconButton(
            onPressed: viewModel.cyclerVue,
            tooltip: switch (viewModel.vue) {
              VueCompat.liste => 'Vue calendrier annuel',
              VueCompat.annuel => 'Vue blocs mensuels',
              VueCompat.mensuel => 'Vue liste',
            },
            icon: Icon(switch (viewModel.vue) {
              VueCompat.liste => Icons.calendar_view_month_outlined,
              VueCompat.annuel => Icons.calendar_month_outlined,
              VueCompat.mensuel => Icons.view_list_outlined,
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenPadding),
            child: Center(child: _ScoreRing(percent: s.scorePercent)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Legende(),
              const SizedBox(height: AppSpacing.sm),
              // Action PRINCIPALE : la messagerie. Décision produit
              // « messagerie-first » : l'app informe, tout se règle ensuite
              // entre les deux personnes dans le chat. L'accord n'est plus le
              // passage obligé.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: viewModel.isBusy ? null : viewModel.contacter,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                ),
              ),
              // Action SECONDAIRE, optionnelle et volontairement discrète :
              // formaliser l'échange/coloc. Elle sert surtout à débloquer les
              // avis + le calcul des économies pour ceux qui concluent vraiment.
              TextButton.icon(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _showProposerSheet(context, viewModel),
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: Text('Formaliser un ${s.typePropose.label.toLowerCase()}'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnTete(viewModel: viewModel),

            // ─── En-tête de colonnes Toi | Lui ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: _ColonnesHeader(autreNom: s.displayName),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),

            // ─── Semaines : liste, calendrier annuel ou mensuel ──
            if (viewModel.vue == VueCompat.annuel)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: _CalendrierAnnuel(
                    groupes: viewModel.semainesParMoisCompletes,
                    filtre: viewModel.filtre,
                    isCourante: viewModel.isSemaineCourante,
                    onTapSemaine: (sem) =>
                        _showDetailSheet(context, viewModel, sem),
                  ),
                ),
              )
            else if (viewModel.vue == VueCompat.mensuel)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: _CalendrierMensuel(
                    groupes: viewModel.semainesParMoisCompletes,
                    filtre: viewModel.filtre,
                    isCourante: viewModel.isSemaineCourante,
                    onTapSemaine: (sem) =>
                        _showDetailSheet(context, viewModel, sem),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: CustomScrollView(
                    controller: viewModel.scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                          child: SizedBox(
                              height: CompatibiliteViewModel.topGap)),
                      for (final entry in groupes.entries)
                        SliverMainAxisGroup(
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _MoisHeaderDelegate(entry.key),
                            ),
                            SliverFixedExtentList(
                              itemExtent: CompatibiliteViewModel.rowExtent,
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _SemaineRow(
                                  semaine: entry.value[i],
                                  courante: viewModel
                                      .isSemaineCourante(entry.value[i]),
                                  onTap: () => _showDetailSheet(
                                      context, viewModel, entry.value[i]),
                                ),
                                childCount: entry.value.length,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(
                                    height: CompatibiliteViewModel.groupGap)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet de détail d'une semaine : type, explication complète.
  void _showDetailSheet(BuildContext context, CompatibiliteViewModel viewModel,
      SemaineCompatibilite semaine) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SemaineDetailSheet(
        semaine: semaine,
        autreNom: viewModel.suggestion.displayName,
        explication: viewModel.explicationFor(semaine.type),
      ),
    );
  }

  /// Bottom sheet de proposition d'accord : message uniquement.
  /// Pas de dates : l'app met en relation, l'organisation est laissée aux
  /// deux utilisateurs (période déduite automatiquement côté backend).
  Future<void> _showProposerSheet(
      BuildContext context, CompatibiliteViewModel viewModel) async {
    final result = await showModalBottomSheet<({String? message})>(
      context: context,
      isScrollControlled: true, // laisse la place au clavier
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ProposerAccordSheet(
          typeLabel: viewModel.suggestion.typePropose.label),
    );
    if (result == null) return;

    final error = await viewModel.proposerAccord(message: result.message);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ??
            'Demande envoyée ! Elle expire dans 72h sans réponse.'),
        backgroundColor: error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  CompatibiliteViewModel viewModelBuilder(BuildContext context) =>
      CompatibiliteViewModel(suggestion: suggestion);

  @override
  void onViewModelReady(CompatibiliteViewModel viewModel) {
    // Attend le premier frame : le ScrollController doit être attaché
    // à la liste avant de pouvoir calculer l'offset.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => viewModel.scrollToSemaineCourante());
  }
}

/// En-tête de l'écran compatibilité : les tuiles chiffrées, puis UNE barre
/// qui résume la situation et ouvre les options.
///
/// APP-120 : « Vos options » vivait ici, en pleine hauteur, et repoussait le
/// calendrier jusqu'à le rendre inutilisable. Or le calendrier est le cœur de
/// l'écran — les options se consultent une fois, le calendrier se parcourt.
/// Elles sont donc passées dans une bottom sheet, où elles ont toute la place.
class _EnTete extends StatelessWidget {
  final CompatibiliteViewModel viewModel;

  const _EnTete({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final s = viewModel.suggestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      // ─── Tuiles chiffrées (tap = filtre) ────────────────
      Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                value: s.nbSemainesEchange,
                label: s.nbSemainesEchange > 1 ? 'échanges' : 'échange',
                color: AppColors.echange,
                background: AppColors.echangeLight,
                selected: viewModel.filtre == CompatibiliteType.ECHANGE,
                dimmed: viewModel.filtre != null &&
                    viewModel.filtre != CompatibiliteType.ECHANGE,
                onTap: () =>
                    viewModel.toggleFiltre(CompatibiliteType.ECHANGE),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                value: s.nbSemainesColocation,
                label: s.nbSemainesColocation > 1 ? 'colocs' : 'coloc',
                color: AppColors.colocation,
                background: AppColors.colocationLight,
                selected:
                    viewModel.filtre == CompatibiliteType.COLOCATION,
                dimmed: viewModel.filtre != null &&
                    viewModel.filtre != CompatibiliteType.COLOCATION,
                onTap: () =>
                    viewModel.toggleFiltre(CompatibiliteType.COLOCATION),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                // Semaines neutres = chacun chez soi (APP-108).
                // Calculé depuis la liste : total - échange - coloc.
                value: s.semaines.length -
                    s.nbSemainesEchange -
                    s.nbSemainesColocation,
                label: 'chacun chez soi',
                color: AppColors.textSecondary,
                background: AppColors.surfaceDark,
                selected:
                    viewModel.filtre == CompatibiliteType.INCOMPATIBLE,
                dimmed: viewModel.filtre != null &&
                    viewModel.filtre != CompatibiliteType.INCOMPATIBLE,
                onTap: () => viewModel
                    .toggleFiltre(CompatibiliteType.INCOMPATIBLE),
              ),
            ),
          ],
        ),
      ),

        // ─── Barre de synthèse : économie + accès aux options ──
        if (s.scenarios.isNotEmpty || s.hasEconomie)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                AppSpacing.screenPadding, AppSpacing.md),
            child: _BarreOptions(viewModel: viewModel),
          )
        else if (s.logementBId == null)
          // Repli : SON logement manque, rien à proposer pour l'instant
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                AppSpacing.screenPadding, AppSpacing.md),
            child: Text(
              '${s.displayName} n\'a pas encore publié son logement',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// Barre unique de synthèse (APP-120) — remplace la bannière d'économie ET le
/// bloc « Vos options ». Une ligne : le gain qui donne envie, le nombre
/// d'options, un chevron. Cliquable seulement s'il y a des options à montrer.
class _BarreOptions extends StatelessWidget {
  final CompatibiliteViewModel viewModel;

  const _BarreOptions({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final s = viewModel.suggestion;
    final nbOptions = s.scenarios.length;
    final cliquable = nbOptions > 0;

    // Le gain mis en avant : celui du match s'il est chiffré, sinon le plus
    // élevé parmi les options. Jamais de chiffre inventé : 0 = on n'affiche rien.
    final meilleurGain = s.hasEconomie
        ? s.economieMensuelle
        : s.scenarios.fold<int>(
            0,
            (max, sc) =>
                sc.economieMensuelle > max ? sc.economieMensuelle : max);

    final coloc = s.typePropose == AccordType.COLOCATION_TOURNANTE;
    final accent = coloc ? AppColors.colocation : AppColors.echange;
    final fond = coloc ? AppColors.colocationLight : AppColors.echangeLight;

    return Material(
      color: fond,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        onTap: cliquable ? () => _ouvrirOptions(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(cliquable ? Icons.lightbulb_outline : Icons.savings_outlined,
                  size: 20, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cliquable
                          ? (nbOptions > 1
                              ? '$nbOptions options pour économiser'
                              : 'Une option pour économiser')
                          : 'Économie estimée',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                    if (meilleurGain > 0)
                      Text('jusqu\'à $meilleurGain €/mois',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (cliquable)
                Icon(Icons.chevron_right, size: 20, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre les options dans une feuille — elles y ont toute la hauteur
  /// nécessaire, sans jamais empiéter sur le calendrier.
  void _ouvrirOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _OptionsSheet(viewModel: viewModel),
    );
  }
}

/// Feuille des options d'arrangement (APP-120).
class _OptionsSheet extends StatelessWidget {
  final CompatibiliteViewModel viewModel;

  const _OptionsSheet({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final s = viewModel.suggestion;

    return SafeArea(
      child: ConstrainedBox(
        // Jamais plein écran : on garde le calendrier visible derrière
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
              AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Vos options avec ${s.displayName}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              // Les actions ferment la feuille avant de naviguer
              for (final sc in s.scenarios)
                _ScenarioCard(
                  scenario: sc,
                  onPublier: () {
                    Navigator.pop(context);
                    viewModel.publierLogement();
                  },
                  onContacter: () {
                    Navigator.pop(context);
                    viewModel.contacter();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Style par type de semaine ────────────────────────────────────

(Color bg, Color accent, IconData? icon) styleFor(CompatibiliteType type) =>
    switch (type) {
      CompatibiliteType.ECHANGE => (
          AppColors.echangeLight,
          AppColors.echange,
          Icons.swap_horiz
        ),
      CompatibiliteType.COLOCATION => (
          AppColors.colocationLight,
          AppColors.colocation,
          Icons.group_outlined
        ),
      CompatibiliteType.CHEVAUCHEMENT => (
          AppColors.chevauchementLight,
          AppColors.chevauchement,
          Icons.warning_amber_outlined
        ),
      CompatibiliteType.INCOMPATIBLE => (
          AppColors.surface,
          AppColors.textTertiary,
          null
        ),
    };

// ─── Vues calendrier alternatives (expérimentation APP-100) ───────
// Deux affichages en plus de la liste, bascule via l'icône de l'AppBar.
// Objectif : les tester auprès d'étudiants pour en retenir deux.

/// Vue calendrier annuel (variante A) : un rang par mois, une case
/// colorée par semaine. Toute l'alternance visible d'un coup — le détail
/// est au tap, comme la vue liste.
class _CalendrierAnnuel extends StatelessWidget {
  final Map<String, List<SemaineCompatibilite>> groupes;
  final CompatibiliteType? filtre;
  final bool Function(SemaineCompatibilite) isCourante;
  final void Function(SemaineCompatibilite) onTapSemaine;

  const _CalendrierAnnuel({
    required this.groupes,
    required this.filtre,
    required this.isCourante,
    required this.onTapSemaine,
  });

  /// Couleur pleine d'une case selon le type
  static Color _couleur(CompatibiliteType type) => switch (type) {
        CompatibiliteType.ECHANGE => AppColors.echange,
        CompatibiliteType.COLOCATION => AppColors.colocation,
        CompatibiliteType.CHEVAUCHEMENT => AppColors.chevauchement,
        CompatibiliteType.INCOMPATIBLE => AppColors.surfaceDark,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groupes.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                // Label mois abrégé ("Sept. 2026" → "Sept.")
                SizedBox(
                  width: 64,
                  child: Text(
                    entry.key.split(' ').first,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                // Une case tappable par semaine du mois
                Expanded(
                  child: Row(
                    children: [
                      for (final sem in entry.value)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _CaseSemaine(
                              semaine: sem,
                              couleur: _couleur(sem.type),
                              courante: isCourante(sem),
                              estompee:
                                  filtre != null && sem.type != filtre,
                              onTap: () => onTapSemaine(sem),
                            ),
                          ),
                        ),
                      // Complète à 5 cases pour aligner les mois courts
                      for (var i = entry.value.length; i < 5; i++)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Case d'une semaine dans le calendrier annuel
class _CaseSemaine extends StatelessWidget {
  final SemaineCompatibilite semaine;
  final Color couleur;
  final bool courante;
  final bool estompee;
  final VoidCallback onTap;

  const _CaseSemaine({
    required this.semaine,
    required this.couleur,
    required this.courante,
    required this.estompee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: estompee ? 0.2 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(6),
            border: courante
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : null,
          ),
          // Jour du mois : donne un repère de date sans surcharger
          child: Text(
            '${semaine.semaine.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: semaine.type == CompatibiliteType.INCOMPATIBLE
                  ? AppColors.textTertiary
                  : AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vue blocs mensuels (variante B) : une carte par mois, 2 par ligne,
/// une bande colorée par semaine. Chaque carte affiche le décompte du
/// mois (« 3 éch · 1 coloc »).
class _CalendrierMensuel extends StatelessWidget {
  final Map<String, List<SemaineCompatibilite>> groupes;
  final CompatibiliteType? filtre;
  final bool Function(SemaineCompatibilite) isCourante;
  final void Function(SemaineCompatibilite) onTapSemaine;

  const _CalendrierMensuel({
    required this.groupes,
    required this.filtre,
    required this.isCourante,
    required this.onTapSemaine,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2 cartes par ligne, hauteur libre (les mois font 4 ou 5 semaines)
        final largeurCarte = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in groupes.entries)
              SizedBox(
                width: largeurCarte,
                child: _MoisCard(
                  label: entry.key,
                  semaines: entry.value,
                  filtre: filtre,
                  isCourante: isCourante,
                  onTapSemaine: onTapSemaine,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Carte d'un mois : en-tête (nom + décompte) et bandes semaine
class _MoisCard extends StatelessWidget {
  final String label;
  final List<SemaineCompatibilite> semaines;
  final CompatibiliteType? filtre;
  final bool Function(SemaineCompatibilite) isCourante;
  final void Function(SemaineCompatibilite) onTapSemaine;

  const _MoisCard({
    required this.label,
    required this.semaines,
    required this.filtre,
    required this.isCourante,
    required this.onTapSemaine,
  });

  /// Décompte court du mois, ex. « 3 éch · 1 coloc »
  String get _resume {
    final ech =
        semaines.where((s) => s.type == CompatibiliteType.ECHANGE).length;
    final coloc =
        semaines.where((s) => s.type == CompatibiliteType.COLOCATION).length;
    final chev = semaines
        .where((s) => s.type == CompatibiliteType.CHEVAUCHEMENT)
        .length;
    final parts = [
      if (ech > 0) '$ech éch',
      if (coloc > 0) '$coloc coloc',
      if (chev > 0) '$chev à gérer',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
              Expanded(
                child: Text(
                  // « Septembre 2026 » → « Septembre » (l'année est évidente)
                  label.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              // Flexible : le décompte peut être long (« 3 éch · 1 coloc ·
              // 2 à gérer ») et la carte ne fait qu'une demi-largeur (APP-120)
              Flexible(
                child: Text(_resume,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final sem in semaines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => onTapSemaine(sem),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${sem.semaine.day}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textTertiary)),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity:
                            filtre != null && sem.type != filtre ? 0.2 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: _CalendrierAnnuel._couleur(sem.type),
                            borderRadius: BorderRadius.circular(4),
                            border: isCourante(sem)
                                ? Border.all(
                                    color: AppColors.textPrimary, width: 2)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────

/// Carte d'un scénario d'arrangement (section « Vos options », APP-109) :
/// icône selon le type, message du moteur, économie et bouton d'action.
class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onPublier;
  final VoidCallback onContacter;

  const _ScenarioCard({
    required this.scenario,
    required this.onPublier,
    required this.onContacter,
  });

  IconData get _icon => switch (scenario.type) {
        'RELAIS' => Icons.autorenew,
        'REEQUILIBRER' => Icons.balance_outlined,
        'COLOC_UNE_VILLE' => Icons.group_outlined,
        'TON_LOGEMENT_MANQUE' || 'AUCUN_LOGEMENT' => Icons.add_home_outlined,
        'SON_LOGEMENT_MANQUE' => Icons.chat_bubble_outline,
        _ => Icons.lightbulb_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 20, color: AppColors.echange),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(scenario.message,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (scenario.hasEconomie)
                Text('≈ ${scenario.economieMensuelle} €/mois économisés',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.echange)),
              const Spacer(),
              if (scenario.action == ScenarioAction.publierLogement)
                TextButton.icon(
                  onPressed: onPublier,
                  icon: const Icon(Icons.add_home_outlined, size: 16),
                  label: const Text('Publier mon logement',
                      style: TextStyle(fontSize: 12)),
                )
              else if (scenario.action == ScenarioAction.contacter)
                TextButton.icon(
                  onPressed: onContacter,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('En discuter',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Anneau de progression autour du score (AppBar)
class _ScoreRing extends StatelessWidget {
  final int percent;

  const _ScoreRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 3.5,
            color: AppColors.echange,
            backgroundColor: AppColors.echangeLight,
          ),
          Center(
            child: Text('$percent%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.echange)),
          ),
        ],
      ),
    );
  }
}

/// Tuile chiffrée du header : gros nombre + label court.
/// Tap = filtre la liste sur ce type (re-tap pour tout réafficher).
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color background;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Une stat à zéro reste visible mais grisée et non tappable
    final actif = value > 0;
    return InkWell(
      onTap: actif ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      child: AnimatedOpacity(
        opacity: dimmed ? 0.45 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: actif ? background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: actif ? color : AppColors.textTertiary)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: actif ? color : AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header de mois collant : reste affiché en haut pendant le scroll
class _MoisHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;

  const _MoisHeaderDelegate(this.label);

  @override
  double get minExtent => CompatibiliteViewModel.headerExtent;
  @override
  double get maxExtent => CompatibiliteViewModel.headerExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Fond opaque : les rows glissent dessous sans transparaître
    return Container(
      color: AppColors.background,
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }

  @override
  bool shouldRebuild(covariant _MoisHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

/// En-tête des colonnes : Semaine | Toi | {prénom}
class _ColonnesHeader extends StatelessWidget {
  final String autreNom;

  const _ColonnesHeader({required this.autreNom});

  static const _styleNom = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 52,
          child: Text('Semaine',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ),
        const Expanded(
            child: Center(child: Text('Toi', style: _styleNom))),
        Expanded(
          child: Center(
            child: Text(autreNom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _styleNom),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }
}

/// Row d'une semaine : date + pastille ville par personne + icône type.
/// Coloc/chevauchement (même ville) : pastille fusionnée « ville · ensemble ».
/// [courante] : semaine en cours → bordure pleine pour la repérer d'un œil.
/// Hauteur FIXE (rowExtent) : requise par le calcul d'auto-scroll.
class _SemaineRow extends StatelessWidget {
  final SemaineCompatibilite semaine;
  final bool courante;
  final VoidCallback onTap;

  const _SemaineRow({
    required this.semaine,
    required this.courante,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, accent, icon) = styleFor(semaine.type);
    final date = DateFormat('dd/MM').format(semaine.semaine);
    final memeVille = semaine.villeAlternantA.toLowerCase() ==
        semaine.villeAlternantB.toLowerCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: courante
              ? BorderRadius.circular(8)
              : const BorderRadius.horizontal(right: Radius.circular(8)),
          border: courante
              ? Border.all(color: accent, width: 2)
              : Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                courante ? '● $date' : date,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: accent),
              ),
            ),
            if (memeVille)
              Expanded(
                child: _VillePill(
                    text: '${_cap(semaine.villeAlternantA)} · ensemble'),
              )
            else ...[
              Expanded(
                  child: _VillePill(text: _cap(semaine.villeAlternantA))),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                  child: _VillePill(text: _cap(semaine.villeAlternantB))),
            ],
            SizedBox(
              width: 26,
              child: icon != null
                  ? Icon(icon, size: 16, color: accent)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Première lettre en majuscule (les villes arrivent en minuscules du back)
  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Pastille blanche affichant une ville
class _VillePill extends StatelessWidget {
  final String text;

  const _VillePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Légende fixe sous la liste : un point coloré par type
class _Legende extends StatelessWidget {
  const _Legende();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: [
        _LegendeItem(color: AppColors.echange, label: 'Échange de logements'),
        _LegendeItem(color: AppColors.colocation, label: 'Même ville, coloc'),
        _LegendeItem(color: AppColors.textTertiary, label: 'Chacun chez soi'),
      ],
    );
  }
}

class _LegendeItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendeItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Bottom sheet de détail d'une semaine (tap sur une row)
class _SemaineDetailSheet extends StatelessWidget {
  final SemaineCompatibilite semaine;
  final String autreNom;
  final String explication;

  const _SemaineDetailSheet({
    required this.semaine,
    required this.autreNom,
    required this.explication,
  });

  static const _mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, accent, icon) = styleFor(semaine.type);
    final d = semaine.semaine;
    final date = '${d.day} ${_mois[d.month - 1]} ${d.year}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusButton),
                    ),
                    child: Icon(icon, size: 20, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semaine.label.isNotEmpty
                            ? semaine.label
                            : 'Semaine neutre',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accent),
                      ),
                      Text('Semaine du $date',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Qui est où cette semaine
            Row(
              children: [
                Expanded(
                  child: _PositionCard(
                      nom: 'Toi', ville: semaine.villeAlternantA),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PositionCard(
                      nom: autreNom, ville: semaine.villeAlternantB),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text(explication,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Petite carte « qui est où » dans la bottom sheet
class _PositionCard extends StatelessWidget {
  final String nom;
  final String ville;

  const _PositionCard({required this.nom, required this.ville});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      child: Column(
        children: [
          Text(nom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(_SemaineRow._cap(ville),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Bottom sheet de proposition ──────────────────────────────────

class _ProposerAccordSheet extends StatefulWidget {
  final String typeLabel;

  const _ProposerAccordSheet({required this.typeLabel});

  @override
  State<_ProposerAccordSheet> createState() => _ProposerAccordSheetState();
}

class _ProposerAccordSheetState extends State<_ProposerAccordSheet> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Remonte le sheet au-dessus du clavier
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Proposer un ${widget.typeLabel.toLowerCase()}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vous entrez en contact. Vous organisez ensuite les détails '
              'entre vous — l\'app ne fixe pas les dates.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                  hintText: 'Message (optionnel)', counterText: ''),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, (
                    message: _messageController.text.trim().isEmpty
                        ? null
                        : _messageController.text.trim(),
                  )),
              child: const Text('Envoyer la demande'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
