import 'enums.dart';

/// Miroir de l'AdminUserResponse backend — un compte vu par l'administration.
class AdminUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  /// Non null = compte banni (soft delete). Un compte simplement suspendu a
  /// isActive à false mais deletedAt null : les deux états sont distincts et
  /// n'ouvrent pas les mêmes actions.
  final DateTime? deletedAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.deletedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  EtatCompte get etat {
    if (deletedAt != null) return EtatCompte.banni;
    return isActive ? EtatCompte.actif : EtatCompte.suspendu;
  }
}

/// État d'un compte du point de vue de l'administration.
/// Dérivé de isActive + deletedAt, que le backend expose séparément.
enum EtatCompte {
  actif,
  suspendu,
  banni;

  String get label => switch (this) {
        actif => 'Actif',
        suspendu => 'Suspendu',
        banni => 'Banni',
      };

  /// Filtre envoyé à l'API : isActive. Le bannissement n'a pas de filtre
  /// dédié côté backend — il se distingue à l'affichage par deletedAt.
  bool? get isActiveFiltre => switch (this) {
        actif => true,
        suspendu => false,
        banni => false,
      };
}
