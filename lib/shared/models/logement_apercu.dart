import 'enums.dart';

/// Miroir de LogementApercuResponse (APP-122) — résumé du logement d'un match,
/// affiché sur la carte de l'écran Matches (vignette + ville · type · loyer).
/// [photoUrl] est l'URL signée de la photo de couverture, ou null.
class LogementApercu {
  final String id;
  final String ville;
  final LogementType? type;
  final double loyer;
  final String? photoUrl;

  const LogementApercu({
    required this.id,
    required this.ville,
    required this.type,
    required this.loyer,
    this.photoUrl,
  });

  factory LogementApercu.fromJson(Map<String, dynamic> json) {
    return LogementApercu(
      id: json['id'] as String,
      ville: json['ville'] as String,
      type: json['type'] == null
          ? null
          : LogementType.fromJson(json['type'] as String),
      loyer: (json['loyer'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
