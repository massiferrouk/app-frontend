import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/calendrier/mon_calendrier_viewmodel.dart';
import 'package:studup_app/services/calendrier_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/mes_semaines.dart';

class MockCalendrierService extends Mock implements CalendrierService {}

void main() {
  late MockCalendrierService calendrierService;
  late MonCalendrierViewModel viewModel;

  MesSemaines buildData() => MesSemaines.fromJson(const {
        'profileId': 'profile-1',
        'villeA': 'Paris',
        'villeB': 'Lyon',
        'rythme': 'SEMAINE_3_1',
        'semaines': [
          {
            'id': 's1',
            'semaine': '2026-07-27',
            'label': 'A',
            'isOverridden': false,
            'overrideReason': null,
          },
          {
            'id': 's2',
            'semaine': '2026-08-03',
            'label': 'A',
            'isOverridden': false,
            'overrideReason': null,
          },
          {
            'id': 's3',
            'semaine': '2026-08-10',
            'label': 'B',
            'isOverridden': true,
            'overrideReason': 'conges',
          },
        ],
      });

  setUp(() {
    calendrierService = MockCalendrierService();
    viewModel =
        MonCalendrierViewModel(calendrierService: calendrierService);
  });

  group('load', () {
    test('charge le calendrier et calcule la part villeA', () async {
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => buildData());

      await viewModel.load();

      expect(viewModel.data, isNotNull);
      expect(viewModel.data!.semaines, hasLength(3));
      // 2 semaines A sur 3
      expect(viewModel.data!.partVilleA, closeTo(0.666, 0.01));
      expect(viewModel.data!.villeFor('A'), 'Paris');
      expect(viewModel.data!.villeFor('B'), 'Lyon');
    });

    test('groupe les semaines par mois en français', () async {
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => buildData());

      await viewModel.load();
      final groupes = viewModel.semainesParMois;

      expect(groupes.keys, ['Juillet 2026', 'Août 2026']);
      expect(groupes['Juillet 2026'], hasLength(1));
      expect(groupes['Août 2026'], hasLength(2));
    });

    test('erreur API : message stocké', () async {
      when(() => calendrierService.getMesSemaines())
          .thenThrow(const ApiException(
        code: 'NOT_FOUND',
        message: 'Profil alternant introuvable — crée d\'abord ton profil',
        statusCode: 404,
      ));

      await viewModel.load();

      expect(viewModel.data, isNull);
      expect(viewModel.errorMessage, contains('Profil alternant'));
    });
  });

  group('isModifiable', () {
    test('une semaine passée n\'est pas modifiable', () {
      final passee = AlternanceSemaine(
        id: 's0',
        semaine: DateTime.now().subtract(const Duration(days: 14)),
        label: 'A',
        isOverridden: false,
      );
      final future = AlternanceSemaine(
        id: 's9',
        semaine: DateTime.now().add(const Duration(days: 14)),
        label: 'A',
        isOverridden: false,
      );

      expect(viewModel.isModifiable(passee), isFalse);
      expect(viewModel.isModifiable(future), isTrue);
    });
  });

  group('override', () {
    test('succès : appelle le service puis recharge', () async {
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => buildData());
      await viewModel.load();

      final semaine = viewModel.data!.semaines.first;
      when(() => calendrierService.overrideSemaine(
            profileId: 'profile-1',
            semaine: semaine.semaine,
            label: 'B',
            reason: 'conges',
          )).thenAnswer((_) async => semaine);

      final error = await viewModel.modifierSemaine(
          semaine: semaine, label: 'B', reason: 'conges');

      expect(error, isNull);
      // load() a été rappelé après l'override (1 initial + 1 reload)
      verify(() => calendrierService.getMesSemaines()).called(2);
    });

    test('échec backend : retourne le message d\'erreur', () async {
      when(() => calendrierService.getMesSemaines())
          .thenAnswer((_) async => buildData());
      await viewModel.load();

      final semaine = viewModel.data!.semaines.first;
      when(() => calendrierService.overrideSemaine(
            profileId: any(named: 'profileId'),
            semaine: any(named: 'semaine'),
            label: any(named: 'label'),
            reason: any(named: 'reason'),
          )).thenThrow(const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Impossible de modifier une semaine passée',
        statusCode: 400,
      ));

      final error = await viewModel.modifierSemaine(
          semaine: semaine, label: 'B', reason: 'conges');

      expect(error, contains('semaine passée'));
    });
  });

  group('vues et bandeau (APP-118)', () {
    // Lundi de la semaine en cours (les semaines backend sont des lundis)
    DateTime lundiCourant() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - (now.weekday - 1));
    }

    AlternanceSemaine semaine(String id, DateTime jour, String label) =>
        AlternanceSemaine(
            id: id, semaine: jour, label: label, isOverridden: false);

    test('cyclerVue bascule liste ⇄ annuel', () {
      expect(viewModel.vue, VueCalendrier.liste);
      viewModel.cyclerVue();
      expect(viewModel.vue, VueCalendrier.annuel);
      viewModel.cyclerVue();
      expect(viewModel.vue, VueCalendrier.liste);
    });

    test('semaine courante et prochaine repérées', () async {
      final lundi = lundiCourant();
      when(() => calendrierService.getMesSemaines()).thenAnswer((_) async =>
          MesSemaines(
            profileId: 'p',
            villeA: 'Paris',
            villeB: 'Lyon',
            rythme: RythmeAlternance.SEMAINE_3_1,
            semaines: [
              semaine('a', lundi, 'A'),
              semaine('b', lundi.add(const Duration(days: 7)), 'B'),
            ],
          ));

      await viewModel.load();

      expect(viewModel.semaineCourante?.id, 'a');
      expect(viewModel.semaineProchaine?.id, 'b');
    });

    test('alternance pas commencée : pas de courante, prochaine à venir',
        () async {
      final lundi = lundiCourant();
      when(() => calendrierService.getMesSemaines()).thenAnswer((_) async =>
          MesSemaines(
            profileId: 'p',
            villeA: 'Paris',
            villeB: 'Lyon',
            rythme: RythmeAlternance.SEMAINE_3_1,
            semaines: [
              semaine('futur1', lundi.add(const Duration(days: 14)), 'A'),
              semaine('futur2', lundi.add(const Duration(days: 21)), 'B'),
            ],
          ));

      await viewModel.load();

      expect(viewModel.semaineCourante, isNull);
      expect(viewModel.semaineProchaine?.id, 'futur1');
    });
  });
}
