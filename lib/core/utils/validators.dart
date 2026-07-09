/// Validation des champs de formulaire côté client.
/// ⚠️ Confort utilisateur uniquement : la validation serveur
/// (Bean Validation backend) fait toujours foi.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// null si valide, message d'erreur sinon (convention Flutter)
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'L\'email est requis';
    if (!_emailRegex.hasMatch(v)) return 'Format d\'email invalide';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName est requis';
    return null;
  }
}
