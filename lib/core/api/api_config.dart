/// Configuration de l'API par environnement.
/// ⚠️ Jamais d'URL de prod en dur ailleurs que dans ce fichier.
class ApiConfig {
  ApiConfig._();

  /// URL du backend — configurable par environnement (APP-87) :
  ///   flutter run --dart-define=API_URL=http://...:8080/api/v1
  ///
  /// Selon la cible :
  /// - Web / desktop (même machine)   : http://localhost:8080/api/v1 (défaut)
  /// - Émulateur Android              : http://10.0.2.2:8080/api/v1
  /// - Téléphone réel (même WiFi)     : http://IP-du-PC:8080/api/v1 (ipconfig)
  /// - Production                     : https://…railway.app/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// Délais avant abandon d'une requête
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Point d'entrée WebSocket SockJS (messagerie temps réel).
  /// Dérivé de baseUrl : http://host:8080/ws
  static String get wsUrl => baseUrl.replaceFirst('/api/v1', '/ws');

  /// Endpoints publics : aucun token à attacher
  static const List<String> publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/confirm',
  ];
}
