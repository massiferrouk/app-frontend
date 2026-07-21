import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/enums.dart';

/// Couleur d'un statut de candidature — source unique, partagée par le badge
/// posé sur la photo et la pastille de l'écran Candidatures, pour que les deux
/// ne divergent jamais.
Color couleurCandidatureStatut(CandidatureStatut statut) => switch (statut) {
      CandidatureStatut.A_CONTACTER => AppColors.textTertiary,
      CandidatureStatut.CONTACTE => AppColors.colocation,
      CandidatureStatut.VISITE_PREVUE => AppColors.chevauchement,
      CandidatureStatut.VISITEE => AppColors.chevauchement,
      CandidatureStatut.SANS_SUITE => AppColors.error,
      CandidatureStatut.ACCEPTEE => AppColors.echange,
    };

/// Badge de statut posé en haut à droite de la photo d'une annonce (APP-119).
///
/// Objectif : en parcourant la recherche, savoir d'un coup d'œil qu'on a déjà
/// contacté ou visité une annonce, sans avoir à ouvrir quoi que ce soit.
/// Il n'apparaît QUE sur les annonces réellement suivies — les autres restent
/// vierges, sinon l'écran deviendrait illisible.
///
/// Le libellé texte est toujours présent : le sens ne repose jamais sur la
/// seule couleur (règle OPQUAST).
class StatutCandidatureBadge extends StatelessWidget {
  final CandidatureStatut statut;

  const StatutCandidatureBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: couleurCandidatureStatut(statut),
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        // Léger halo : garantit la lisibilité quelle que soit la photo dessous
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        statut.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
