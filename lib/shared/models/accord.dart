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

  /// Prénoms des participants (fournis par le backend pour l'affichage,
  /// ex: bouton « Contacter »). Peuvent être null selon l'endpoint.
  final String? initiatorPrenom;
  final String? receiverPrenom;

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
    this.initiatorPrenom,
    this.receiverPrenom,
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
      initiatorPrenom: json['initiatorPrenom'] as String?,
      receiverPrenom: json['receiverPrenom'] as String?,
    );
  }

  /// Id du partenaire vu par [userId] (l'autre participant).
  String partnerId(String userId) =>
      initiatorId == userId ? receiverId : initiatorId;

  /// Prénom du partenaire vu par [userId].
  String? partnerPrenom(String userId) =>
      initiatorId == userId ? receiverPrenom : initiatorPrenom;

  /// true si [userId] a initié la demande
  bool isInitiator(String userId) => initiatorId == userId;

  /// Seul le DESTINATAIRE d'une demande EN_ATTENTE peut accepter/refuser
  bool canBeAnsweredBy(String userId) =>
      statut == AccordStatut.EN_ATTENTE && receiverId == userId;

  /// Seul l'INITIATEUR d'une demande EN_ATTENTE peut l'annuler
  bool canBeCancelledBy(String userId) =>
      statut == AccordStatut.EN_ATTENTE && initiatorId == userId;

  /// Heures restantes avant expiration (72h après création).
  /// null si l'accord n'est plus EN_ATTENTE.
  int? get heuresAvantExpiration {
    if (statut != AccordStatut.EN_ATTENTE) return null;
    final expiration = createdAt.add(const Duration(hours: 72));
    final restant = expiration.difference(DateTime.now()).inHours;
    return restant < 0 ? 0 : restant;
  }
}
