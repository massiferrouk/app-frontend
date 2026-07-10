import 'enums.dart';

/// Miroir de l'AccordSummaryResponse backend — version condensée d'un
/// accord pour les listes du dashboard.
class AccordSummary {
  final String id;
  final AccordType type;
  final AccordStatut statut;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String partnerId;

  /// Heures restantes avant expiration (accords EN_ATTENTE uniquement)
  final int? heuresAvantExpiration;

  const AccordSummary({
    required this.id,
    required this.type,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
    required this.partnerId,
    this.heuresAvantExpiration,
  });

  factory AccordSummary.fromJson(Map<String, dynamic> json) {
    return AccordSummary(
      id: json['id'] as String,
      type: AccordType.fromJson(json['type'] as String),
      statut: AccordStatut.fromJson(json['statut'] as String),
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      partnerId: json['partnerId'] as String,
      heuresAvantExpiration: (json['heuresAvantExpiration'] as num?)?.toInt(),
    );
  }
}
