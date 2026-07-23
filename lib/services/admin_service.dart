import '../core/api/api_client.dart';
import '../shared/models/admin_dashboard.dart';
import '../shared/models/admin_user.dart';
import '../shared/models/enums.dart';
import '../shared/models/logement.dart';
import '../shared/models/logement_report.dart';
import '../shared/models/message_report.dart';
import '../shared/models/mot_interdit.dart';

/// Service d'administration (APP-121).
/// Toutes les routes sont protégées par le rôle ADMIN côté serveur : un appel
/// depuis un autre compte reçoit un 403, quoi que fasse le client.
class AdminService {
  final ApiClient _api;

  AdminService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// GET /admin/dashboard — chiffres de la plateforme.
  Future<AdminDashboard> dashboard() async {
    final data = await _api.get<Map<String, dynamic>>('/admin/dashboard');
    return AdminDashboard.fromJson(data);
  }

  /// GET /admin/users — liste paginée, filtrable par rôle et par état.
  ///
  /// Le backend ne connaît que isActive : « suspendu » et « banni » partagent
  /// donc le même filtre, et c'est deletedAt qui les départage à l'affichage.
  Future<({List<AdminUser> users, bool hasNext, int total})> listUsers({
    UserRole? role,
    EtatCompte? etat,
    int page = 0,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {
        'role': ?role?.toJson(),
        'isActive': ?etat?.isActiveFiltre,
        'page': page,
      },
    );
    return (
      users: (data['content'] as List? ?? [])
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: data['hasNext'] as bool? ?? false,
      total: (data['totalElements'] as num? ?? 0).toInt(),
    );
  }

  /// PUT /admin/users/{id}/suspend — coupe l'accès immédiatement.
  Future<AdminUser> suspendre(String userId) => _action(userId, 'suspend');

  /// PUT /admin/users/{id}/ban — suspension permanente (soft delete).
  Future<AdminUser> bannir(String userId) => _action(userId, 'ban');

  /// PUT /admin/users/{id}/reactivate — lève la sanction.
  Future<AdminUser> reactiver(String userId) => _action(userId, 'reactivate');

  Future<AdminUser> _action(String userId, String action) async {
    final data =
        await _api.put<Map<String, dynamic>>('/admin/users/$userId/$action');
    return AdminUser.fromJson(data);
  }

  // ─── Modération de la messagerie ────────────────────────────────

  /// GET /admin/moderation/messages — file des messages signalés non masqués.
  /// Le backend joint le contenu du message et les noms des deux personnes :
  /// sans eux, impossible de trancher.
  Future<({List<MessageReport> signalements, bool hasNext, int total})>
      signalements({int page = 0}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/admin/moderation/messages',
      queryParameters: {'page': page},
    );
    return (
      signalements: (data['content'] as List? ?? [])
          .map((e) => MessageReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: data['hasNext'] as bool? ?? false,
      total: (data['totalElements'] as num? ?? 0).toInt(),
    );
  }

  /// PUT /admin/moderation/messages/{id}/hide — masque le message.
  /// Le message reste en base : il est marqué masqué, et la note de
  /// modération garde la trace de la décision. Elle est obligatoire côté
  /// serveur (400 si vide).
  Future<void> masquerMessage(String messageId, String note) =>
      _api.put<void>(
        '/admin/moderation/messages/$messageId/hide',
        data: {'moderationNote': note},
      );

  // ─── Mots interdits ─────────────────────────────────────────────

  /// GET /admin/moderation/mots-interdits — la liste complète, triée.
  /// Pas de pagination : cette liste reste courte par nature.
  Future<List<MotInterdit>> motsInterdits() async {
    final data =
        await _api.get<List<dynamic>>('/admin/moderation/mots-interdits');
    return data
        .map((e) => MotInterdit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/moderation/mots-interdits — 409 si le mot existe déjà,
  /// quelle que soit la casse saisie.
  Future<MotInterdit> ajouterMotInterdit(String mot) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/admin/moderation/mots-interdits',
      data: {'mot': mot},
    );
    return MotInterdit.fromJson(data);
  }

  /// DELETE /admin/moderation/mots-interdits/{id}
  Future<void> supprimerMotInterdit(String id) =>
      _api.delete<void>('/admin/moderation/mots-interdits/$id');

  // ─── Modération des annonces ────────────────────────────────────

  /// GET /admin/logements — liste d'administration.
  /// Contrairement à la recherche publique, elle montre aussi les brouillons
  /// et les annonces déjà suspendues : sans ça, impossible de défaire une
  /// suspension.
  Future<({List<Logement> logements, bool hasNext, int total})> logements({
    LogementStatut? statut,
    int page = 0,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/admin/logements',
      queryParameters: {'statut': ?statut?.toJson(), 'page': page},
    );
    return (
      logements: (data['content'] as List? ?? [])
          .map((e) => Logement.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: data['hasNext'] as bool? ?? false,
      total: (data['totalElements'] as num? ?? 0).toInt(),
    );
  }

  /// PUT /admin/logements/{id}/suspendre — le motif est obligatoire (400
  /// sinon) : il est envoyé au propriétaire pour expliquer le retrait.
  Future<Logement> suspendreLogement(String logementId, String motif) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/admin/logements/$logementId/suspendre',
      data: {'motif': motif},
    );
    return Logement.fromJson(data);
  }

  /// PUT /admin/logements/{id}/republier
  Future<Logement> republierLogement(String logementId) async {
    final data = await _api
        .put<Map<String, dynamic>>('/admin/logements/$logementId/republier');
    return Logement.fromJson(data);
  }

  /// GET /admin/moderation/logements — annonces signalées encore en ligne.
  /// Une annonce déjà suspendue sort de la file : le dossier est clos.
  Future<({List<LogementReport> signalements, bool hasNext, int total})>
      annoncesSignalees({int page = 0}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/admin/moderation/logements',
      queryParameters: {'page': page},
    );
    return (
      signalements: (data['content'] as List? ?? [])
          .map((e) => LogementReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: data['hasNext'] as bool? ?? false,
      total: (data['totalElements'] as num? ?? 0).toInt(),
    );
  }
}
