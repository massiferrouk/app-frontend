import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/address_suggestion.dart';
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

  /// GET /logements — recherche publique avec filtres (logements ACTIF
  /// uniquement). Retourne la page + l'indicateur hasNext pour
  /// l'infinite scroll.
  /// [tri] : pertinence (défaut) | prix_asc | prix_desc | surface_desc.
  /// [total] permet d'afficher « X logements » sans attendre toutes les pages.
  Future<({List<Logement> logements, bool hasNext, int total})> search({
    String? ville,
    double? loyerMax,
    double? surfaceMin,
    bool? meuble,
    LogementType? type,
    String? tri,
    int page = 0,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/logements',
      queryParameters: {
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        'loyer_max': ?loyerMax,
        'surface_min': ?surfaceMin,
        'meuble': ?meuble,
        'type': ?type?.toJson(),
        'tri': ?tri,
        'page': page,
      },
    );
    return (
      logements: (data['content'] as List? ?? [])
          .map((e) => Logement.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: data['hasNext'] as bool? ?? false,
      total: (data['totalElements'] as num? ?? 0).toInt(),
    );
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

  /// GET /geocoding/autocomplete — suggestions d'adresses (Base Adresse
  /// Nationale). Retourne une liste vide si la requête est trop courte.
  Future<List<AddressSuggestion>> autocompleteAddress(String query) async {
    final data = await _api.get<List<dynamic>>(
      '/geocoding/autocomplete',
      queryParameters: {'q': query},
    );
    return data
        .map((e) => AddressSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// PUT /logements/{id} — met à jour un logement (brouillon ou publié).
  /// 409 si le logement est engagé dans un accord.
  Future<Logement> updateLogement({
    required String logementId,
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
    final data = await _api.put<Map<String, dynamic>>(
      '/logements/$logementId',
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

  /// POST /logements/{id}/photos — upload multipart (1 à 10 photos).
  /// Utilise les bytes de chaque image (readAsBytes) plutôt que le chemin
  /// fichier : fonctionne à la fois sur mobile ET sur le web (où image_picker
  /// renvoie un blob non lisible par MultipartFile.fromFile). (APP-93)
  Future<List<String>> addPhotos(
      String logementId, List<XFile> photos) async {
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      ));
    }
    final data = await _api.post<List<dynamic>>(
      '/logements/$logementId/photos',
      data: formData,
    );
    return data.map((e) => e.toString()).toList();
  }

  /// DELETE /logements/{id} — supprime un logement m'appartenant.
  /// 409 si le logement est engagé dans un accord.
  Future<void> delete(String logementId) async {
    await _api.delete<void>('/logements/$logementId');
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
