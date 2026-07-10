import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';

/// Onglets de l'écran accords
enum AccordTab { enCours, termines, tous }

/// Logique de l'écran "Mes accords".
class MesAccordsViewModel extends BaseViewModel {
  final AccordService _accords;
  final ProfileService _profile;

  MesAccordsViewModel(
      {AccordService? accordService, ProfileService? profileService})
      : _accords = accordService ?? locator<AccordService>(),
        _profile = profileService ?? locator<ProfileService>();

  List<Accord> _all = [];
  String? errorMessage;
  AccordTab tab = AccordTab.enCours;

  /// userId du connecté — détermine les actions possibles sur chaque accord
  String? currentUserId;

  Future<void> load() async {
    setBusy(true);
    try {
      currentUserId = await _profile.currentUserId();
      _all = await _accords.getMesAccords();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  void setTab(AccordTab t) {
    tab = t;
    notifyListeners();
  }

  /// Statuts considérés "en cours de vie"
  static const _statutsEnCours = {
    AccordStatut.EN_ATTENTE,
    AccordStatut.ACCEPTE,
    AccordStatut.EN_COURS,
  };

  List<Accord> get accords => switch (tab) {
        AccordTab.enCours =>
          _all.where((a) => _statutsEnCours.contains(a.statut)).toList(),
        AccordTab.termines =>
          _all.where((a) => !_statutsEnCours.contains(a.statut)).toList(),
        AccordTab.tous => _all,
      };

  // ─── Règles d'action ──────────────────────────────────────────
  // Seul le DESTINATAIRE accepte/refuse une demande en attente.
  // Seul l'INITIATEUR peut annuler sa demande en attente.

  bool canAcceptOrRefuse(Accord a) =>
      a.statut == AccordStatut.EN_ATTENTE &&
      currentUserId != null &&
      !a.isInitiator(currentUserId!);

  bool canCancel(Accord a) =>
      a.statut == AccordStatut.EN_ATTENTE &&
      currentUserId != null &&
      a.isInitiator(currentUserId!);

  // ─── Actions — null si OK, message d'erreur sinon ─────────────

  Future<String?> accept(Accord a) => _run(() => _accords.accept(a.id));

  Future<String?> refuse(Accord a) => _run(() => _accords.refuse(a.id));

  Future<String?> cancel(Accord a) => _run(() => _accords.cancel(a.id));

  Future<String?> _run(Future<Accord> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
