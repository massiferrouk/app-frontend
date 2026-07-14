import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/matching_suggestion.dart';
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenPadding),
            child: Center(
              child: Text(
                '${s.scorePercent}%',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.echange),
              ),
            ),
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
              ElevatedButton.icon(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _showProposerSheet(context, viewModel),
                icon: const Icon(Icons.handshake_outlined),
                label: Text('Proposer un ${s.typePropose.label.toLowerCase()}'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Tuiles chiffrées ───────────────────────────────
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
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      value: s.nbSemainesColocation,
                      label: s.nbSemainesColocation > 1 ? 'colocs' : 'coloc',
                      color: AppColors.colocation,
                      background: AppColors.colocationLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      value: s.nbSemainesChevauchement,
                      label: 'à gérer',
                      color: AppColors.chevauchement,
                      background: AppColors.chevauchementLight,
                    ),
                  ),
                ],
              ),
            ),

            // ─── En-tête de colonnes Toi | Lui ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: _ColonnesHeader(autreNom: s.displayName),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),

            // ─── Semaines ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  for (final entry in groupes.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ),
                    ...entry.value.map((sem) => _SemaineRow(
                          semaine: sem,
                          onTap: () =>
                              _showDetailSheet(context, viewModel, sem),
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

// ─── Widgets internes ─────────────────────────────────────────────

/// Tuile chiffrée du header : gros nombre + label court
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color background;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Une stat à zéro reste visible mais grisée : l'absence est une info
    final actif = value > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: actif ? background : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
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
    );
  }
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
class _SemaineRow extends StatelessWidget {
  final SemaineCompatibilite semaine;
  final VoidCallback onTap;

  const _SemaineRow({required this.semaine, required this.onTap});

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
        padding:
            const EdgeInsets.symmetric(vertical: 7, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8)),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(date,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent)),
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
        _LegendeItem(color: AppColors.chevauchement, label: 'À gérer entre vous'),
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
