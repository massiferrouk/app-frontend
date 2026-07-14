import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/logements/ajouter_logement_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockLogementService logementService;
  late MockNavigationService nav;
  late AjouterLogementViewModel viewModel;

  final fakeLogement = Logement.fromJson({
    'id': 'log-1',
    'ownerId': 'user-1',
    'adresse': '12 rue de la Paix',
    'ville': 'Paris',
    'codePostal': '75001',
    'type': 'STUDIO',
    'surface': 25.0,
    'nbPieces': 1,
    'loyer': 800.0,
    'charges': 50.0,
    'statut': 'BROUILLON',
    'isVerified': false,
    'isMeuble': true,
  });

  setUpAll(() {
    registerFallbackValue(LogementType.STUDIO);
    registerFallbackValue(<XFile>[]);
  });

  setUp(() {
    logementService = MockLogementService();
    nav = MockNavigationService();
    viewModel = AjouterLogementViewModel(
      logementService: logementService,
      navigationService: nav,
    );
  });

  void fillValidForm() {
    viewModel.adresseController.text = '12 rue de la Paix';
    viewModel.villeController.text = 'Paris';
    viewModel.codePostalController.text = '75001';
    viewModel.surfaceController.text = '25';
    viewModel.loyerController.text = '800';
  }

  void stubCreate() {
    when(() => logementService.createLogement(
          adresse: any(named: 'adresse'),
          ville: any(named: 'ville'),
          codePostal: any(named: 'codePostal'),
          type: any(named: 'type'),
          surface: any(named: 'surface'),
          nbPieces: any(named: 'nbPieces'),
          loyer: any(named: 'loyer'),
          charges: any(named: 'charges'),
          description: any(named: 'description'),
          equipements: any(named: 'equipements'),
          isMeuble: any(named: 'isMeuble'),
        )).thenAnswer((_) async => fakeLogement);
  }

  group('validation', () {
    test('code postal invalide : erreur locale, aucun appel', () async {
      fillValidForm();
      viewModel.codePostalController.text = '7500';

      await viewModel.submit(publierMaintenant: false);

      expect(viewModel.errorMessage,
          'Le code postal doit contenir 5 chiffres');
      verifyNever(() => logementService.createLogement(
            adresse: any(named: 'adresse'),
            ville: any(named: 'ville'),
            codePostal: any(named: 'codePostal'),
            type: any(named: 'type'),
            surface: any(named: 'surface'),
            nbPieces: any(named: 'nbPieces'),
            loyer: any(named: 'loyer'),
            charges: any(named: 'charges'),
            description: any(named: 'description'),
            equipements: any(named: 'equipements'),
            isMeuble: any(named: 'isMeuble'),
          ));
    });

    test('surface non numérique ou nulle : erreur', () async {
      fillValidForm();
      viewModel.surfaceController.text = 'abc';

      await viewModel.submit(publierMaintenant: false);

      expect(viewModel.errorMessage, contains('surface'));
    });

    test('la virgule décimale française est acceptée', () async {
      fillValidForm();
      viewModel.surfaceController.text = '25,5';
      stubCreate();
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit(publierMaintenant: false);

      expect(viewModel.errorMessage, isNull);
      final captured = verify(() => logementService.createLogement(
            adresse: any(named: 'adresse'),
            ville: any(named: 'ville'),
            codePostal: any(named: 'codePostal'),
            type: any(named: 'type'),
            surface: captureAny(named: 'surface'),
            nbPieces: any(named: 'nbPieces'),
            loyer: any(named: 'loyer'),
            charges: any(named: 'charges'),
            description: any(named: 'description'),
            equipements: any(named: 'equipements'),
            isMeuble: any(named: 'isMeuble'),
          )).captured;
      expect(captured.single, 25.5);
    });
  });

  group('submit', () {
    test('brouillon : crée sans publier, retourne à la liste', () async {
      fillValidForm();
      stubCreate();
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit(publierMaintenant: false);

      verifyNever(() => logementService.publish(any()));
      verify(() => nav.back(result: true)).called(1);
    });

    test('publier maintenant : crée PUIS publie', () async {
      fillValidForm();
      stubCreate();
      when(() => logementService.publish('log-1'))
          .thenAnswer((_) async => fakeLogement);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit(publierMaintenant: true);

      verify(() => logementService.publish('log-1')).called(1);
    });

    test('avec photos : upload après création', () async {
      fillValidForm();
      viewModel.addPhoto(XFile('/tmp/photo1.jpg'));
      viewModel.addPhoto(XFile('/tmp/photo2.jpg'));
      stubCreate();
      when(() => logementService.addPhotos('log-1', any()))
          .thenAnswer((_) async => ['url1', 'url2']);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await viewModel.submit(publierMaintenant: false);

      // XFile n'a pas d'égalité par valeur : on vérifie l'appel avec les
      // 2 photos ajoutées via un matcher de longueur.
      final captured = verify(() => logementService.addPhotos(
          'log-1', captureAny())).captured.single as List<XFile>;
      expect(captured, hasLength(2));
    });

    test('erreur backend : message affiché, pas de retour', () async {
      fillValidForm();
      when(() => logementService.createLogement(
            adresse: any(named: 'adresse'),
            ville: any(named: 'ville'),
            codePostal: any(named: 'codePostal'),
            type: any(named: 'type'),
            surface: any(named: 'surface'),
            nbPieces: any(named: 'nbPieces'),
            loyer: any(named: 'loyer'),
            charges: any(named: 'charges'),
            description: any(named: 'description'),
            equipements: any(named: 'equipements'),
            isMeuble: any(named: 'isMeuble'),
          )).thenThrow(const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Données invalides',
        statusCode: 400,
      ));

      await viewModel.submit(publierMaintenant: false);

      expect(viewModel.errorMessage, 'Données invalides');
      verifyNever(() => nav.back(result: any(named: 'result')));
    });
  });

  group('photos', () {
    test('limite de 10 photos', () {
      for (var i = 0; i < 10; i++) {
        expect(viewModel.addPhoto(XFile('/tmp/p$i.jpg')), isTrue);
      }
      expect(viewModel.addPhoto(XFile('/tmp/p11.jpg')), isFalse);
      expect(viewModel.photos, hasLength(10));
    });
  });

  group('édition', () {
    test('pré-remplit le formulaire depuis le logement existant', () {
      final vm = AjouterLogementViewModel(
        existant: fakeLogement,
        logementService: logementService,
        navigationService: nav,
      );

      expect(vm.isEdition, isTrue);
      expect(vm.adresseController.text, '12 rue de la Paix');
      expect(vm.villeController.text, 'Paris');
      expect(vm.loyerController.text, '800');
      expect(vm.selectedType, LogementType.STUDIO);
    });

    test('submit en édition appelle updateLogement', () async {
      final vm = AjouterLogementViewModel(
        existant: fakeLogement,
        logementService: logementService,
        navigationService: nav,
      );

      when(() => logementService.updateLogement(
            logementId: any(named: 'logementId'),
            adresse: any(named: 'adresse'),
            ville: any(named: 'ville'),
            codePostal: any(named: 'codePostal'),
            type: any(named: 'type'),
            surface: any(named: 'surface'),
            nbPieces: any(named: 'nbPieces'),
            loyer: any(named: 'loyer'),
            charges: any(named: 'charges'),
            description: any(named: 'description'),
            equipements: any(named: 'equipements'),
            isMeuble: any(named: 'isMeuble'),
          )).thenAnswer((_) async => fakeLogement);
      when(() => nav.back(result: any(named: 'result'))).thenReturn(true);

      await vm.submit(publierMaintenant: false);

      verify(() => logementService.updateLogement(
            logementId: 'log-1',
            adresse: any(named: 'adresse'),
            ville: any(named: 'ville'),
            codePostal: any(named: 'codePostal'),
            type: any(named: 'type'),
            surface: any(named: 'surface'),
            nbPieces: any(named: 'nbPieces'),
            loyer: any(named: 'loyer'),
            charges: any(named: 'charges'),
            description: any(named: 'description'),
            equipements: any(named: 'equipements'),
            isMeuble: any(named: 'isMeuble'),
          )).called(1);
    });
  });
}
