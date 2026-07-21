import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/profil/profil_viewmodel.dart';
import 'package:studup_app/services/auth_service.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/services/chat_socket_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/alternant_profile.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/user.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockLogementService extends Mock implements LogementService {}

class MockAuthService extends Mock implements AuthService {}

class MockChatSocketService extends Mock implements ChatSocketService {}

class MockCandidatureService extends Mock implements CandidatureService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockProfileService profileService;
  late MockLogementService logementService;
  late MockAuthService authService;
  late MockChatSocketService socketService;
  late MockCandidatureService candidatureService;
  late MockNavigationService nav;
  late ProfilViewModel viewModel;

  const user = User(
    id: 'user-1',
    email: 'alice@studup.fr',
    firstName: 'Alice',
    lastName: 'Martin',
    role: UserRole.ALTERNANT,
    isVerified: true,
  );

  final fakeAlternantProfile = AlternantProfile(
    id: 'profile-1',
    userId: 'user-1',
    villeA: 'Paris',
    villeB: 'Lyon',
    ecole: 'YNOV Paris',
    entreprise: 'ACME Lyon',
    dateDebut: DateTime(2026, 9, 1),
    dateFin: DateTime(2027, 8, 31),
    rythme: RythmeAlternance.SEMAINE_1_1,
    premiereSemaine: PremiereSemaine.ECOLE,
  );

  setUp(() {
    profileService = MockProfileService();
    logementService = MockLogementService();
    authService = MockAuthService();
    socketService = MockChatSocketService();
    candidatureService = MockCandidatureService();
    nav = MockNavigationService();
    // Défaut : pas de profil alternant chargé (surchargé au besoin)
    when(() => profileService.getMyAlternantProfile())
        .thenAnswer((_) async => null);
    // Défaut : aucune candidature (enrichissement non bloquant du profil)
    when(() => candidatureService.getMesCandidatures())
        .thenAnswer((_) async => []);
    viewModel = ProfilViewModel(
      profileService: profileService,
      logementService: logementService,
      candidatureService: candidatureService,
      authService: authService,
      chatSocketService: socketService,
      navigationService: nav,
    );
  });

  group('load', () {
    test('charge identité + enrichissements', () async {
      when(() => profileService.getMe()).thenAnswer((_) async => user);
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => []);
      // Alternant : son profil d'alternance est aussi chargé (APP-117 · A-04)
      when(() => profileService.getMyAlternantProfile())
          .thenAnswer((_) async => fakeAlternantProfile);

      await viewModel.load();

      expect(viewModel.user!.fullName, 'Alice Martin');
      expect(viewModel.isAlternant, isTrue);
      expect(viewModel.alternantProfile!.rythme,
          RythmeAlternance.SEMAINE_1_1);
    });

    test('échec des enrichissements : profil affiché quand même', () async {
      when(() => profileService.getMe()).thenAnswer((_) async => user);
      when(() => logementService.getMesLogements()).thenThrow(
          const ApiException(
              code: 'ERROR', message: 'Erreur', statusCode: 500));

      await viewModel.load();

      expect(viewModel.user, isNotNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('échec de l\'identité : erreur bloquante', () async {
      when(() => profileService.getMe()).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.load();

      expect(viewModel.user, isNull);
      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('goToEditAlternance', () {
    test('sans profil chargé : ne navigue pas', () async {
      await viewModel.goToEditAlternance();

      verifyNever(() => nav.navigateTo(any(),
          arguments: any(named: 'arguments')));
    });

    test('profil modifié (retour true) : recharge le profil', () async {
      // Pré-charge un profil alternant
      when(() => profileService.getMe()).thenAnswer((_) async => user);
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => []);
      when(() => profileService.getMyAlternantProfile())
          .thenAnswer((_) async => fakeAlternantProfile);
      await viewModel.load();

      // La modification renvoie true → on doit recharger (getMe rappelé)
      when(() => nav.navigateTo(any(), arguments: any(named: 'arguments')))
          .thenAnswer((_) async => true);

      await viewModel.goToEditAlternance();

      // getMe : 1x au load initial + 1x au rechargement
      verify(() => profileService.getMe()).called(2);
    });
  });

  group('logout', () {
    test('coupe le WebSocket, révoque, purge et retourne au login',
        () async {
      when(() => authService.logout()).thenAnswer((_) async {});
      when(() => nav.clearStackAndShow(any()))
          .thenAnswer((_) async => null);

      await viewModel.logout();

      // APP-89 : l'ancien compte ne doit plus recevoir de messages
      verify(() => socketService.disconnect()).called(1);
      verify(() => authService.logout()).called(1);
      verify(() => nav.clearStackAndShow(any())).called(1);
    });
  });

  group('changeMode (APP-117)', () {
    test('canChangeMode/otherStudentMode selon le rôle', () {
      viewModel.user = user; // ALTERNANT
      expect(viewModel.canChangeMode, isTrue);
      expect(viewModel.otherStudentMode, UserRole.ETUDIANT);

      viewModel.user = const User(
          id: 'u2',
          email: 'e@e.fr',
          firstName: 'E',
          lastName: 'T',
          role: UserRole.ETUDIANT,
          isVerified: true);
      expect(viewModel.canChangeMode, isTrue);
      expect(viewModel.otherStudentMode, UserRole.ALTERNANT);

      // Un propriétaire ne peut pas changer de mode
      viewModel.user = const User(
          id: 'u3',
          email: 'p@p.fr',
          firstName: 'P',
          lastName: 'R',
          role: UserRole.PROPRIETAIRE,
          isVerified: true);
      expect(viewModel.canChangeMode, isFalse);
      expect(viewModel.otherStudentMode, isNull);
    });

    test('passe en étudiant : change le mode, rafraîchit, relance le menu',
        () async {
      when(() => profileService.changeMode(UserRole.ETUDIANT))
          .thenAnswer((_) async => user);
      when(() => authService.refreshSession()).thenAnswer((_) async {});
      when(() => nav.clearStackAndShow(any())).thenAnswer((_) async => null);

      await viewModel.changeMode(UserRole.ETUDIANT);

      verify(() => profileService.changeMode(UserRole.ETUDIANT)).called(1);
      verify(() => authService.refreshSession()).called(1);
      verify(() => nav.clearStackAndShow(any())).called(1);
      verifyNever(() => nav.navigateTo(any()));
    });

    test('passe en alternant sans profil : emmène au formulaire', () async {
      when(() => profileService.changeMode(UserRole.ALTERNANT))
          .thenAnswer((_) async => user);
      when(() => authService.refreshSession()).thenAnswer((_) async {});
      // getMyAlternantProfile → null (défaut du setUp) : pas encore de profil
      when(() => nav.navigateTo(any(), arguments: any(named: 'arguments')))
          .thenAnswer((_) async => null);

      await viewModel.changeMode(UserRole.ALTERNANT);

      verify(() => profileService.changeMode(UserRole.ALTERNANT)).called(1);
      verify(() => authService.refreshSession()).called(1);
      // L'ancien rôle voyage avec la route : le formulaire peut proposer
      // « Annuler » qui le rétablit (APP-119)
      verify(() => nav.navigateTo(Routes.profilCreationView,
          arguments: any(named: 'arguments'))).called(1);
      verifyNever(() => nav.clearStackAndShow(any()));
    });

    test('erreur backend : message affiché, pas de refresh ni navigation',
        () async {
      when(() => profileService.changeMode(UserRole.ALTERNANT)).thenThrow(
          const ApiException(
              code: 'INVALID_ARGUMENT',
              message: 'Le changement de mode n\'est possible '
                  'qu\'entre étudiant et alternant.',
              statusCode: 400));

      await viewModel.changeMode(UserRole.ALTERNANT);

      expect(viewModel.errorMessage, contains('étudiant et alternant'));
      verifyNever(() => authService.refreshSession());
      verifyNever(() => nav.clearStackAndShow(any()));
      verifyNever(() => nav.navigateTo(any()));
    });
  });
}
