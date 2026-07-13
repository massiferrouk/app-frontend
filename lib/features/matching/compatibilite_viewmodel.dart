import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/semaine_compatibilite.dart';

/// Logique du calendrier de compatibilité.
/// L'affichage n'appelle pas le réseau (données dans la suggestion),
/// seule la proposition d'accord fait un POST.
class CompatibiliteViewModel extends BaseViewModel {
  final MatchingSuggestion suggestion;
  final AccordService _accords;

  CompatibiliteViewModel(
      {required this.suggestion, AccordService? accordService})
      : _accords = accordService ?? locator<AccordService>();

  /// true si le type d'accord est un échange (nécessite les 2 logements).
  bool get _estEchange =>
      suggestion.typePropose == AccordType.ECHANGE_TOTAL ||
      suggestion.typePropose == AccordType.ECHANGE_PARTIEL;

  /// Envoie la demande d'accord au match affiché.
  /// Le type vient de l'algorithme (typePropose). Aucune date : le backend
  /// déduit la période commune des deux alternances.
  /// Retourne null si OK, un message d'erreur sinon.
  Future<String?> proposerAccord({String? message}) async {
    // Un échange n'est signable que si les deux logements sont publiés.
    if (_estEchange &&
        (suggestion.logementAId == null || suggestion.logementBId == null)) {
      return 'Match potentiel : vous devez tous les deux avoir publié votre '
          'logement pour proposer un échange.';
    }

    setBusy(true);
    try {
      await _accords.createAccord(
        receiverId: suggestion.userId,
        type: suggestion.typePropose,
        logementAId: suggestion.logementAId,
        logementBId: suggestion.logementBId,
        messageInitial: message,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      setBusy(false);
    }
  }

  static const _mois = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  /// Semaines groupées par mois (même logique que Mon calendrier)
  Map<String, List<SemaineCompatibilite>> get semainesParMois {
    final grouped = <String, List<SemaineCompatibilite>>{};
    for (final s in suggestion.semaines) {
      final key = '${_mois[s.semaine.month - 1]} ${s.semaine.year}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    return grouped;
  }

  /// Sous-titre explicatif d'une semaine selon son type
  String noteFor(SemaineCompatibilite s) => switch (s.type) {
        CompatibiliteType.ECHANGE => 'Vos logements se libèrent mutuellement',
        CompatibiliteType.COLOCATION => 'Coloc possible · Loyer partagé',
        CompatibiliteType.CHEVAUCHEMENT =>
          'Même ville en même temps — gérez entre vous',
        CompatibiliteType.INCOMPATIBLE => '',
      };
}
