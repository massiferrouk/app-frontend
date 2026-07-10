import 'accord_summary.dart';

/// Miroir de l'AlternantDashboardResponse backend.
class AlternantDashboard {
  /// Accords EN_COURS/ACCEPTE à venir (les prochains échanges)
  final List<AccordSummary> prochainAccords;

  /// Accords EN_ATTENTE de réponse (avec countdown d'expiration)
  final List<AccordSummary> accordsEnAttente;

  /// Économies estimées en euros sur les échanges réalisés
  final double economiesEstimees;

  final int nbAccordsTermines;

  const AlternantDashboard({
    required this.prochainAccords,
    required this.accordsEnAttente,
    required this.economiesEstimees,
    required this.nbAccordsTermines,
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
      economiesEstimees: (json['economiesEstimees'] as num? ?? 0).toDouble(),
      nbAccordsTermines: (json['nbAccordsTermines'] as num? ?? 0).toInt(),
    );
  }
}
