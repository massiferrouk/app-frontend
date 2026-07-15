import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/shared/models/accord.dart';
import 'package:studup_app/features/matching/compatibilite_viewmodel.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';
import 'package:studup_app/shared/models/semaine_compatibilite.dart';

class MockAccordService extends Mock implements AccordService {}

void main() {
  // Match actif : les deux logements sont publiés (IDs non nuls).
  MatchingSuggestion buildSuggestion({
    bool actif = true,
  }) =>
      MatchingSuggestion.fromJson({
        'profileId': 'p-1',
        'userId': 'u-1',
        'prenom': 'Thomas',
        'nom': 'Durand',
        'villeA': 'Lyon',
        'villeB': 'Paris',
        'score': 0.75,
        'scorePercent': 75,
        'typePropose': 'ECHANGE_PARTIEL',
        'isMatchActif': actif,
        'messageMatchPotentiel': null,
        'nbSemainesEchange': 3,
        'nbSemainesColocation': 0,
        'nbSemainesChevauchement': 1,
        'messageResume': 'Vos rythmes sont compatibles à 75%.',
        'logementAId': actif ? 'log-a' : null,
        'logementBId': actif ? 'log-b' : null,
        'economieMensuelle': actif ? 225 : 0,
        'semaines': const [
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

    test('explication complète par type pour la bottom sheet (APP-100)', () {
      final viewModel = CompatibiliteViewModel(
          suggestion: buildSuggestion(), accordService: MockAccordService());

      // L'échange mentionne le prénom du match pour personnaliser
      expect(viewModel.explicationFor(CompatibiliteType.ECHANGE),
          contains(viewModel.suggestion.displayName));
      expect(viewModel.explicationFor(CompatibiliteType.COLOCATION),
          contains('moitié du'));
      expect(viewModel.explicationFor(CompatibiliteType.CHEVAUCHEMENT),
          contains('organiser entre vous'));
      expect(viewModel.explicationFor(CompatibiliteType.INCOMPATIBLE),
          isNotEmpty);
    });

    test('économie mensuelle parsée et formatée (APP-103)', () {
      final viewModel = CompatibiliteViewModel(
          suggestion: buildSuggestion(), accordService: MockAccordService());

      expect(viewModel.suggestion.economieMensuelle, 225);
      expect(viewModel.suggestion.hasEconomie, isTrue);
      expect(viewModel.suggestion.economieLabel, contains('225 €/mois'));
    });

    test('pas de loyer connu : aucune économie affichable (APP-103)', () {
      final viewModel = CompatibiliteViewModel(
          suggestion: buildSuggestion(actif: false),
          accordService: MockAccordService());

      expect(viewModel.suggestion.hasEconomie, isFalse);
    });

    test('toggleFiltre ne garde que les semaines du type choisi (APP-100)',
        () {
      final viewModel = CompatibiliteViewModel(
          suggestion: buildSuggestion(), accordService: MockAccordService());

      viewModel.toggleFiltre(CompatibiliteType.COLOCATION);
      final filtrees =
          viewModel.semainesParMois.values.expand((s) => s).toList();
      expect(filtrees, hasLength(1));
      expect(filtrees.single.type, CompatibiliteType.COLOCATION);

      // Re-tap sur la même tuile : le filtre se désactive
      viewModel.toggleFiltre(CompatibiliteType.COLOCATION);
      expect(viewModel.filtre, isNull);
      expect(viewModel.semainesParMois.values.expand((s) => s), hasLength(3));
    });

    test('isSemaineCourante détecte le lundi de la semaine en cours (APP-100)',
        () {
      final viewModel = CompatibiliteViewModel(
          suggestion: buildSuggestion(), accordService: MockAccordService());

      final now = DateTime.now();
      final lundi = DateTime(now.year, now.month, now.day - (now.weekday - 1));

      final semaineCourante = SemaineCompatibilite(
        semaine: lundi,
        villeAlternantA: 'Paris',
        villeAlternantB: 'Lyon',
        type: CompatibiliteType.ECHANGE,
        couleurHex: '#27AE60',
        label: 'Échange',
      );

      expect(viewModel.isSemaineCourante(semaineCourante), isTrue);
      // Les semaines du payload (2026) ne sont pas la semaine courante
      for (final s in viewModel.suggestion.semaines) {
        expect(viewModel.isSemaineCourante(s),
            s.semaine == lundi ? isTrue : isFalse);
      }
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
    });

    test('envoie la demande avec le type et les 2 logements, sans dates',
        () async {
      when(() => accordService.createAccord(
            receiverId: any(named: 'receiverId'),
            type: any(named: 'type'),
            logementAId: any(named: 'logementAId'),
            logementBId: any(named: 'logementBId'),
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

      final error = await viewModel.proposerAccord(message: 'Salut !');

      expect(error, isNull);

      verify(() => accordService.createAccord(
            receiverId: 'u-1',
            type: AccordType.ECHANGE_PARTIEL, // le typePropose du match
            logementAId: 'log-a',
            logementBId: 'log-b',
            messageInitial: 'Salut !',
          )).called(1);
    });

    test('match potentiel (logements manquants) : erreur locale sans réseau',
        () async {
      // Suggestion sans logements publiés → échange non signable
      viewModel = CompatibiliteViewModel(
        suggestion: buildSuggestion(actif: false),
        accordService: accordService,
      );

      final error = await viewModel.proposerAccord();

      expect(error, contains('Match potentiel'));
      verifyNever(() => accordService.createAccord(
            receiverId: any(named: 'receiverId'),
            type: any(named: 'type'),
            logementAId: any(named: 'logementAId'),
            logementBId: any(named: 'logementBId'),
            messageInitial: any(named: 'messageInitial'),
          ));
    });
  });
}
