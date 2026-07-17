/// Ce que l'utilisateur peut faire depuis un scénario (APP-109)
enum ScenarioAction {
  publierLogement,
  contacter,
  aucune;

  static ScenarioAction fromJson(String? value) => switch (value) {
        'PUBLIER_LOGEMENT' => ScenarioAction.publierLogement,
        'CONTACTER' => ScenarioAction.contacter,
        _ => ScenarioAction.aucune,
      };
}

/// Miroir de ScenarioResponse backend — un arrangement possible avec un
/// match : message, économie éventuelle et action proposée (APP-109).
/// [type] reste une String : le backend peut ajouter des types sans
/// casser l'app (on ne s'en sert que pour choisir une icône).
class Scenario {
  final String type;
  final String message;

  /// 0 = non calculable, rien à afficher
  final int economieMensuelle;
  final ScenarioAction action;

  const Scenario({
    required this.type,
    required this.message,
    this.economieMensuelle = 0,
    this.action = ScenarioAction.aucune,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      economieMensuelle: (json['economieMensuelle'] as num? ?? 0).round(),
      action: ScenarioAction.fromJson(json['action'] as String?),
    );
  }

  bool get hasEconomie => economieMensuelle > 0;
}
