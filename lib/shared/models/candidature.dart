import 'enums.dart';
import 'logement.dart';

/// Miroir du CandidatureResponse backend (APP-117).
/// L'annonce est un [Logement] complet : on réutilise le modèle existant.
class Candidature {
  final String id;
  final CandidatureStatut statut;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Logement logement;

  const Candidature({
    required this.id,
    required this.statut,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.logement,
  });

  factory Candidature.fromJson(Map<String, dynamic> json) {
    return Candidature(
      id: json['id'] as String,
      statut: CandidatureStatut.fromJson(json['statut'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      logement: Logement.fromJson(json['logement'] as Map<String, dynamic>),
    );
  }
}
