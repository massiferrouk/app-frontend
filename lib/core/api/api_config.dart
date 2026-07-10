/// Configuration de l'API par environnement.
/// ⚠️ Jamais d'URL de prod en dur ailleurs que dans ce fichier.
class ApiConfig {
  ApiConfig._();

  /// URL du backend Spring Boot local.
  ///
  /// ⚠️ Piège classique : depuis l'émulateur Android, "localhost" désigne
  /// l'émulateur lui-même, pas ton PC. L'adresse spéciale 10.0.2.2 est
  /// l'alias de la machine hôte vue depuis l'émulateur.
  /// Sur un téléphone réel : remplacer par l'IP locale du PC (ipconfig).
  /// Téléphone réel : IP locale du PC (ipconfig → IPv4), même WiFi requis.
  /// Émulateur Android : remettre 'http://10.0.2.2:8080/api/v1'.
  static const String baseUrl = 'http://10.177.155.139:8080/api/v1';

  /// Délais avant abandon d'une requête
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Endpoints publics : aucun token à attacher
  static const List<String> publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/confirm',
  ];
}
