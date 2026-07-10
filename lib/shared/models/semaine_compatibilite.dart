import 'enums.dart';

/// Miroir de SemaineCompatibilite (algorithme backend).
/// Une semaine comparée entre deux alternants, avec le type de
/// compatibilité et la couleur à afficher.
class SemaineCompatibilite {
  final DateTime semaine;
  final String villeAlternantA;
  final String villeAlternantB;
  final CompatibiliteType type;
  final String couleurHex;
  final String label;

  const SemaineCompatibilite({
    required this.semaine,
    required this.villeAlternantA,
    required this.villeAlternantB,
    required this.type,
    required this.couleurHex,
    required this.label,
  });

  factory SemaineCompatibilite.fromJson(Map<String, dynamic> json) {
    return SemaineCompatibilite(
      semaine: DateTime.parse(json['semaine'] as String),
      villeAlternantA: json['villeAlternantA'] as String,
      villeAlternantB: json['villeAlternantB'] as String,
      type: CompatibiliteType.fromJson(json['type'] as String),
      couleurHex: json['couleurHex'] as String? ?? '#ECF0F1',
      label: json['label'] as String? ?? '',
    );
  }
}
