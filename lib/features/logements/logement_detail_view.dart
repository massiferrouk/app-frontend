import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/matching_suggestion.dart';
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

                  // ─── Compatibilité avec l'annonceur (APP-104) ──
                  if (viewModel.matchAnnonceur != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _CompatibiliteCard(
                      suggestion: viewModel.matchAnnonceur!,
                      onTap: viewModel.voirCompatibilite,
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

class _PhotoCarousel extends StatefulWidget {
  final List<String> photoUrls;

  const _PhotoCarousel({required this.photoUrls});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;

    if (urls.isEmpty) {
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
      child: Stack(
        children: [
          // Carrousel swipe + tap pour ouvrir en plein écran
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: urls.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openFullScreen(context, index),
              child: CachedNetworkImage(
                imageUrl: urls[index],
                fit: BoxFit.cover,
                width: double.infinity,
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
          ),

          // Compteur "2 / 5" en haut à droite (masqué si une seule photo)
          if (urls.length > 1)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text('${_current + 1} / ${urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),

          // Points de position en bas (masqués si une seule photo)
          if (urls.length > 1)
            Positioned(
              bottom: AppSpacing.sm,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// Ouvre la galerie en plein écran, zoomable, à partir de la photo tapée.
  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullScreenGallery(
        photoUrls: widget.photoUrls,
        initialIndex: initialIndex,
      ),
    ));
  }
}

/// Visionneuse plein écran : swipe entre les photos + pinch-to-zoom.
class _FullScreenGallery extends StatelessWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _FullScreenGallery(
      {required this.photoUrls, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: photoUrls[index],
              fit: BoxFit.contain,
            ),
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

/// Carte compatibilité : l'annonceur est un alternant compatible (APP-104).
/// Score + économie estimée, tap → calendrier de compatibilité.
class _CompatibiliteCard extends StatelessWidget {
  final MatchingSuggestion suggestion;
  final VoidCallback onTap;

  const _CompatibiliteCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.echangeLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.echange),
        ),
        child: Row(
          children: [
            Text('${suggestion.scorePercent}%',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.echange)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Compatible avec ton rythme d\'alternance',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (suggestion.hasEconomie) ...[
                    const SizedBox(height: 2),
                    Text(suggestion.economieLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.echange)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.echange),
          ],
        ),
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
