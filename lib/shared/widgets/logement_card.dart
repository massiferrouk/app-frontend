import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/logement.dart';

/// Carte d'annonce : grande photo 16:9, prix mis en avant, caractéristiques
/// puis badges. Partagée par l'accueil étudiant (aperçu) et l'écran Recherche
/// (APP-117) — l'annonce est le contenu principal côté étudiant, elle doit
/// être visuelle, pas une ligne de liste.
class LogementCard extends StatelessWidget {
  final Logement logement;
  final VoidCallback onTap;

  /// Contenu additionnel affiché en bas de la carte (ex : le statut d'une
  /// candidature). Optionnel — null sur les écrans de simple consultation.
  final Widget? footer;

  const LogementCard({
    super.key,
    required this.logement,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        // L'image doit épouser les coins arrondis de la carte
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: logement.photoUrls.isEmpty
                  ? const _PhotoFallback()
                  : Image.network(
                      logement.photoUrls.first,
                      fit: BoxFit.cover,
                      semanticLabel: 'Photo du logement à ${logement.ville}',
                      errorBuilder: (_, _, _) => const _PhotoFallback(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${logement.loyer.toStringAsFixed(0)} € /mois',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      '${logement.type.label} · '
                      '${logement.surface.toStringAsFixed(0)} m² · '
                      '${logement.ville}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (logement.isMeuble || logement.isVerified) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (logement.isMeuble)
                          const _MiniBadge(label: 'Meublé'),
                        if (logement.isVerified)
                          const _MiniBadge(
                              label: 'Vérifié ✓', color: AppColors.echange),
                      ],
                    ),
                  ],
                  if (footer != null) ...[
                    const Divider(height: AppSpacing.lg),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visuel de repli quand l'annonce n'a pas de photo (ou qu'elle ne charge pas).
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      alignment: Alignment.center,
      child:
          const Icon(Icons.apartment, size: 32, color: AppColors.textTertiary),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
