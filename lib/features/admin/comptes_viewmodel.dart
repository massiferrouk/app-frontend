import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/admin_service.dart';
import '../../shared/models/admin_user.dart';
import '../../shared/models/enums.dart';

/// Logique de l'écran Comptes (APP-121).
class ComptesViewModel extends BaseViewModel {
  final AdminService _admin;

  ComptesViewModel({AdminService? adminService})
      : _admin = adminService ?? locator<AdminService>();

  List<AdminUser> comptes = [];
  String? errorMessage;
  int total = 0;

  /// Filtres actifs — null = « tous »
  UserRole? filtreRole;
  EtatCompte? filtreEtat;

  int _page = 0;
  bool _hasNext = false;

  /// Une page de plus est disponible et aucun chargement n'est en cours.
  bool get peutChargerPlus => _hasNext && !isBusy;

  Future<void> load() async {
    _page = 0;
    setBusy(true);
    try {
      final result = await _admin.listUsers(role: filtreRole, etat: filtreEtat);
      comptes = result.users;
      _hasNext = result.hasNext;
      total = result.total;
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Page suivante — les résultats s'ajoutent à la liste courante.
  /// Une erreur ici ne vide pas ce qui est déjà affiché.
  Future<void> chargerPlus() async {
    if (!peutChargerPlus) return;
    setBusy(true);
    try {
      final result = await _admin.listUsers(
          role: filtreRole, etat: filtreEtat, page: _page + 1);
      comptes = [...comptes, ...result.users];
      _page++;
      _hasNext = result.hasNext;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Change un filtre et recharge depuis la première page.
  /// Repasser le même filtre le retire (bascule).
  Future<void> setFiltreRole(UserRole? role) async {
    filtreRole = filtreRole == role ? null : role;
    await load();
  }

  Future<void> setFiltreEtat(EtatCompte? etat) async {
    filtreEtat = filtreEtat == etat ? null : etat;
    await load();
  }

  Future<String?> suspendre(AdminUser user) =>
      _appliquer(() => _admin.suspendre(user.id));

  Future<String?> bannir(AdminUser user) =>
      _appliquer(() => _admin.bannir(user.id));

  Future<String?> reactiver(AdminUser user) =>
      _appliquer(() => _admin.reactiver(user.id));

  /// Applique une sanction puis recharge la liste : l'état affiché doit venir
  /// du serveur, pas d'une supposition côté client. Retourne null si OK,
  /// un message d'erreur sinon.
  Future<String?> _appliquer(Future<AdminUser> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
