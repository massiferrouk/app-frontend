import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/features/matching/compatibilite_viewmodel.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

class MockAccordService extends Mock implements AccordService {}

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
          CompatibiliteViewModel(suggestion: buildSuggestion(), accordService: MockAccordService());

      expect(viewModel.suggestion.semaines, hasLength(3));
      expect(viewModel.suggestion.semaines[0].type,
          CompatibiliteType.ECHANGE);
      expect(viewModel.suggestion.semaines[1].type,
          CompatibiliteType.CHEVAUCHEMENT);
    });

    test('groupe les semaines par mois', () {
      final viewModel =
          CompatibiliteViewModel(suggestion: buildSuggestion(), accordService: MockAccordService());

      final groupes = viewModel.semainesParMois;

      expect(groupes.keys, ['Juillet 2026', 'Août 2026']);
      expect(groupes['Août 2026'], hasLength(2));
    });

    test('note explicative selon le type de semaine', () {
      final viewModel =
          CompatibiliteViewModel(suggestion: buildSuggestion(), accordService: MockAccordService());
      final semaines = viewModel.suggestion.semaines;

      expect(viewModel.noteFor(semaines[0]), contains('libèrent'));
      expect(viewModel.noteFor(semaines[1]), contains('gérez entre vous'));
      expect(viewModel.noteFor(semaines[2]), contains('Loyer partagé'));
    });
  });

  group('proposerAccord', () {
    late MockAccordService accordService;
    late CompatibiliteViewModel viewModel;

    setUp(() {
      accordService = MockAccordService();
      viewModel = CompatibiliteViewModel(
        suggestion: buildSuggestion(),
        accordService: accordService,
      );
    });

    setUpAll(() {
      registerFallbackValue(AccordType.ECHANGE_TOTAL);
      registerFallbackValue(DateTime(2026));
    });

    test('envoie la demande avec le type proposé par l\'algorithme',
        () async {
      when(() => accordService.createAccord(
            receiverId: any(named: 'receiverId'),
            type: any(named: 'type'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            messageInitial: any(named: 'messageInitial'),
          )).thenAnswer((_) async => Accord.fromJson({
            'id': 'a1',
            'initiatorId': 'moi',
            'receiverId': 'u-1',
            'type': 'ECHANGE_PARTIEL',
            'statut': 'EN_ATTENTE',
            'dateDebut': '2026-09-01',
            'dateFin': '2026-12-31',
            'createdAt': DateTime.now().toIso8601String(),
          }));

      final error = await viewModel.proposerAccord(
        dateDebut: DateTime(2026, 9, 1),
        dateFin: DateTime(2026, 12, 31),
        message: 'Salut !',
      );

      expect(error, isNull);

      verify(() => accordService.createAccord(
            receiverId: 'u-1',
            type: AccordType.ECHANGE_PARTIEL, // le typePropose du match
            dateDebut: DateTime(2026, 9, 1),
            dateFin: DateTime(2026, 12, 31),
            messageInitial: 'Salut !',
          )).called(1);
    });

    test('dates incohérentes : erreur locale sans appel réseau', () async {
      final error = await viewModel.proposerAccord(
        dateDebut: DateTime(2026, 12, 31),
        dateFin: DateTime(2026, 9, 1),
      );

      expect(error, contains('date de début'));
      verifyNever(() => accordService.createAccord(
            receiverId: any(named: 'receiverId'),
            type: any(named: 'type'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            messageInitial: any(named: 'messageInitial'),
          ));
    });
  });
}
