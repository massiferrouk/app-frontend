import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/auth/profil_creation/profil_creation_viewmodel.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/alternant_profile.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockProfileService profile;
  late MockNavigationService nav;
  late ProfilCreationViewModel viewModel;

  final fakeProfile = AlternantProfile(
    id: 'profile-1',
    userId: 'user-1',
    villeA: 'Paris',
    villeB: 'Lyon',
    ecole: 'YNOV Paris',
    entreprise: 'ACME Lyon',
    dateDebut: DateTime(2026, 9, 1),
    dateFin: DateTime(2027, 8, 31),
    rythme: RythmeAlternance.SEMAINE_3_1,
  );

  setUpAll(() {
    registerFallbackValue(RythmeAlternance.SEMAINE_1_1);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    profile = MockProfileService();
    nav = MockNavigationService();
    viewModel = ProfilCreationViewModel(
      profileService: profile,
      navigationService: nav,
    );
  });

  void fillValidForm() {
    viewModel.villeAController.text = 'Paris';
    viewModel.villeBController.text = 'Lyon';
    viewModel.ecoleController.text = 'YNOV Paris';
    viewModel.entrepriseController.text = 'ACME Lyon';
    viewModel.setDateDebut(DateTime(2026, 9, 1));
    viewModel.setDateFin(DateTime(2027, 8, 31));
  }

  group('validation', () {
    test('champ requis manquant : erreur, aucun appel réseau', () async {
      await viewModel.submit();

      expect(viewModel.errorMessage,
          'Le nom de la ville de l\'école est requis');
      verifyNever(() => profile.createAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
          ));
    });

    test('villes identiques (insensible à la casse) : erreur métier',
        () async {
      fillValidForm();
      viewModel.villeBController.text = '  paris ';

      await viewModel.submit();

      expect(
          viewModel.errorMessage, 'Les deux villes doivent être différentes');
    });

    test('dates manquantes : erreur', () async {
      viewModel.villeAController.text = 'Paris';
      viewModel.villeBController.text = 'Lyon';
      viewModel.ecoleController.text = 'YNOV';
      viewModel.entrepriseController.text = 'ACME';

      await viewModel.submit();

      expect(viewModel.errorMessage,
          'Les dates de début et de fin sont requises');
    });

    test('dateDebut après dateFin : erreur', () async {
      fillValidForm();
      viewModel.setDateDebut(DateTime(2027, 9, 1));
      viewModel.setDateFin(DateTime(2026, 9, 1));

      await viewModel.submit();

      expect(viewModel.errorMessage,
          'La date de début doit être avant la date de fin');
    });
  });

  group('submit', () {
    test('succès : création puis navigation vers Home', () async {
      fillValidForm();

      when(() => profile.createAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
          )).thenAnswer((_) async => fakeProfile);
      when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);

      await viewModel.submit();

      expect(viewModel.errorMessage, isNull);
      verify(() => profile.createAlternantProfile(
            villeA: 'Paris',
            villeB: 'Lyon',
            ecole: 'YNOV Paris',
            entreprise: 'ACME Lyon',
            dateDebut: DateTime(2026, 9, 1),
            dateFin: DateTime(2027, 8, 31),
            rythme: RythmeAlternance.SEMAINE_1_1,
          )).called(1);
      verify(() => nav.clearStackAndShow(Routes.homeView)).called(1);
    });

    test('erreur backend : message affiché, pas de navigation', () async {
      fillValidForm();

      when(() => profile.createAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
          )).thenThrow(const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Données invalides',
        statusCode: 400,
      ));

      await viewModel.submit();

      expect(viewModel.errorMessage, 'Données invalides');
      verifyNever(() => nav.clearStackAndShow(any()));
    });
  });
}
