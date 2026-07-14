import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import 'logement_detail_viewmodel.dart';

/// Détail d'un logement : carousel photos, caractéristiques,
/// équipements, propriétaire (réputation), disponibilités.
class LogementDetailView extends StackedView<LogementDetailViewModel> {
  final Logement logement;

  const LogementDetailView({super.key, required this.logement});

  @override
  Widget builder(
    BuildContext context,
    LogementDetailViewModel viewModel,
    Widget? child,
  ) {
    final l = viewModel.logement;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${l.type.label} — ${l.ville}')),
      body: SafeArea(
        child: ListView(
          children: [
            // ─── Carousel photos ────────────────────────────
            _PhotoCarousel(photoUrls: l.photoUrls),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Loyer + adresse ────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${l.loyer.toStringAsFixed(0)} €',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                            '/ mois + ${l.charges.toStringAsFixed(0)} € charges',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${l.adresse}, ${l.codePostal} ${l.ville}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),

                  // ─── Caractéristiques ───────────────────────
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _InfoChip(
                          icon: Icons.straighten,
                          label: '${l.surface.toStringAsFixed(0)} m²'),
                      _InfoChip(
                          icon: Icons.meeting_room_outlined,
                          label:
                              '${l.nbPieces} pièce${l.nbPieces > 1 ? 's' : ''}'),
                      _InfoChip(
                          icon: Icons.chair_outlined,
                          label: l.isMeuble ? 'Meublé' : 'Non meublé'),
                      if (l.isVerified)
                        const _InfoChip(
                            icon: Icons.verified_outlined,
                            label: 'Vérifié',
                            color: AppColors.echange),
                    ],
                  ),

                  // ─── Description ────────────────────────────
                  if (l.description != null &&
                      l.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Description',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l.description!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],

                  // ─── Équipements ────────────────────────────
                  if (l.equipements.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Équipements',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: l.equipements
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusChip),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Text(e,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  ],

                  // ─── Propriétaire ───────────────────────────
                  const SizedBox(height: AppSpacing.lg),
                  Text('Propriétaire',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _OwnerCard(viewModel: viewModel),

                  // ─── Disponibilités ─────────────────────────
                  const SizedBox(height: AppSpacing.lg),
                  Text('Disponibilités (4 prochaines semaines)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _DisponibilitesSection(viewModel: viewModel),

                  // Contacter le propriétaire (masqué sur son propre logement)
                  if (viewModel.canContact) ...[
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: viewModel.contacter,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contacter'),
                    ),
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
  LogementDetailViewModel viewModelBuilder(BuildContext context) =>
      LogementDetailViewModel(logement: logement);

  @override
  void onViewModelReady(LogementDetailViewModel viewModel) =>
      viewModel.loadExtras();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _PhotoCarousel extends StatelessWidget {
  final List<String> photoUrls;

  const _PhotoCarousel({required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return Container(
        height: 220,
        color: AppColors.surfaceDark,
        child: const Center(
          child: Icon(Icons.apartment,
              size: 64, color: AppColors.textTertiary),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: photoUrls.length,
        itemBuilder: (context, index) => CachedNetworkImage(
          imageUrl: photoUrls[index],
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            color: AppColors.surfaceDark,
            child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.echange, strokeWidth: 2)),
          ),
          errorWidget: (_, _, _) => Container(
            color: AppColors.surfaceDark,
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.textTertiary),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon,
      required this.label,
      this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final LogementDetailViewModel viewModel;

  const _OwnerCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final rep = viewModel.reputation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceDark,
            child: Icon(Icons.person_outline, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: rep == null
                ? Text('Propriétaire',
                    style: Theme.of(context).textTheme.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < rep.avgRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: AppColors.chevauchement,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${rep.avgRating.toStringAsFixed(1)} (${rep.totalReviews} avis)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.echangeLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusChip),
                        ),
                        child: Text(rep.badge,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.echange)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DisponibilitesSection extends StatelessWidget {
  final LogementDetailViewModel viewModel;

  const _DisponibilitesSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isBusy) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: CircularProgressIndicator(
            color: AppColors.echange, strokeWidth: 2),
      ));
    }

    final dispos = viewModel.prochainesDisponibilites;
    if (dispos.isEmpty) {
      return Text('Aucune plage renseignée.',
          style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      children: dispos.map((d) {
        final (color, bg) = switch (d.type) {
          DisponibiliteType.LIBRE => (
              AppColors.echange,
              AppColors.echangeLight
            ),
          DisponibiliteType.OCCUPE => (AppColors.error, AppColors.errorLight),
          DisponibiliteType.BLOQUE => (
              AppColors.textSecondary,
              AppColors.surfaceDark
            ),
        };
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '${DateFormat('dd/MM').format(d.dateDebut)} → '
                '${DateFormat('dd/MM').format(d.dateFin)}',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Text(d.type.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
