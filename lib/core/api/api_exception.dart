import 'package:dio/dio.dart';

/// Exception unique levée par la couche API.
/// Transforme le format d'erreur du backend StudUp
/// {code, message, timestamp, path, details[]} et les erreurs réseau
/// en une exception exploitable directement par les ViewModels.
class ApiException implements Exception {
  /// Code métier du backend (ex: DUPLICATE_EMAIL, VALIDATION_ERROR)
  /// ou code technique local (NETWORK_ERROR, UNKNOWN)
  final String code;

  /// Message affichable à l'utilisateur (déjà en français côté backend)
  final String message;

  /// Statut HTTP (0 si l'erreur est survenue avant d'atteindre le serveur)
  final int statusCode;

  /// Détails de validation champ par champ (souvent vide)
  final List<String> details;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details = const [],
  });

  // ─── Raccourcis utilisés par les ViewModels ───────────────────

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400;
  bool get isRateLimited => statusCode == 429;
  bool get isNetworkError => statusCode == 0;

  /// Construit l'exception depuis une erreur Dio.
  /// C'est LE point de traduction unique : toute la variété des erreurs
  /// possibles est ramenée à une ApiException.
  factory ApiException.fromDioException(DioException e) {
    // Cas 1 — pas de réponse serveur : problème réseau (timeout, pas de
    // connexion, serveur éteint...)
    final response = e.response;
    if (response == null) {
      return const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur. Vérifie ta connexion.',
        statusCode: 0,
      );
    }

    // Cas 2 — le serveur a répondu avec le format d'erreur StudUp
    final data = response.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return ApiException(
        code: data['code'] as String? ?? 'UNKNOWN',
        message: data['message'] as String,
        statusCode: response.statusCode ?? 0,
        details: (data['details'] as List?)
                ?.map((d) => d.toString())
                .toList() ??
            const [],
      );
    }

    // Cas 3 — réponse d'erreur sans le format attendu
    // (ex: 502 d'un proxy, HTML d'une gateway...)
    return ApiException(
      code: 'UNKNOWN',
      message: 'Une erreur est survenue. Réessaie plus tard.',
      statusCode: response.statusCode ?? 0,
    );
  }

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
