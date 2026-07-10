import 'enums.dart';

/// Une semaine du calendrier d'alternance (miroir AlternanceScheduleResponse).
class AlternanceSemaine {
  final String id;

  /// Toujours un lundi
  final DateTime semaine;

  /// 'A' = ville école, 'B' = ville entreprise
  final String label;
  final bool isOverridden;
  final String? overrideReason;

  const AlternanceSemaine({
    required this.id,
    required this.semaine,
    required this.label,
    required this.isOverridden,
    this.overrideReason,
  });

  factory AlternanceSemaine.fromJson(Map<String, dynamic> json) {
    return AlternanceSemaine(
      id: json['id'] as String,
      semaine: DateTime.parse(json['semaine'] as String),
      label: json['label'] as String,
      isOverridden: json['isOverridden'] as bool? ?? false,
      overrideReason: json['overrideReason'] as String?,
    );
  }
}

/// Le calendrier complet + contexte du profil (miroir MesSemainesResponse).
class MesSemaines {
  final String profileId;
  final String villeA;
  final String villeB;
  final RythmeAlternance rythme;
  final List<AlternanceSemaine> semaines;

  const MesSemaines({
    required this.profileId,
    required this.villeA,
    required this.villeB,
    required this.rythme,
    required this.semaines,
  });

  factory MesSemaines.fromJson(Map<String, dynamic> json) {
    return MesSemaines(
      profileId: json['profileId'] as String,
      villeA: json['villeA'] as String,
      villeB: json['villeB'] as String,
      rythme: RythmeAlternance.fromJson(json['rythme'] as String),
      semaines: (json['semaines'] as List? ?? [])
          .map((e) => AlternanceSemaine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Ville correspondant au label d'une semaine
  String villeFor(String label) => label == 'A' ? villeA : villeB;

  /// Proportion de semaines passées en ville A (pour la barre bicolore)
  double get partVilleA {
    if (semaines.isEmpty) return 0;
    final nbA = semaines.where((s) => s.label == 'A').length;
    return nbA / semaines.length;
  }
}
