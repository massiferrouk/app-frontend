import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/features/matching/compatibilite_viewmodel.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

void main() {
  MatchingSuggestion buildSuggestion() =>
      MatchingSuggestion.fromJson(const {
        'profileId': 'p-1',
        'userId': 'u-1',
        'prenom': 'Thomas',
        'nom': 'Durand',
        'villeA': 'Lyon',
        'villeB': 'Paris',
        'score': 0.75,
        'scorePercent': 75,
        'typePropose': 'ECHANGE_PARTIEL',
        'isMatchActif': true,
        'messageMatchPotentiel': null,
        'nbSemainesEchange': 3,
        'nbSemainesColocation': 0,
        'nbSemainesChevauchement': 1,
        'messageResume': 'Vos rythmes sont compatibles à 75%.',
        'semaines': [
          {
            'semaine': '2026-07-27',
            'villeAlternantA': 'Paris',
            'villeAlternantB': 'Lyon',
            'type': 'ECHANGE',
            'couleurHex': '#27AE60',
            'label': 'Échange',
          },
          {
            'semaine': '2026-08-03',
            'villeAlternantA': 'Paris',
            'villeAlternantB': 'Paris',
            'type': 'CHEVAUCHEMENT',
            'couleurHex': '#F39C12',
            'label': 'Chevauchement',
          },
          {
            'semaine': '2026-08-10',
            'villeAlternantA': 'Lyon',
            'villeAlternantB': 'Lyon',
            'type': 'COLOCATION',
            'couleurHex': '#3498DB',
            'label': 'Coloc possible',
          },
        ],
      });

  group('CompatibiliteViewModel', () {
    test('parse les semaines du payload suggestions', () {
      final viewModel =
          CompatibiliteViewModel(suggestion: buildSuggestion());

      expect(viewModel.suggestion.semaines, hasLength(3));
      expect(viewModel.suggestion.semaines[0].type,
          CompatibiliteType.ECHANGE);
      expect(viewModel.suggestion.semaines[1].type,
          CompatibiliteType.CHEVAUCHEMENT);
    });

    test('groupe les semaines par mois', () {
      final viewModel =
          CompatibiliteViewModel(suggestion: buildSuggestion());

      final groupes = viewModel.semainesParMois;

      expect(groupes.keys, ['Juillet 2026', 'Août 2026']);
      expect(groupes['Août 2026'], hasLength(2));
    });

    test('note explicative selon le type de semaine', () {
      final viewModel =
          CompatibiliteViewModel(suggestion: buildSuggestion());
      final semaines = viewModel.suggestion.semaines;

      expect(viewModel.noteFor(semaines[0]), contains('libèrent'));
      expect(viewModel.noteFor(semaines[1]), contains('gérez entre vous'));
      expect(viewModel.noteFor(semaines[2]), contains('Loyer partagé'));
    });
  });
}
