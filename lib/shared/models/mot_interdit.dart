/// Miroir du MotInterditResponse backend — un mot filtré dans la messagerie.
///
/// Le mot est toujours stocké en minuscules côté serveur : le filtrage compare
/// en minuscules, donc la casse saisie n'a aucun effet.
class MotInterdit {
  final String id;
  final String mot;
  final DateTime createdAt;

  const MotInterdit({
    required this.id,
    required this.mot,
    required this.createdAt,
  });

  factory MotInterdit.fromJson(Map<String, dynamic> json) {
    return MotInterdit(
      id: json['id'] as String,
      mot: json['mot'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
