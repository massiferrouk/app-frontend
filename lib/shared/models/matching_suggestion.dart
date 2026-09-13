import 'enums.dart';
import 'logement_apercu.dart';
import 'scenario.dart';
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

  /// Type d'arrangement principal. null quand le match passe par un scénario
  /// (relais, rééquilibrage) plutôt qu'un échange/coloc direct : le backend
  /// renvoie alors typePropose=null mais garde la suggestion via ses scénarios
  /// (APP-122). Un seul de ces matchs faisait planter tout le parsing de la
  /// liste — d'où « Aucun match » alors que le back renvoyait bien des matchs.
  final AccordType? typePropose;

  /// true = les logements nécessaires sont publiés, accord signable.
  /// false = match potentiel : profils compatibles, logement(s) manquant(s).
  final bool isMatchActif;
  final String? messageMatchPotentiel;
  final int nbSemainesEchange;
  final int nbSemainesColocation;
  final int nbSemainesChevauchement;
  final String? messageResume;
  final List<SemaineCompatibilite> semaines;

  /// Logements publiés qui rendent l'échange signable.
  /// null si l'alternant concerné n'a pas encore publié son logement.
  final String? logementAId; // logement de l'utilisateur connecté
  final String? logementBId; // logement du candidat

  /// Économie mensuelle estimée pour l'utilisateur connecté, en euros
  /// entiers (APP-103). 0 = pas calculable (loyers inconnus).
  final int economieMensuelle;

  /// Scénarios d'arrangement possibles, triés par priorité — le premier
  /// est le scénario principal affiché sur la match card (APP-109).
  final List<Scenario> scenarios;

  /// Rythme de l'autre alternant, prêt à afficher (APP-122) :
  /// « 3 sem. Paris / 1 sem. Lyon ». Construit par le backend. Peut être vide
  /// si l'API est ancienne (repli sur les villes à l'affichage).
  final String rythmeLabel;

  /// Aperçu du logement de l'autre alternant (APP-122) : vignette + infos sur
  /// la carte de match. null si l'autre n'a pas de logement publié.
  final LogementApercu? logementBApercu;

  const MatchingSuggestion({
    required this.profileId,
    required this.userId,
    required this.prenom,
    required this.nom,
    required this.villeA,
    required this.villeB,
    required this.score,
    required this.scorePercent,
    this.typePropose,
    required this.isMatchActif,
    this.messageMatchPotentiel,
    required this.nbSemainesEchange,
    required this.nbSemainesColocation,
    required this.nbSemainesChevauchement,
    this.messageResume,
    this.semaines = const [],
    this.logementAId,
    this.logementBId,
    this.economieMensuelle = 0,
    this.scenarios = const [],
    this.rythmeLabel = '',
    this.logementBApercu,
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
      typePropose: json['typePropose'] == null
          ? null
          : AccordType.fromJson(json['typePropose'] as String),
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
      logementAId: json['logementAId'] as String?,
      logementBId: json['logementBId'] as String?,
      economieMensuelle: (json['economieMensuelle'] as num? ?? 0).round(),
      scenarios: (json['scenarios'] as List? ?? [])
          .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
          .toList(),
      rythmeLabel: json['rythmeLabel'] as String? ?? '',
      logementBApercu: json['logementBApercu'] == null
          ? null
          : LogementApercu.fromJson(
              json['logementBApercu'] as Map<String, dynamic>),
    );
  }

  /// Ligne rythme prête à afficher, avec repli sur les villes si le backend
  /// n'a pas fourni le libellé (ancienne version de l'API).
  String get rythmeLigne =>
      rythmeLabel.isNotEmpty ? rythmeLabel : '$villeA ⇄ $villeB';

  /// Le scénario prioritaire à montrer sur la match card (null si aucun)
  Scenario? get scenarioPrincipal =>
      scenarios.isEmpty ? null : scenarios.first;

  /// Libellé du type d'arrangement, avec repli pour les matchs par scénario
  /// (typePropose null) — « Arrangement possible » plutôt qu'un plantage.
  String get typeLabel => typePropose?.label ?? 'Arrangement possible';

  /// true si une économie chiffrée peut être affichée
  bool get hasEconomie => economieMensuelle > 0;

  /// Phrase d'économie selon le type d'accord (APP-103)
  String get economieLabel => typePropose == AccordType.COLOCATION_TOURNANTE
      ? 'Divisez vos loyers : ≈ $economieMensuelle €/mois économisés chacun'
      : 'Économise ≈ $economieMensuelle €/mois';

  /// Version courte pour les cartes de match, allégées (APP-122) — le vert de
  /// l'économie est le seul repère coloré, inutile de le noyer dans une phrase.
  String get economieLabelCourt =>
      typePropose == AccordType.COLOCATION_TOURNANTE
          ? '≈ $economieMensuelle €/mois chacun'
          : '≈ $economieMensuelle €/mois';

  /// Type d'arrangement + nombre de semaines exploitables, en une ligne
  /// (ex. « Colocation tournante · 22 semaines ») — remplace l'empilement
  /// pastille de type + résumé des semaines sur les cartes (APP-122).
  String get arrangementLabel {
    final sem = nbSemainesEchange + nbSemainesColocation;
    if (sem <= 0) return typeLabel;
    return '$typeLabel · $sem semaine${sem > 1 ? 's' : ''}';
  }

  /// Nom affiché : "Thomas D."
  String get displayName =>
      '$prenom ${nom.isNotEmpty ? '${nom[0]}.' : ''}'.trim();

  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();
}
