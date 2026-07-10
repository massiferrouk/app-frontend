import 'enums.dart';
import 'semaine_compatibilite.dart';

/// Miroir de MatchingSuggestionResponse backend — un match proposé.
class MatchingSuggestion {
  final String profileId;
  final String userId;
  final String prenom;
  final String nom;
  final String villeA;
  final String villeB;
  final double score;
  final int scorePercent;
  final AccordType typePropose;

  /// true = les logements nécessaires sont publiés, accord signable.
  /// false = match potentiel : profils compatibles, logement(s) manquant(s).
  final bool isMatchActif;
  final String? messageMatchPotentiel;
  final int nbSemainesEchange;
  final int nbSemainesColocation;
  final int nbSemainesChevauchement;
  final String? messageResume;
  final List<SemaineCompatibilite> semaines;

  const MatchingSuggestion({
    required this.profileId,
    required this.userId,
    required this.prenom,
    required this.nom,
    required this.villeA,
    required this.villeB,
    required this.score,
    required this.scorePercent,
    required this.typePropose,
    required this.isMatchActif,
    this.messageMatchPotentiel,
    required this.nbSemainesEchange,
    required this.nbSemainesColocation,
    required this.nbSemainesChevauchement,
    this.messageResume,
    this.semaines = const [],
  });

  factory MatchingSuggestion.fromJson(Map<String, dynamic> json) {
    return MatchingSuggestion(
      profileId: json['profileId'] as String,
      userId: json['userId'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      villeA: json['villeA'] as String,
      villeB: json['villeB'] as String,
      score: (json['score'] as num).toDouble(),
      scorePercent: (json['scorePercent'] as num).toInt(),
      typePropose: AccordType.fromJson(json['typePropose'] as String),
      isMatchActif: json['isMatchActif'] as bool? ?? false,
      messageMatchPotentiel: json['messageMatchPotentiel'] as String?,
      nbSemainesEchange: (json['nbSemainesEchange'] as num? ?? 0).toInt(),
      nbSemainesColocation:
          (json['nbSemainesColocation'] as num? ?? 0).toInt(),
      nbSemainesChevauchement:
          (json['nbSemainesChevauchement'] as num? ?? 0).toInt(),
      messageResume: json['messageResume'] as String?,
      semaines: (json['semaines'] as List? ?? [])
          .map((e) => SemaineCompatibilite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Nom affiché : "Thomas D."
  String get displayName =>
      '$prenom ${nom.isNotEmpty ? '${nom[0]}.' : ''}'.trim();

  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();
}
