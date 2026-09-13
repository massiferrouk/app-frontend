import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Autocomplétion des villes du profil alternant (APP-122).
///
/// Charge UNE fois la liste des communes françaises embarquée en asset, puis
/// filtre en local — aucun appel réseau. But : forcer une saisie canonique
/// (tout le monde choisit exactement la même chaîne « Marseille »), pour ne pas
/// rater de match à cause d'une faute de frappe (« Marseile ») — le matching
/// compare les villes par égalité de texte.
class VilleService {
  static const _assetPath = 'assets/villes_france.json';

  /// Liste triée des communes, mise en cache après le premier chargement.
  List<String>? _villes;

  Future<List<String>> _chargerVilles() async {
    if (_villes != null) return _villes!;
    final raw = await rootBundle.loadString(_assetPath);
    _villes = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return _villes!;
  }

  /// Communes dont le nom CONTIENT [query] (insensible à la casse, aux accents
  /// et aux séparateurs « - / ' »). Query vide → début de liste. Résultats
  /// plafonnés à [limite] pour garder le menu déroulant réactif.
  Future<List<String>> rechercher(String query, {int limite = 50}) async {
    final villes = await _chargerVilles();
    final q = _normaliser(query);
    if (q.isEmpty) return villes.take(limite).toList();

    final resultats = <String>[];
    for (final v in villes) {
      if (_normaliser(v).contains(q)) {
        resultats.add(v);
        if (resultats.length >= limite) break;
      }
    }
    return resultats;
  }

  /// Minuscule, suppression des accents et unification des séparateurs :
  /// « St-Étienne », « st etienne » et « Saint Etienne »… se comparent sur la
  /// même base. (« saint » vs « st » n'est pas géré : hors périmètre.)
  static String _normaliser(String s) {
    s = s.toLowerCase().trim().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
    const to = 'aaaaaceeeeiiiinooooouuuuyy';
    final sb = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final idx = from.indexOf(ch);
      sb.write(idx >= 0 ? to[idx] : ch);
    }
    return sb
        .toString()
        .replaceAll(RegExp("[-'’/]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
