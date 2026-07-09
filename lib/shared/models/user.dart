import 'enums.dart';

/// Miroir du UserResponse backend.
/// Classe immutable : tous les champs sont final, aucune modification
/// possible après construction — on remplace l'objet entier si besoin.
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phone;
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    required this.isVerified,
  });

  /// Désérialisation depuis le JSON backend
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.fromJson(json['role'] as String),
      phone: json['phone'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toJson(),
        'phone': phone,
        'isVerified': isVerified,
      };

  /// Initiales pour l'avatar (ex: Alice Martin → AM)
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  String get fullName => '$firstName $lastName';
}
