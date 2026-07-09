import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/utils/jwt_decoder.dart';
import '../shared/models/alternant_profile.dart';
import '../shared/models/enums.dart';
import 'token_storage_service.dart';

/// Service des profils utilisateur.
class ProfileService {
  final ApiClient _api;
  final TokenStorageService _tokens;

  ProfileService({ApiClient? apiClient, TokenStorageService? tokenStorage})
      : _api = apiClient ?? locator<ApiClient>(),
        _tokens = tokenStorage ?? locator<TokenStorageService>();

  // ─── Identité de l'utilisateur connecté (claims du JWT) ────────

  /// Rôle lu dans le token — null si pas connecté ou token illisible
  Future<UserRole?> currentRole() async {
    final token = await _tokens.getAccessToken();
    if (token == null) return null;

    final roleName = JwtDecoder.role(token);
    if (roleName == null) return null;
    try {
      return UserRole.fromJson(roleName);
    } catch (_) {
      return null;
    }
  }

  /// userId lu dans le token
  Future<String?> currentUserId() async {
    final token = await _tokens.getAccessToken();
    return token == null ? null : JwtDecoder.userId(token);
  }

  // ─── Profil alternant ──────────────────────────────────────────

  /// POST /profile/alternant — crée le profil de l'utilisateur connecté.
  /// Le backend génère automatiquement le calendrier d'alternance derrière.
  Future<AlternantProfile> createAlternantProfile({
    required String villeA,
    required String villeB,
    required String ecole,
    required String entreprise,
    required DateTime dateDebut,
    required DateTime dateFin,
    required RythmeAlternance rythme,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/profile/alternant',
      data: {
        'villeA': villeA,
        'villeB': villeB,
        'ecole': ecole,
        'entreprise': entreprise,
        'dateDebut': AlternantProfile.toIsoDate(dateDebut),
        'dateFin': AlternantProfile.toIsoDate(dateFin),
        'rythme': rythme.toJson(),
      },
    );
    return AlternantProfile.fromJson(data);
  }

  /// true si l'utilisateur connecté est un ALTERNANT sans profil :
  /// il doit alors passer par le formulaire de création.
  /// En cas d'erreur réseau, false : on ne bloque jamais l'entrée
  /// dans l'app pour ça.
  Future<bool> needsAlternantProfile() async {
    try {
      final role = await currentRole();
      if (role != UserRole.ALTERNANT) return false;
      return await getMyAlternantProfile() == null;
    } on ApiException {
      return false;
    }
  }

  /// GET /profile/{userId} — null si le profil n'existe pas encore (404).
  /// Utilisé après login pour décider d'afficher le formulaire de création.
  Future<AlternantProfile?> getMyAlternantProfile() async {
    final userId = await currentUserId();
    if (userId == null) return null;

    try {
      final data =
          await _api.get<Map<String, dynamic>>('/profile/$userId');
      return AlternantProfile.fromJson(data);
    } on ApiException catch (e) {
      if (e.isNotFound) return null; // pas encore de profil : cas normal
      rethrow; // toute autre erreur remonte
    }
  }
}
