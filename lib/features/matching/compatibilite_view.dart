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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () => _showProposerSheet(context, viewModel),
            icon: const Icon(Icons.handshake_outlined),
            label: Text('Proposer un ${s.typePropose.label.toLowerCase()}'),
          ),
        ),
      ),
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

  /// Bottom sheet de proposition d'accord : dates + message
  Future<void> _showProposerSheet(
      BuildContext context, CompatibiliteViewModel viewModel) async {
    final result = await showModalBottomSheet<
        ({DateTime debut, DateTime fin, String? message})>(
      context: context,
      isScrollControlled: true, // laisse la place au clavier
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ProposerAccordSheet(
          typeLabel: viewModel.suggestion.typePropose.label),
    );
    if (result == null) return;

    final error = await viewModel.proposerAccord(
      dateDebut: result.debut,
      dateFin: result.fin,
      message: result.message,
    );

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
}

// ─── Bottom sheet de proposition ──────────────────────────────────

class _ProposerAccordSheet extends StatefulWidget {
  final String typeLabel;

  const _ProposerAccordSheet({required this.typeLabel});

  @override
  State<_ProposerAccordSheet> createState() => _ProposerAccordSheetState();
}

class _ProposerAccordSheetState extends State<_ProposerAccordSheet> {
  DateTime? _debut;
  DateTime? _fin;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDebut) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _debut : _fin) ??
          now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)), // @Future côté backend
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => isDebut ? _debut = picked : _fin = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _debut != null && _fin != null;

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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _dateButton('Début', _debut, () => _pickDate(true))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _dateButton('Fin', _fin, () => _pickDate(false))),
              ],
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
              onPressed: ready
                  ? () => Navigator.pop(context, (
                        debut: _debut!,
                        fin: _fin!,
                        message: _messageController.text.trim().isEmpty
                            ? null
                            : _messageController.text.trim(),
                      ))
                  : null,
              child: const Text('Envoyer la demande'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            Text(
              value == null
                  ? 'Choisir…'
                  : DateFormat('dd/MM/yyyy').format(value),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null
                      ? AppColors.textTertiary
                      : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
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
