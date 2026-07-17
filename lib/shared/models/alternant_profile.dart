import 'enums.dart';

/// Miroir de l'AlternantProfileResponse backend.
class AlternantProfile {
  final String id;
  final String userId;

  /// Ville de l'école
  final String villeA;

  /// Ville de l'entreprise
  final String villeB;
  final String ecole;
  final String entreprise;
  final DateTime dateDebut;
  final DateTime dateFin;
  final RythmeAlternance rythme;

  /// Première semaine du cycle : école ou entreprise (APP-110)
  final PremiereSemaine premiereSemaine;

  const AlternantProfile({
    required this.id,
    required this.userId,
    required this.villeA,
    required this.villeB,
    required this.ecole,
    required this.entreprise,
    required this.dateDebut,
    required this.dateFin,
    required this.rythme,
    required this.premiereSemaine,
  });

  factory AlternantProfile.fromJson(Map<String, dynamic> json) {
    return AlternantProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      villeA: json['villeA'] as String,
      villeB: json['villeB'] as String,
      ecole: json['ecole'] as String,
      entreprise: json['entreprise'] as String,
      // Le backend envoie les LocalDate en ISO-8601 : "2026-09-01"
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      rythme: RythmeAlternance.fromJson(json['rythme'] as String),
      // Défensif : un backend pas encore migré n'envoie pas le champ —
      // on retombe alors sur l'ordre historique du rythme
      premiereSemaine: json['premiereSemaine'] != null
          ? PremiereSemaine.fromJson(json['premiereSemaine'] as String)
          : PremiereSemaine.defaultFor(
              RythmeAlternance.fromJson(json['rythme'] as String)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'villeA': villeA,
        'villeB': villeB,
        'ecole': ecole,
        'entreprise': entreprise,
        'dateDebut': toIsoDate(dateDebut),
        'dateFin': toIsoDate(dateFin),
        'rythme': rythme.toJson(),
        'premiereSemaine': premiereSemaine.toJson(),
      };

  /// LocalDate backend = date sans heure : "2026-09-01"
  static String toIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
