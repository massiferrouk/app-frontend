import 'accord_summary.dart';

/// Miroir de l'AlternantDashboardResponse backend.
class AlternantDashboard {
  /// Accords EN_COURS/ACCEPTE à venir (les prochains échanges)
  final List<AccordSummary> prochainAccords;

  /// Accords EN_ATTENTE de réponse (avec countdown d'expiration)
  final List<AccordSummary> accordsEnAttente;

  /// Économies estimées en euros sur les échanges réalisés
  /// Meilleure économie POSSIBLE parmi les matches (APP-120) — un potentiel,
  /// pas un acquis : le libellé affiché doit rester au conditionnel.
  final double economiePossibleMax;

  final int nbMatchesCompatibles;

  const AlternantDashboard({
    required this.prochainAccords,
    required this.accordsEnAttente,
    required this.economiePossibleMax,
    required this.nbMatchesCompatibles,
  });

  factory AlternantDashboard.fromJson(Map<String, dynamic> json) {
    return AlternantDashboard(
      prochainAccords: (json['prochainAccords'] as List? ?? [])
          .map((e) => AccordSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      accordsEnAttente: (json['accordsEnAttente'] as List? ?? [])
          .map((e) => AccordSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      // BigDecimal backend → num JSON → double Dart
      economiePossibleMax:
          (json['economiePossibleMax'] as num? ?? 0).toDouble(),
      nbMatchesCompatibles:
          (json['nbMatchesCompatibles'] as num? ?? 0).toInt(),
    );
  }
}
