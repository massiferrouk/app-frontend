import 'enums.dart';

/// Ligne logement du dashboard propriétaire (miroir LogementSummaryResponse).
class LogementSummary {
  final String id;
  final String ville;
  final String adresse;
  final LogementType type;
  final LogementStatut statut;
  final double loyer;
  final bool isOccupe;

  const LogementSummary({
    required this.id,
    required this.ville,
    required this.adresse,
    required this.type,
    required this.statut,
    required this.loyer,
    required this.isOccupe,
  });

  factory LogementSummary.fromJson(Map<String, dynamic> json) {
    return LogementSummary(
      id: json['id'] as String,
      ville: json['ville'] as String,
      adresse: json['adresse'] as String,
      type: LogementType.fromJson(json['type'] as String),
      statut: LogementStatut.fromJson(json['statut'] as String),
      loyer: (json['loyer'] as num? ?? 0).toDouble(),
      isOccupe: json['isOccupe'] as bool? ?? false,
    );
  }
}

/// Miroir du ProprietaireDashboardResponse backend.
class ProprietaireDashboard {
  final int nbLogementsTotaux;
  final int nbLogementsActifs;

  /// KPIs vivants (APP-119) — remplacent « taux d'occupation » et
  /// « locataires actifs », qui dépendaient d'accords EN_COURS jamais
  /// atteints et affichaient 0 pour toujours.
  final int nbEtudiantsInteresses;
  final int nbConversations;
  final List<LogementSummary> logements;

  const ProprietaireDashboard({
    required this.nbLogementsTotaux,
    required this.nbLogementsActifs,
    required this.nbEtudiantsInteresses,
    required this.nbConversations,
    required this.logements,
  });

  factory ProprietaireDashboard.fromJson(Map<String, dynamic> json) {
    return ProprietaireDashboard(
      nbLogementsTotaux: (json['nbLogementsTotaux'] as num? ?? 0).toInt(),
      nbLogementsActifs: (json['nbLogementsActifs'] as num? ?? 0).toInt(),
      nbEtudiantsInteresses:
          (json['nbEtudiantsInteresses'] as num? ?? 0).toInt(),
      nbConversations: (json['nbConversations'] as num? ?? 0).toInt(),
      logements: (json['logements'] as List? ?? [])
          .map((e) => LogementSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
