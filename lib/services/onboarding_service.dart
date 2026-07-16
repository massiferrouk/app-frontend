import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mémorise si l'onboarding du premier lancement a déjà été vu (APP-105).
///
/// Utilise le secure storage déjà présent dans l'app plutôt que
/// shared_preferences : un booléen n'a pas besoin de chiffrement, mais ça
/// évite une dépendance native supplémentaire (et le mode développeur
/// Windows qu'elle exigerait sur la machine de dev).
class OnboardingService {
  static const _vuKey = 'onboarding_vu';

  final FlutterSecureStorage _storage;

  OnboardingService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// true si l'utilisateur a déjà vu (ou passé) l'onboarding.
  /// Une erreur de lecture = premier lancement (montrer l'onboarding
  /// une fois de trop est sans conséquence, planter le démarrage non).
  Future<bool> dejaVu() async {
    try {
      return await _storage.read(key: _vuKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Appelé quand l'onboarding se termine ou est passé
  Future<void> marquerVu() => _storage.write(key: _vuKey, value: 'true');
}
