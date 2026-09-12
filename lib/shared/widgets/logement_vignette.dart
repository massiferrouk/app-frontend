import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Vignette d'un logement (photo de couverture) — APP-122.
/// Utilisée sur les cartes de match. Clé de cache STABLE (chemin sans la
/// signature) : les URLs MinIO sont signées et changent à chaque chargement,
/// sinon la vignette re-téléchargerait à chaque rafraîchissement. Fallback si
/// pas de photo.
class LogementVignette extends StatelessWidget {
  final String? photoUrl;
  final double width;
  final double height;
  final double radius;

  const LogementVignette({
    super.key,
    required this.photoUrl,
    this.width = 64,
    this.height = 52,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? const _Fallback()
            : Semantics(
                image: true,
                label: 'Photo du logement',
                child: CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: url.split('?').first,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _Fallback(),
                  errorWidget: (_, _, _) => const _Fallback(),
                ),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.apartment, color: AppColors.textTertiary, size: 22),
      ),
    );
  }
}
