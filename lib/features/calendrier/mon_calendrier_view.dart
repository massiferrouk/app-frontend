import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/mes_semaines.dart';
import '../../shared/widgets/semaine_card.dart';
import 'mon_calendrier_viewmodel.dart';

/// Mon calendrier d'alternance (refonte APP-118) — deux affichages :
/// liste verticale (mois collants + auto-scroll sur la semaine en cours)
/// et calendrier annuel (heatmap). Bandeau « cette semaine / la prochaine »
/// en tête, override d'une semaine au tap.
class MonCalendrierView extends StackedView<MonCalendrierViewModel> {
  const MonCalendrierView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MonCalendrierViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon calendrier'),
        actions: [
          // Bascule liste ⇄ calendrier annuel (dispo une fois chargé)
          if (viewModel.data != null)
            IconButton(
              onPressed: viewModel.cyclerVue,
              tooltip: viewModel.vue == VueCalendrier.liste
                  ? 'Vue calendrier annuel'
                  : 'Vue liste',
              icon: Icon(viewModel.vue == VueCalendrier.liste
                  ? Icons.calendar_view_month_outlined
                  : Icons.view_list_outlined),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, MonCalendrierViewModel viewModel) {
    if (viewModel.isBusy && viewModel.data == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.data == null) {
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

    final data = viewModel.data!;
    final courante = viewModel.semaineCourante;
    final prochaine = viewModel.semaineProchaine;
    final hasBandeau = courante != null || prochaine != null;

    return Column(
      children: [
        // ─── Zone fixe : bandeau « maintenant » + résumé rythme ──
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
              AppSpacing.screenPadding, AppSpacing.screenPadding, 0),
          child: Column(
            children: [
              if (hasBandeau) ...[
                _BandeauMaintenant(
                  courante: courante,
                  prochaine: prochaine,
                  data: data,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _RythmeSummary(data: data),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ─── Zone défilante : liste ou calendrier annuel ─────────
        Expanded(
          child: viewModel.vue == VueCalendrier.annuel
              ? _buildAnnuel(context, viewModel, data)
              : _buildListe(context, viewModel, data),
        ),
      ],
    );
  }

  /// Liste verticale : en-têtes de mois collants, cartes à hauteur fixe
  /// (requise par l'auto-scroll), pull-to-refresh.
  Widget _buildListe(
      BuildContext context, MonCalendrierViewModel viewModel, MesSemaines data) {
    final groupes = viewModel.semainesParMois;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: CustomScrollView(
          controller: viewModel.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
                child: SizedBox(height: MonCalendrierViewModel.topGap)),
            for (final entry in groupes.entries)
              SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _MoisHeaderDelegate(entry.key),
                  ),
                  SliverFixedExtentList(
                    itemExtent: MonCalendrierViewModel.rowExtent,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final s = entry.value[i];
                        return SemaineCard(
                          semaine: s,
                          ville: data.villeFor(s.label),
                          modifiable: viewModel.isModifiable(s),
                          courante: viewModel.isSemaineCourante(s),
                          onTap: () => _showOverrideSheet(context, viewModel, s),
                        );
                      },
                      childCount: entry.value.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: MonCalendrierViewModel.groupGap)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Calendrier annuel (heatmap) : un rang par mois, une case par semaine
  /// (foncé = ville d'école, gris = ville d'entreprise).
  Widget _buildAnnuel(
      BuildContext context, MonCalendrierViewModel viewModel, MesSemaines data) {
    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: _CalendrierAnnuelPerso(
          groupes: viewModel.semainesParMois,
          data: data,
          isCourante: viewModel.isSemaineCourante,
          isModifiable: viewModel.isModifiable,
          onTapSemaine: (s) => _showOverrideSheet(context, viewModel, s),
        ),
      ),
    );
  }

  /// Bottom sheet de modification d'une semaine (label + raison)
  Future<void> _showOverrideSheet(
    BuildContext context,
    MonCalendrierViewModel viewModel,
    AlternanceSemaine semaine,
  ) async {
    // Sécurité : une semaine passée n'est pas modifiable
    if (!viewModel.isModifiable(semaine)) return;

    final result = await showModalBottomSheet<({String label, String reason})>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OverrideSheet(
        semaine: semaine,
        villeA: viewModel.data!.villeA,
        villeB: viewModel.data!.villeB,
      ),
    );

    if (result == null) return;

    final error = await viewModel.modifierSemaine(
      semaine: semaine,
      label: result.label,
      reason: result.reason,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Semaine modifiée ✓'),
        backgroundColor:
            error == null ? AppColors.echange : AppColors.error,
      ));
    }
  }

  @override
  MonCalendrierViewModel viewModelBuilder(BuildContext context) =>
      MonCalendrierViewModel();

  @override
  void onViewModelReady(MonCalendrierViewModel viewModel) async {
    await viewModel.load();
    // Après le chargement et le premier frame de la liste, on se place
    // sur la semaine en cours (le ScrollController doit être attaché).
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => viewModel.scrollToSemaineCourante());
  }
}

// ─── Bandeau « cette semaine / la prochaine » (APP-118) ───────────

class _BandeauMaintenant extends StatelessWidget {
  final AlternanceSemaine? courante;
  final AlternanceSemaine? prochaine;
  final MesSemaines data;

  const _BandeauMaintenant({
    required this.courante,
    required this.prochaine,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Cas 1 : alternance en cours → cette semaine + la prochaine
    if (courante != null) {
      return Row(
        children: [
          Expanded(
            child: _NowCard(
              titre: 'CETTE SEMAINE',
              semaine: courante!,
              ville: data.villeFor(courante!.label),
              actuel: true,
            ),
          ),
          if (prochaine != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NowCard(
                titre: 'LA SEMAINE PROCHAINE',
                semaine: prochaine!,
                ville: data.villeFor(prochaine!.label),
                actuel: false,
              ),
            ),
          ],
        ],
      );
    }

    // Cas 2 : alternance pas encore commencée → seule la prochaine
    return _NowCard(
      titre: 'PROCHAINE SEMAINE',
      semaine: prochaine!,
      ville: data.villeFor(prochaine!.label),
      actuel: false,
    );
  }
}

/// Mini-carte du bandeau : ville + école/entreprise, accent selon le lieu
class _NowCard extends StatelessWidget {
  final String titre;
  final AlternanceSemaine semaine;
  final String ville;
  final bool actuel;

  const _NowCard({
    required this.titre,
    required this.semaine,
    required this.ville,
    required this.actuel,
  });

  @override
  Widget build(BuildContext context) {
    final style = styleSemaineLieu(semaine.label);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: actuel ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
            color: actuel ? AppColors.textPrimary : AppColors.border,
            width: actuel ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(style.icon, size: 16, color: style.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ville.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(style.tag,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: style.color)),
        ],
      ),
    );
  }
}

// ─── Résumé du rythme en tête d'écran ─────────────────────────────

class _RythmeSummary extends StatelessWidget {
  final MesSemaines data;

  const _RythmeSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final partA = data.partVilleA;
    final pctA = (partA * 100).round();
    final ecole = styleSemaineLieu('A');
    final entreprise = styleSemaineLieu('B');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rythme ${data.rythme.label}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          // Barre bicolore : proportion école (bleu) / entreprise (vert)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: pctA,
                  child: Container(height: 8, color: ecole.color),
                ),
                Expanded(
                  flex: 100 - pctA,
                  child: Container(height: 8, color: entreprise.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${data.villeA} $pctA% · ${data.villeB} ${100 - pctA}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Header de mois collant ───────────────────────────────────────

class _MoisHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;

  const _MoisHeaderDelegate(this.label);

  @override
  double get minExtent => MonCalendrierViewModel.headerExtent;
  @override
  double get maxExtent => MonCalendrierViewModel.headerExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Fond opaque : les cartes glissent dessous sans transparaître
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

// ─── Vue calendrier annuel (heatmap) ──────────────────────────────

class _CalendrierAnnuelPerso extends StatelessWidget {
  final Map<String, List<AlternanceSemaine>> groupes;
  final MesSemaines data;
  final bool Function(AlternanceSemaine) isCourante;
  final bool Function(AlternanceSemaine) isModifiable;
  final void Function(AlternanceSemaine) onTapSemaine;

  const _CalendrierAnnuelPerso({
    required this.groupes,
    required this.data,
    required this.isCourante,
    required this.isModifiable,
    required this.onTapSemaine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Légende en tête : ce que chaque couleur veut dire (guidage)
        _LegendePerso(villeA: data.villeA, villeB: data.villeB),
        const SizedBox(height: AppSpacing.md),
        for (final entry in groupes.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                // Label mois abrégé ("Septembre 2026" → "Sept.")
                SizedBox(
                  width: 56,
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
                      for (final s in entry.value)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _CasePersoSemaine(
                              semaine: s,
                              courante: isCourante(s),
                              modifiable: isModifiable(s),
                              onTap: () => onTapSemaine(s),
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
class _CasePersoSemaine extends StatelessWidget {
  final AlternanceSemaine semaine;
  final bool courante;
  final bool modifiable;
  final VoidCallback onTap;

  const _CasePersoSemaine({
    required this.semaine,
    required this.courante,
    required this.modifiable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = styleSemaineLieu(semaine.label).color;

    return GestureDetector(
      onTap: modifiable ? onTap : null,
      child: Opacity(
        opacity: modifiable ? 1 : 0.55,
        child: Stack(
          children: [
            Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: couleur,
                borderRadius: BorderRadius.circular(6),
                border: courante
                    ? Border.all(color: AppColors.textPrimary, width: 2)
                    : null,
              ),
              child: Text(
                '${semaine.semaine.day}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // Pastille « modifié » (override) en coin
            if (semaine.isOverridden)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.chevauchement,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Légende du calendrier annuel — carte de guidage : chaque couleur est
/// accompagnée de son icône et du nom de la ville (jamais la couleur seule).
class _LegendePerso extends StatelessWidget {
  final String villeA;
  final String villeB;

  const _LegendePerso({required this.villeA, required this.villeB});

  @override
  Widget build(BuildContext context) {
    final ecole = styleSemaineLieu('A');
    final entreprise = styleSemaineLieu('B');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _LegendeItem(
              color: ecole.color, icon: ecole.icon, label: 'École · $villeA'),
          _LegendeItem(
              color: entreprise.color,
              icon: entreprise.icon,
              label: 'Entreprise · $villeB'),
          const _LegendeItem(
              color: AppColors.chevauchement,
              icon: Icons.circle,
              label: 'Semaine modifiée'),
        ],
      ),
    );
  }
}

class _LegendeItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendeItem(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Bottom sheet d'override ──────────────────────────────────────

class _OverrideSheet extends StatefulWidget {
  final AlternanceSemaine semaine;
  final String villeA;
  final String villeB;

  const _OverrideSheet({
    required this.semaine,
    required this.villeA,
    required this.villeB,
  });

  @override
  State<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends State<_OverrideSheet> {
  late String _label = widget.semaine.label;
  String _reason = 'conges';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modifier cette semaine',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),

          // Choix de la ville (label A/B)
          Row(
            children: [
              _labelChip('A', widget.villeA),
              const SizedBox(width: AppSpacing.sm),
              _labelChip('B', widget.villeB),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Raison de la modification
          DropdownButtonFormField<String>(
            initialValue: _reason,
            items: const [
              DropdownMenuItem(value: 'conges', child: Text('Congés')),
              DropdownMenuItem(
                  value: 'rattrapage', child: Text('Rattrapage')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _reason = v ?? 'autre'),
          ),
          const SizedBox(height: AppSpacing.lg),

          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, (label: _label, reason: _reason)),
            child: const Text('Confirmer'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _labelChip(String label, String ville) {
    final selected = _label == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _label = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
                color:
                    selected ? AppColors.textPrimary : AppColors.border),
          ),
          child: Text(
            '$label — $ville',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
