// Valeurs en SCREAMING_SNAKE_CASE pour correspondre à l'enum Java backend.
// ignore_for_file: constant_identifier_names

import 'enums.dart';

/// Ville du profil alternant à laquelle un logement est associé
enum VilleAssociee {
  VILLE_A,
  VILLE_B;

  static VilleAssociee fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => this == VILLE_A ? 'Ville A' : 'Ville B';
}

/// Miroir du LogementResponse backend.
class Logement {
  final String id;
  final String ownerId;
  final String adresse;
  final String ville;
  final String codePostal;
  final LogementType type;
  final double surface;
  final int nbPieces;
  final double loyer;
  final double charges;
  final String? description;
  final List<String> equipements;
  final LogementStatut statut;
  final bool isVerified;
  final bool isMeuble;
  final VilleAssociee? villeAssociee;
  final List<String> photoUrls;

  const Logement({
    required this.id,
    required this.ownerId,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    required this.type,
    required this.surface,
    required this.nbPieces,
    required this.loyer,
    required this.charges,
    this.description,
    this.equipements = const [],
    required this.statut,
    required this.isVerified,
    required this.isMeuble,
    this.villeAssociee,
    this.photoUrls = const [],
  });

  factory Logement.fromJson(Map<String, dynamic> json) {
    return Logement(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      adresse: json['adresse'] as String,
      ville: json['ville'] as String,
      codePostal: json['codePostal'] as String,
      type: LogementType.fromJson(json['type'] as String),
      surface: (json['surface'] as num? ?? 0).toDouble(),
      nbPieces: (json['nbPieces'] as num? ?? 1).toInt(),
      loyer: (json['loyer'] as num? ?? 0).toDouble(),
      charges: (json['charges'] as num? ?? 0).toDouble(),
      description: json['description'] as String?,
      equipements: (json['equipements'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      statut: LogementStatut.fromJson(json['statut'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      isMeuble: json['isMeuble'] as bool? ?? true,
      villeAssociee: json['villeAssociee'] == null
          ? null
          : VilleAssociee.fromJson(json['villeAssociee'] as String),
      photoUrls: (json['photoUrls'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
