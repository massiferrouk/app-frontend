/// Miroir de l'AlternantDashboardResponse backend.
///
/// APP-120 : les listes `prochainAccords` et `accordsEnAttente` ont été
/// retirées avec la feature accord. Le backend les envoie encore — on les
/// ignore simplement, sans casser la désérialisation.
class AlternantDashboard {
  /// Meilleure économie POSSIBLE parmi les matches (APP-120) — un potentiel,
  /// pas un acquis : le libellé affiché doit rester au conditionnel.
  final double economiePossibleMax;

  final int nbMatchesCompatibles;

  const AlternantDashboard({
    required this.economiePossibleMax,
    required this.nbMatchesCompatibles,
  });

  factory AlternantDashboard.fromJson(Map<String, dynamic> json) {
    return AlternantDashboard(
      // BigDecimal backend → num JSON → double Dart
      economiePossibleMax:
          (json['economiePossibleMax'] as num? ?? 0).toDouble(),
      nbMatchesCompatibles:
          (json['nbMatchesCompatibles'] as num? ?? 0).toInt(),
    );
  }
}
