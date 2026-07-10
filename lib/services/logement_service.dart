import 'package:dio/dio.dart';

import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/disponibilite.dart';
import '../shared/models/enums.dart';
import '../shared/models/logement.dart';
import '../shared/models/reputation_score.dart';

/// Service des logements.
class LogementService {
  final ApiClient _api;

  LogementService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /logements/mes-logements — tous mes logements, brouillons inclus
  Future<List<Logement>> getMesLogements() async {
    final data = await _api.get<List<dynamic>>('/logements/mes-logements');
    return data
        .map((e) => Logement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /logements/{id} — détail complet d'un logement
  Future<Logement> getLogement(String logementId) async {
    final data =
        await _api.get<Map<String, dynamic>>('/logements/$logementId');
    return Logement.fromJson(data);
  }

  /// GET /logements/{id}/disponibilites — plages de disponibilité
  Future<List<Disponibilite>> getDisponibilites(String logementId) async {
    final data = await _api
        .get<List<dynamic>>('/logements/$logementId/disponibilites');
    return data
        .map((e) => Disponibilite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /reputation/user/{userId} — score de réputation du propriétaire
  Future<ReputationScore> getReputation(String userId) async {
    final data =
        await _api.get<Map<String, dynamic>>('/reputation/user/$userId');
    return ReputationScore.fromJson(data);
  }

  /// POST /logements — crée un logement en statut BROUILLON
  Future<Logement> createLogement({
    required String adresse,
    required String ville,
    required String codePostal,
    required LogementType type,
    required double surface,
    required int nbPieces,
    required double loyer,
    required double charges,
    String? description,
    List<String> equipements = const [],
    required bool isMeuble,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/logements',
      data: {
        'adresse': adresse,
        'ville': ville,
        'codePostal': codePostal,
        'type': type.toJson(),
        'surface': surface,
        'nbPieces': nbPieces,
        'loyer': loyer,
        'charges': charges,
        'description': description,
        'equipements': equipements,
        'isMeuble': isMeuble,
      },
    );
    return Logement.fromJson(data);
  }

  /// POST /logements/{id}/photos — upload multipart (1 à 10 photos)
  Future<List<String>> addPhotos(
      String logementId, List<String> filePaths) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(path),
      ));
    }
    final data = await _api.post<List<dynamic>>(
      '/logements/$logementId/photos',
      data: formData,
    );
    return data.map((e) => e.toString()).toList();
  }

  /// PUT /logements/{id}/publish — BROUILLON → ACTIF
  Future<Logement> publish(String logementId) async {
    final data = await _api
        .put<Map<String, dynamic>>('/logements/$logementId/publish');
    return Logement.fromJson(data);
  }

  /// PATCH /logements/{id}/ville — associe le logement à villeA ou villeB
  /// du profil alternant (409 si un logement occupe déjà cette ville).
  Future<Logement> associerVille(
      String logementId, VilleAssociee ville) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/logements/$logementId/ville',
      data: {'villeAssociee': ville.toJson()},
    );
    return Logement.fromJson(data);
  }
}
