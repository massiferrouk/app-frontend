import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/calendrier_service.dart';
import '../../shared/models/mes_semaines.dart';

/// Les deux vues de Mon calendrier (APP-118) : liste détaillée et
/// calendrier annuel (heatmap ville école / ville entreprise).
enum VueCalendrier { liste, annuel }

/// Logique de l'écran "Mon calendrier".
class MonCalendrierViewModel extends BaseViewModel {
  final CalendrierService _calendrier;

  MonCalendrierViewModel({CalendrierService? calendrierService})
      : _calendrier = calendrierService ?? locator<CalendrierService>();

  MesSemaines? data;
  String? errorMessage;

  /// Mois français — évite l'initialisation de locale intl pour si peu
  static const _mois = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  Future<void> load() async {
    setBusy(true);
    try {
      data = await _calendrier.getMesSemaines();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Semaines groupées par mois, dans l'ordre chronologique.
  /// Clé = "Juillet 2026", valeur = semaines de ce mois.
  Map<String, List<AlternanceSemaine>> get semainesParMois {
    final grouped = <String, List<AlternanceSemaine>>{};
    for (final s in data?.semaines ?? <AlternanceSemaine>[]) {
      final key = '${_mois[s.semaine.month - 1]} ${s.semaine.year}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    return grouped;
  }

  /// Une semaine passée n'est pas modifiable (règle backend répliquée
  /// pour éviter un aller-retour voué à l'échec)
  bool isModifiable(AlternanceSemaine s) =>
      !s.semaine.isBefore(DateTime.now());

  /// Applique un override puis recharge le calendrier.
  /// Retourne null si OK, un message d'erreur sinon (affiché par la View).
  Future<String?> modifierSemaine({
    required AlternanceSemaine semaine,
    required String label,
    required String reason,
  }) async {
    if (data == null) return 'Calendrier non chargé';

    setBusy(true);
    try {
      await _calendrier.overrideSemaine(
        profileId: data!.profileId,
        semaine: semaine.semaine,
        label: label,
        reason: reason,
      );
      await load(); // recharge pour refléter le badge "Modifié"
      return null;
    } on ApiException catch (e) {
      setBusy(false);
      return e.message;
    }
  }

  // ─── Bascule liste / calendrier annuel (APP-118) ─────────────────

  /// Vue affichée — bascule liste ⇄ annuel via l'icône de l'AppBar
  VueCalendrier vue = VueCalendrier.liste;

  void cyclerVue() {
    vue = vue == VueCalendrier.liste
        ? VueCalendrier.annuel
        : VueCalendrier.liste;
    notifyListeners();
  }

  // ─── Semaine courante / prochaine (bandeau, APP-118) ─────────────

  List<AlternanceSemaine> get _liste => data?.semaines ?? const [];

  /// true si [s] est la semaine en cours (les semaines sont des lundis)
  bool isSemaineCourante(AlternanceSemaine s) {
    final now = DateTime.now();
    final lundi = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return s.semaine.year == lundi.year &&
        s.semaine.month == lundi.month &&
        s.semaine.day == lundi.day;
  }

  /// La semaine en cours, si l'alternance la couvre
  AlternanceSemaine? get semaineCourante {
    for (final s in _liste) {
      if (isSemaineCourante(s)) return s;
    }
    return null;
  }

  /// La semaine suivant la semaine en cours ; à défaut de semaine
  /// courante, la première semaine à venir (alternance pas commencée).
  AlternanceSemaine? get semaineProchaine {
    final i = _liste.indexWhere(isSemaineCourante);
    if (i >= 0) return i + 1 < _liste.length ? _liste[i + 1] : null;
    final now = DateTime.now();
    for (final s in _liste) {
      if (s.semaine.isAfter(now)) return s;
    }
    return null;
  }

  // ─── Auto-scroll sur la semaine courante (APP-118) ───────────────

  /// Hauteurs fixes de la liste — partagées avec la View pour que le
  /// calcul d'offset du scroll reste exact (sticky header + cartes).
  static const double topGap = 8;
  static const double headerExtent = 30;
  static const double rowExtent = 80;
  static const double groupGap = 12;

  final ScrollController scrollController = ScrollController();

  /// Scrolle jusqu'à la semaine courante à l'ouverture de l'écran.
  /// Toutes les hauteurs étant fixes, l'offset se calcule sans mesurer.
  void scrollToSemaineCourante() {
    if (!scrollController.hasClients) return;

    double offset = topGap;
    var found = false;
    for (final entry in semainesParMois.entries) {
      offset += headerExtent;
      for (final s in entry.value) {
        if (isSemaineCourante(s)) {
          found = true;
          break;
        }
        offset += rowExtent;
      }
      if (found) break;
      offset += groupGap;
    }
    if (!found) return; // alternance pas commencée ou déjà finie

    // -rowExtent : laisse une carte de contexte au-dessus de la cible
    final target = (offset - rowExtent)
        .clamp(0.0, scrollController.position.maxScrollExtent);
    scrollController.animateTo(target,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
