import 'package:flutter/material.dart';

/// Palette de couleurs StudUp — source unique de vérité.
/// Ne jamais utiliser une couleur en dur dans un écran : toujours passer par ici.
class AppColors {
  AppColors._(); // constructeur privé — classe non instanciable

  // ─── Fondamentaux ─────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);

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

  /// Ville B (entreprise) — gris
  static const Color villeB = Color(0xFF9E9E9E);
}
