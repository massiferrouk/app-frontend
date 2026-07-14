import 'package:flutter/widgets.dart';
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

  // ─── Filtre par type (tap sur une tuile stat, APP-100) ──────────

  /// Type actuellement filtré — null = tout afficher
  CompatibiliteType? filtre;

  /// Tap sur une tuile : active le filtre, re-tap : le désactive.
  /// On remonte en haut de liste pour éviter un scroll orphelin.
  void toggleFiltre(CompatibiliteType type) {
    filtre = filtre == type ? null : type;
    if (scrollController.hasClients) scrollController.jumpTo(0);
    notifyListeners();
  }

  /// Semaines groupées par mois, filtre appliqué
  Map<String, List<SemaineCompatibilite>> get semainesParMois {
    final grouped = <String, List<SemaineCompatibilite>>{};
    for (final s in suggestion.semaines) {
      if (filtre != null && s.type != filtre) continue;
      final key = '${_mois[s.semaine.month - 1]} ${s.semaine.year}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    return grouped;
  }

  // ─── Semaine courante + auto-scroll (APP-100) ───────────────────

  /// Hauteurs fixes de la liste — partagées avec la View pour que le
  /// calcul d'offset du scroll reste exact (sticky header + rows).
  static const double topGap = 8;
  static const double headerExtent = 34;
  static const double rowExtent = 46;
  static const double groupGap = 16;

  final ScrollController scrollController = ScrollController();

  /// true si [s] est la semaine en cours (les semaines sont des lundis)
  bool isSemaineCourante(SemaineCompatibilite s) {
    final now = DateTime.now();
    final lundi = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return s.semaine.year == lundi.year &&
        s.semaine.month == lundi.month &&
        s.semaine.day == lundi.day;
  }

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

    // -rowExtent : laisse une row de contexte au-dessus de la cible
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

  /// Sous-titre explicatif d'une semaine selon son type
  String noteFor(SemaineCompatibilite s) => switch (s.type) {
        CompatibiliteType.ECHANGE => 'Vos logements se libèrent mutuellement',
        CompatibiliteType.COLOCATION => 'Coloc possible · Loyer partagé',
        CompatibiliteType.CHEVAUCHEMENT =>
          'Même ville en même temps — gérez entre vous',
        CompatibiliteType.INCOMPATIBLE => '',
      };

  /// Explication complète d'un type de semaine — affichée dans la bottom
  /// sheet au tap sur une semaine (le texte est retiré des cartes, APP-100).
  String explicationFor(CompatibiliteType type) => switch (type) {
        CompatibiliteType.ECHANGE =>
          'Cette semaine, vous êtes chacun dans la ville de l\'autre : '
              'vos logements se libèrent mutuellement. Tu peux loger chez '
              '${suggestion.displayName} et inversement — sans payer de '
              'loyer supplémentaire.',
        CompatibiliteType.COLOCATION =>
          'Cette semaine, vous êtes tous les deux dans la même ville. '
              'En partageant un seul logement, chacun paie la moitié du '
              'loyer au lieu d\'un loyer plein.',
        CompatibiliteType.CHEVAUCHEMENT =>
          'Vous êtes dans la même ville en même temps, mais de façon '
              'ponctuelle. Ni échange ni coloc structurelle cette semaine : '
              'à vous de vous organiser entre vous si vous signez un accord.',
        CompatibiliteType.INCOMPATIBLE =>
          'Cette semaine, vos positions ne permettent ni échange ni '
              'colocation. Rien à faire, c\'est juste une semaine neutre.',
      };
}
