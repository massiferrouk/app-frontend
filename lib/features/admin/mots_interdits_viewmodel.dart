import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/admin_service.dart';
import '../../shared/models/mot_interdit.dart';

/// Logique de l'écran Mots interdits (APP-121).
///
/// La liste alimente le filtrage de la messagerie : un message contenant l'un
/// de ces mots est refusé à l'envoi. Elle était figée en base jusqu'ici,
/// faute d'endpoint pour la modifier.
class MotsInterditsViewModel extends BaseViewModel {
  final AdminService _admin;

  MotsInterditsViewModel({AdminService? adminService})
      : _admin = adminService ?? locator<AdminService>();

  List<MotInterdit> mots = [];
  String? errorMessage;

  Future<void> load() async {
    setBusy(true);
    try {
      mots = await _admin.motsInterdits();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Ajoute un mot puis recharge : le serveur le normalise en minuscules,
  /// donc afficher la saisie telle quelle mentirait sur ce qui est stocké.
  /// Retourne null si OK, un message d'erreur sinon (409 si déjà présent).
  Future<String?> ajouter(String mot) async {
    final saisie = mot.trim();
    if (saisie.isEmpty) return 'Saisis un mot';

    try {
      await _admin.ajouterMotInterdit(saisie);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.isConflict ? 'Ce mot est déjà dans la liste' : e.message;
    }
  }

  Future<String?> supprimer(MotInterdit mot) async {
    try {
      await _admin.supprimerMotInterdit(mot.id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
