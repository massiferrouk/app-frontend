import 'enums.dart';

/// Miroir de l'AccordResponse backend.
class Accord {
  final String id;
  final String initiatorId;
  final String receiverId;
  final String? logementAId;
  final String? logementBId;
  final AccordType type;
  final AccordStatut statut;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double? montantLoyer;
  final String? messageInitial;
  final DateTime createdAt;

  const Accord({
    required this.id,
    required this.initiatorId,
    required this.receiverId,
    this.logementAId,
    this.logementBId,
    required this.type,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
    this.montantLoyer,
    this.messageInitial,
    required this.createdAt,
  });

  factory Accord.fromJson(Map<String, dynamic> json) {
    return Accord(
      id: json['id'] as String,
      initiatorId: json['initiatorId'] as String,
      receiverId: json['receiverId'] as String,
      logementAId: json['logementAId'] as String?,
      logementBId: json['logementBId'] as String?,
      type: AccordType.fromJson(json['type'] as String),
      statut: AccordStatut.fromJson(json['statut'] as String),
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      montantLoyer: (json['montantLoyer'] as num?)?.toDouble(),
      messageInitial: json['messageInitial'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// true si [userId] a initié la demande
  bool isInitiator(String userId) => initiatorId == userId;

  /// Heures restantes avant expiration (72h après création).
  /// null si l'accord n'est plus EN_ATTENTE.
  int? get heuresAvantExpiration {
    if (statut != AccordStatut.EN_ATTENTE) return null;
    final expiration = createdAt.add(const Duration(hours: 72));
    final restant = expiration.difference(DateTime.now()).inHours;
    return restant < 0 ? 0 : restant;
  }
}
