import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/semaine_compatibilite.dart';
import 'compatibilite_viewmodel.dart';

/// Calendrier de compatibilité — vue semaine par semaine entre
/// l'utilisateur connecté et un match.
/// VERT = échange, BLEU = colocation, ORANGE = chevauchement, GRIS = rien.
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
      appBar: AppBar(title: const Text('Compatibilité')),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header duo + résumé ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _MiniProfile(initials: 'Moi', name: 'Toi'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Icon(Icons.swap_horiz,
                            color: AppColors.echange, size: 28),
                      ),
                      _MiniProfile(
                          initials: s.initials, name: s.displayName),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (s.nbSemainesEchange > 0)
                              _SummaryChip(
                                label: '${s.nbSemainesEchange} sem. échange',
                                color: AppColors.echange,
                                background: AppColors.echangeLight,
                              ),
                            if (s.nbSemainesColocation > 0)
                              _SummaryChip(
                                label: '${s.nbSemainesColocation} sem. coloc',
                                color: AppColors.colocation,
                                background: AppColors.colocationLight,
                              ),
                            if (s.nbSemainesChevauchement > 0)
                              _SummaryChip(
                                label:
                                    '${s.nbSemainesChevauchement} sem. chevauchement',
                                color: AppColors.chevauchement,
                                background: AppColors.chevauchementLight,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${s.scorePercent}%',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.echange),
                      ),
                    ],
                  ),
                  if (s.messageResume != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      s.messageResume!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // ─── Semaines ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  for (final entry in groupes.entries) ...[
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ),
                    ...entry.value.map((sem) => _SemaineCompatCard(
                          semaine: sem,
                          note: viewModel.noteFor(sem),
                        )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  CompatibiliteViewModel viewModelBuilder(BuildContext context) =>
      CompatibiliteViewModel(suggestion: suggestion);
}

// ─── Widgets internes ─────────────────────────────────────────────

class _MiniProfile extends StatelessWidget {
  final String initials;
  final String name;

  const _MiniProfile({required this.initials, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surfaceDark,
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.background,
  });

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

/// Carte d'une semaine de compatibilité — fond teinté selon le type
class _SemaineCompatCard extends StatelessWidget {
  final SemaineCompatibilite semaine;
  final String note;

  const _SemaineCompatCard({required this.semaine, required this.note});

  (Color bg, Color accent, IconData? icon) get _style =>
      switch (semaine.type) {
        CompatibiliteType.ECHANGE => (
            AppColors.echangeLight,
            AppColors.echange,
            Icons.check_circle_outline
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

  @override
  Widget build(BuildContext context) {
    final (bg, accent, icon) = _style;
    final dates = DateFormat('dd/MM').format(semaine.semaine);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(dates,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (semaine.label.isNotEmpty)
                      Text(semaine.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    const Spacer(),
                    // Les deux villes : Toi → / ← Lui
                    Text(
                      'Toi : ${semaine.villeAlternantA} · '
                      '${semaine.villeAlternantB}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (note.isNotEmpty)
                  Text(note,
                      style: TextStyle(
                          fontSize: 11, color: accent)),
              ],
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, size: 18, color: accent),
          ],
        ],
      ),
    );
  }
}
