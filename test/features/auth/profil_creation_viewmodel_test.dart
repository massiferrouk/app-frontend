import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/auth/profil_creation/profil_creation_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/alternant_profile.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/user.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockProfileService profile;
  late MockNavigationService nav;
  late MockAuthService auth;
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
    premiereSemaine: PremiereSemaine.ENTREPRISE,
  );

  setUpAll(() {
    registerFallbackValue(RythmeAlternance.SEMAINE_1_1);
    registerFallbackValue(PremiereSemaine.ECOLE);
    registerFallbackValue(UserRole.ETUDIANT);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    profile = MockProfileService();
    nav = MockNavigationService();
    auth = MockAuthService();
    viewModel = ProfilCreationViewModel(
      profileService: profile,
      navigationService: nav,
      authService: auth,
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

  group('rythmes proposés', () {
    test('AUTRE est retiré du choix (APP-110), les 4 rythmes définis restent',
        () {
      expect(RythmeAlternance.selectable,
          isNot(contains(RythmeAlternance.AUTRE)));
      expect(RythmeAlternance.selectable, hasLength(4));
    });
  });

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
            premiereSemaine: any(named: 'premiereSemaine'),
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
            premiereSemaine: any(named: 'premiereSemaine'),
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
            // Défaut du 1-1 : le cycle commence par l'école
            premiereSemaine: PremiereSemaine.ECOLE,
          )).called(1);
      verify(() => nav.clearStackAndShow(Routes.mainView)).called(1);
    });

    test('le choix explicite de la première semaine est envoyé', () async {
      fillValidForm();
      // L'utilisateur inverse son cycle : 1 sem entreprise PUIS 1 sem école
      viewModel.selectPremiereSemaine(PremiereSemaine.ENTREPRISE);

      when(() => profile.createAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
            premiereSemaine: any(named: 'premiereSemaine'),
          )).thenAnswer((_) async => fakeProfile);
      when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);

      await viewModel.submit();

      verify(() => profile.createAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
            premiereSemaine: PremiereSemaine.ENTREPRISE,
          )).called(1);
    });

    test('changer de rythme réaligne le défaut de première semaine', () {
      // Défaut initial : 1-1 → ECOLE
      expect(viewModel.selectedPremiereSemaine, PremiereSemaine.ECOLE);

      // Le 3-1 démarre historiquement en entreprise
      viewModel.selectRythme(RythmeAlternance.SEMAINE_3_1);
      expect(viewModel.selectedPremiereSemaine, PremiereSemaine.ENTREPRISE);

      // Retour à un rythme symétrique → ECOLE
      viewModel.selectRythme(RythmeAlternance.SEMAINE_2_2);
      expect(viewModel.selectedPremiereSemaine, PremiereSemaine.ECOLE);
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
            premiereSemaine: any(named: 'premiereSemaine'),
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

  // ─── Mode édition (APP-117 · A-04) ──────────────────────────────────
  group('édition', () {
    ProfilCreationViewModel makeEditVm() => ProfilCreationViewModel(
          existingProfile: fakeProfile,
          profileService: profile,
          navigationService: nav,
      authService: auth,
        );

    test('pré-remplit le formulaire depuis le profil existant', () {
      final vm = makeEditVm();

      expect(vm.isEdition, isTrue);
      expect(vm.villeAController.text, 'Paris');
      expect(vm.villeBController.text, 'Lyon');
      expect(vm.ecoleController.text, 'YNOV Paris');
      expect(vm.entrepriseController.text, 'ACME Lyon');
      expect(vm.selectedRythme, RythmeAlternance.SEMAINE_3_1);
      expect(vm.selectedPremiereSemaine, PremiereSemaine.ENTREPRISE);
      expect(vm.dateDebut, DateTime(2026, 9, 1));
      expect(vm.dateFin, DateTime(2027, 8, 31));
    });

    test('succès : appelle updateAlternantProfile puis revient (result true)',
        () async {
      final vm = makeEditVm();
      // L'utilisateur corrige sa ville d'école
      vm.villeAController.text = 'Bordeaux';

      when(() => profile.updateAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
            premiereSemaine: any(named: 'premiereSemaine'),
          )).thenAnswer((_) async => fakeProfile);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await vm.submit();

      expect(vm.errorMessage, isNull);
      verify(() => profile.updateAlternantProfile(
            villeA: 'Bordeaux',
            villeB: 'Lyon',
            ecole: 'YNOV Paris',
            entreprise: 'ACME Lyon',
            dateDebut: DateTime(2026, 9, 1),
            dateFin: DateTime(2027, 8, 31),
            rythme: RythmeAlternance.SEMAINE_3_1,
            premiereSemaine: PremiereSemaine.ENTREPRISE,
          )).called(1);
      // Retour au profil avec signal de mise à jour ; jamais createAlternant
      verify(() => nav.back(result: true)).called(1);
      verifyNever(() => nav.clearStackAndShow(any()));
    });

    test('erreur backend en édition : message affiché, pas de retour',
        () async {
      final vm = makeEditVm();

      when(() => profile.updateAlternantProfile(
            villeA: any(named: 'villeA'),
            villeB: any(named: 'villeB'),
            ecole: any(named: 'ecole'),
            entreprise: any(named: 'entreprise'),
            dateDebut: any(named: 'dateDebut'),
            dateFin: any(named: 'dateFin'),
            rythme: any(named: 'rythme'),
            premiereSemaine: any(named: 'premiereSemaine'),
          )).thenThrow(const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Dates invalides',
        statusCode: 400,
      ));

      await vm.submit();

      expect(vm.errorMessage, 'Dates invalides');
      verifyNever(() => nav.back(result: any(named: 'result')));
    });
  });

  group('annulation du changement de mode (APP-119)', () {
    ProfilCreationViewModel makeVmAvecAnnulation() => ProfilCreationViewModel(
          roleAnnulation: UserRole.ETUDIANT,
          profileService: profile,
          navigationService: nav,
          authService: auth,
        );

    test('peutAnnuler : uniquement à l\'ouverture via « Changer de mode »',
        () {
      // Parcours d'inscription : création obligatoire, pas d'annulation
      expect(viewModel.peutAnnuler, isFalse);
      // Changement de mode : annulation proposée
      expect(makeVmAvecAnnulation().peutAnnuler, isTrue);
    });

    test('annuler rétablit l\'ancien rôle puis revient au Profil', () async {
      when(() => profile.changeMode(UserRole.ETUDIANT))
          .thenAnswer((_) async => User.fromJson(const {
                'id': 'u1',
                'email': 'massi@studup.fr',
                'firstName': 'Massi',
                'lastName': 'F',
                'role': 'ETUDIANT',
              }));
      when(() => auth.refreshSession()).thenAnswer((_) async {});
      when(() => nav.back()).thenReturn(true);

      final vm = makeVmAvecAnnulation();
      await vm.annulerChangementMode();

      // L'ordre compte : rôle rétabli côté serveur, session rafraîchie
      // (token à jour), PUIS retour — sur l'écran Profil d'où l'utilisateur
      // venait, pas sur l'accueil (un Annuler ramène là où on était)
      verifyInOrder([
        () => profile.changeMode(UserRole.ETUDIANT),
        () => auth.refreshSession(),
        () => nav.back(),
      ]);
      verifyNever(() => nav.clearStackAndShow(any()));
    });

    test('échec réseau : on reste sur le formulaire avec un message',
        () async {
      when(() => profile.changeMode(any())).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      final vm = makeVmAvecAnnulation();
      await vm.annulerChangementMode();

      // Quitter quand même laisserait un alternant sans profil : on ne
      // navigue pas, l'utilisateur voit l'erreur et peut réessayer
      expect(vm.errorMessage, 'Hors ligne');
      verifyNever(() => nav.back());
    });

    test('sans roleAnnulation (inscription) : aucune action', () async {
      await viewModel.annulerChangementMode();

      verifyNever(() => profile.changeMode(any()));
      verifyNever(() => nav.back());
    });
  });
}
