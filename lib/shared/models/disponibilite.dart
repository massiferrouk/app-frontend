import 'enums.dart';

/// Miroir du DisponibiliteResponse backend — une plage de disponibilité.
class Disponibilite {
  final String id;
  final String logementId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DisponibiliteType type;

  const Disponibilite({
    required this.id,
    required this.logementId,
    required this.dateDebut,
    required this.dateFin,
    required this.type,
  });

  factory Disponibilite.fromJson(Map<String, dynamic> json) {
    return Disponibilite(
      id: json['id'] as String,
      logementId: json['logementId'] as String,
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      type: DisponibiliteType.fromJson(json['type'] as String),
    );
  }
}
