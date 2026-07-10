import 'package:stacked/stacked.dart';

import '../../shared/models/enums.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/semaine_compatibilite.dart';

/// Logique du calendrier de compatibilité.
/// Pas d'appel réseau : les données arrivent avec la suggestion
/// (elles sont dans le payload de /matching/suggestions).
class CompatibiliteViewModel extends BaseViewModel {
  final MatchingSuggestion suggestion;

  CompatibiliteViewModel({required this.suggestion});

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
