/// Miroir du LogementReportResponse backend — une annonce signalée, telle que
/// la voit un modérateur (APP-121).
class LogementReport {
  final String id;
  final String logementId;
  final String motif;
  final DateTime createdAt;

  /// Null si l'annonce a disparu entre le signalement et la consultation
  final String? logementLibelle;
  final String? proprietaire;
  final String? signalePar;

  const LogementReport({
    required this.id,
    required this.logementId,
    required this.motif,
    required this.createdAt,
    this.logementLibelle,
    this.proprietaire,
    this.signalePar,
  });

  factory LogementReport.fromJson(Map<String, dynamic> json) {
    return LogementReport(
      id: json['id'] as String,
      logementId: json['logementId'] as String,
      motif: json['motif'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      logementLibelle: json['logementLibelle'] as String?,
      proprietaire: json['proprietaire'] as String?,
      signalePar: json['signalePar'] as String?,
    );
  }

  /// L'annonce a-t-elle pu être chargée ? Sinon le modérateur ne peut pas
  /// juger, et l'écran le dit plutôt que d'afficher un vide.
  bool get annonceDisponible => logementLibelle != null;
}
