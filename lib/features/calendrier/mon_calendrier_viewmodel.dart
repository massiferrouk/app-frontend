import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/calendrier_service.dart';
import '../../shared/models/mes_semaines.dart';

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
  Future<String?> override({
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
}
