/// Miroir du MessageReportResponse backend — un message signalé, tel que le
/// voit un modérateur (APP-121).
///
/// Le contexte (contenu, auteur, signaleur) n'est renseigné que dans la file
/// de modération. À la création d'un signalement, le backend renvoie le même
/// objet sans ces champs : ils sont donc tous optionnels.
class MessageReport {
  final String id;
  final String messageId;
  final String reporterId;
  final String motif;
  final DateTime createdAt;

  /// Contenu signalé — null si le message a disparu entre-temps
  final String? contenuMessage;
  final String? auteurId;
  final String? auteurNom;
  final DateTime? messageCreeLe;
  final String? signalePar;

  const MessageReport({
    required this.id,
    required this.messageId,
    required this.reporterId,
    required this.motif,
    required this.createdAt,
    this.contenuMessage,
    this.auteurId,
    this.auteurNom,
    this.messageCreeLe,
    this.signalePar,
  });

  factory MessageReport.fromJson(Map<String, dynamic> json) {
    return MessageReport(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      reporterId: json['reporterId'] as String,
      motif: json['motif'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      contenuMessage: json['contenuMessage'] as String?,
      auteurId: json['auteurId'] as String?,
      auteurNom: json['auteurNom'] as String?,
      messageCreeLe: json['messageCreeLe'] == null
          ? null
          : DateTime.parse(json['messageCreeLe'] as String),
      signalePar: json['signalePar'] as String?,
    );
  }

  /// Le message a-t-il pu être chargé ? Sinon le modérateur ne peut pas
  /// juger sur pièce, et l'écran le dit au lieu d'afficher un vide.
  bool get contenuDisponible => contenuMessage != null;
}
