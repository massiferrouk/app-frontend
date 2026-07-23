import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/admin/annonces_viewmodel.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService adminService;
  late AnnoncesViewModel viewModel;

  Logement annonce(
    String id, {
    LogementStatut statut = LogementStatut.ACTIF,
    String? moderationNote,
  }) =>
      Logement(
        id: id,
        ownerId: 'o1',
        adresse: '1 rue de la Paix',
        ville: 'Paris',
        codePostal: '75001',
        type: LogementType.STUDIO,
        surface: 25,
        nbPieces: 1,
        loyer: 700,
        charges: 0,
        statut: statut,
        isVerified: false,
        isMeuble: true,
        moderationNote: moderationNote,
      );

  ({List<Logement> logements, bool hasNext, int total}) page(
    List<Logement> items, {
    bool hasNext = false,
    int? total,
  }) =>
      (logements: items, hasNext: hasNext, total: total ?? items.length);

  setUp(() {
    adminService = MockAdminService();
    viewModel = AnnoncesViewModel(adminService: adminService);
  });

  group('load', () {
    test('charge la liste et le total', () async {
      when(() => adminService.logements(
                statut: any(named: 'statut'),
                page: any(named: 'page'),
              ))
          .thenAnswer((_) async => page([annonce('l1'), annonce('l2')], total: 9));

      await viewModel.load();

      expect(viewModel.annonces, hasLength(2));
      expect(viewModel.total, 9);
      expect(viewModel.errorMessage, isNull);
    });

    test('erreur API : message stocké', () async {
      when(() => adminService.logements(
            statut: any(named: 'statut'),
            page: any(named: 'page'),
          )).thenThrow(const ApiException(
        code: 'FORBIDDEN',
        message: 'Accès refusé',
        statusCode: 403,
      ));

      await viewModel.load();

      expect(viewModel.annonces, isEmpty);
      expect(viewModel.errorMessage, 'Accès refusé');
    });

    test('une annonce suspendue porte son motif', () async {
      when(() => adminService.logements(
                statut: any(named: 'statut'),
                page: any(named: 'page'),
              ))
          .thenAnswer((_) async => page([
                annonce('l1',
                    statut: LogementStatut.SUSPENDU,
                    moderationNote: 'Photos trompeuses')
              ]));

      await viewModel.load();

      expect(viewModel.annonces.first.moderationNote, 'Photos trompeuses');
    });
  });

  group('filtres', () {
    setUp(() {
      when(() => adminService.logements(
            statut: any(named: 'statut'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([]));
    });

    test('repasser le même filtre le retire', () async {
      await viewModel.setFiltreStatut(LogementStatut.SUSPENDU);
      expect(viewModel.filtreStatut, LogementStatut.SUSPENDU);

      await viewModel.setFiltreStatut(LogementStatut.SUSPENDU);

      expect(viewModel.filtreStatut, isNull);
    });

    test('changer de filtre repart de la première page', () async {
      await viewModel.setFiltreStatut(LogementStatut.ACTIF);

      verify(() => adminService.logements(
          statut: LogementStatut.ACTIF, page: 0)).called(1);
    });
  });

  group('suspendre', () {
    setUp(() {
      when(() => adminService.logements(
            statut: any(named: 'statut'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([annonce('l1')]));
    });

    test('suspend puis recharge depuis le serveur', () async {
      when(() => adminService.suspendreLogement(any(), any())).thenAnswer(
          (_) async => annonce('l1', statut: LogementStatut.SUSPENDU));
      await viewModel.load();

      final error = await viewModel.suspendre(annonce('l1'), '  Photos trompeuses ');

      expect(error, isNull);
      verify(() => adminService.suspendreLogement('l1', 'Photos trompeuses'))
          .called(1);
      // Le statut affiché doit venir du serveur, pas d'une supposition locale
      verify(() => adminService.logements(
          statut: any(named: 'statut'), page: any(named: 'page'))).called(2);
    });

    test('motif vide : refusé sans appel réseau', () async {
      final error = await viewModel.suspendre(annonce('l1'), '   ');

      expect(error, 'Le motif est obligatoire');
      verifyNever(() => adminService.suspendreLogement(any(), any()));
    });

    test('erreur API : message remonté', () async {
      await viewModel.load();
      when(() => adminService.suspendreLogement(any(), any()))
          .thenThrow(const ApiException(
        code: 'CONFLICT',
        message: 'Cette annonce est déjà suspendue',
        statusCode: 409,
      ));

      final error = await viewModel.suspendre(annonce('l1'), 'Motif');

      expect(error, 'Cette annonce est déjà suspendue');
    });
  });

  group('republier', () {
    test('republie puis recharge', () async {
      when(() => adminService.logements(
            statut: any(named: 'statut'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([annonce('l1')]));
      when(() => adminService.republierLogement('l1'))
          .thenAnswer((_) async => annonce('l1'));

      final error = await viewModel
          .republier(annonce('l1', statut: LogementStatut.SUSPENDU));

      expect(error, isNull);
      verify(() => adminService.republierLogement('l1')).called(1);
    });
  });
}
