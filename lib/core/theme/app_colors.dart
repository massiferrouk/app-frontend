import 'package:flutter/material.dart';

/// Palette de couleurs StudUp — source unique de vérité.
/// Ne jamais utiliser une couleur en dur dans un écran : toujours passer par ici.
class AppColors {
  AppColors._(); // constructeur privé — classe non instanciable

  // ─── Fondamentaux ─────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Accessibilité (APP-112, OPQUAST) : l'ancien #9E9E9E ne donnait qu'un
  // ratio de ~2.7:1 sur fond blanc, sous le seuil AA (4.5:1) pour du texte.
  // #757575 monte à ~4.6:1 tout en restant le gris le plus clair de la
  // hiérarchie. Réservé aux textes secondaires (placeholders, légendes).
  static const Color textTertiary = Color(0xFF757575);

  // ─── Surfaces et bordures ─────────────────────────────────────
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFF0F0F0);

  // ─── Couleurs métier (matching / calendrier) ──────────────────
  /// Vert — échange possible, actions positives, CTA principaux
  static const Color echange = Color(0xFF27AE60);
  static const Color echangeLight = Color(0xFFF0FAF4);

  /// Bleu — colocation tournante
  static const Color colocation = Color(0xFF3498DB);
  static const Color colocationLight = Color(0xFFF0F7FF);

  /// Orange — chevauchement, avertissements, semaine modifiée
  static const Color chevauchement = Color(0xFFF39C12);
  static const Color chevauchementLight = Color(0xFFFFF8F0);

  /// Gris — semaines incompatibles
  static const Color incompatible = Color(0xFFECF0F1);

  // ─── États ────────────────────────────────────────────────────
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDF0EE);
  static const Color success = echange;

  // ─── Calendrier personnel ─────────────────────────────────────
  /// Ville A (école) — foncé
  static const Color villeA = Color(0xFF1A1A1A);

  /// Ville B (entreprise) — gris.
  /// Barre décorative : l'information ville A/B n'est JAMAIS portée par la
  /// seule couleur (toujours doublée d'un badge A/B et du nom de ville en
  /// texte), conformément à la règle OPQUAST « ne pas donner l'information
  /// uniquement par la couleur ». La teinte reste donc volontairement claire.
  static const Color villeB = Color(0xFF9E9E9E);
}
