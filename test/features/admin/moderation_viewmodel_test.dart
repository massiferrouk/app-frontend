import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/admin/moderation_viewmodel.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';
import 'package:studup_app/shared/models/logement_report.dart';
import 'package:studup_app/shared/models/message_report.dart';

class MockAdminService extends Mock implements AdminService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockAdminService adminService;
  late ModerationViewModel viewModel;

  MessageReport signalement(
    String id, {
    String messageId = 'm1',
    String? contenu = 'Contenu signalé',
  }) =>
      MessageReport(
        id: id,
        messageId: messageId,
        reporterId: 'r1',
        motif: 'Propos déplacés',
        createdAt: DateTime(2026, 6, 1),
        contenuMessage: contenu,
        auteurId: 'a1',
        auteurNom: contenu == null ? null : 'Bob B',
        messageCreeLe: contenu == null ? null : DateTime(2026, 5, 30),
        signalePar: 'Alice A',
      );

  ({List<MessageReport> signalements, bool hasNext, int total}) page(
    List<MessageReport> items, {
    bool hasNext = false,
    int? total,
  }) =>
      (signalements: items, hasNext: hasNext, total: total ?? items.length);

  setUp(() {
    adminService = MockAdminService();
    viewModel = ModerationViewModel(
      adminService: adminService,
      navigationService: MockNavigationService(),
    );
  });

  group('load', () {
    test('charge la file avec le contexte de chaque signalement', () async {
      when(() => adminService.signalements(page: any(named: 'page')))
          .thenAnswer((_) async => page([signalement('s1')], total: 7));

      await viewModel.load();

      expect(viewModel.signalements, hasLength(1));
      expect(viewModel.total, 7);
      // Le contexte est ce qui permet de trancher (APP-121)
      expect(viewModel.signalements.first.contenuMessage, 'Contenu signalé');
      expect(viewModel.signalements.first.signalePar, 'Alice A');
      expect(viewModel.errorMessage, isNull);
    });

    test('erreur API : message stocké', () async {
      when(() => adminService.signalements(page: any(named: 'page')))
          .thenThrow(const ApiException(
        code: 'FORBIDDEN',
        message: 'Accès refusé',
        statusCode: 403,
      ));

      await viewModel.load();

      expect(viewModel.signalements, isEmpty);
      expect(viewModel.errorMessage, 'Accès refusé');
    });

    test('message disparu : le signalement reste consultable', () async {
      when(() => adminService.signalements(page: any(named: 'page')))
          .thenAnswer(
              (_) async => page([signalement('s1', contenu: null)]));

      await viewModel.load();

      expect(viewModel.signalements, hasLength(1));
      // L'écran doit le dire plutôt que d'afficher un blanc
      expect(viewModel.signalements.first.contenuDisponible, isFalse);
    });
  });

  group('pagination', () {
    test('chargerPlus ajoute à la file', () async {
      when(() => adminService.signalements(page: 0))
          .thenAnswer((_) async => page([signalement('s1')], hasNext: true));
      when(() => adminService.signalements(page: 1))
          .thenAnswer((_) async => page([signalement('s2')]));

      await viewModel.load();
      await viewModel.chargerPlus();

      expect(viewModel.signalements.map((s) => s.id), ['s1', 's2']);
      expect(viewModel.peutChargerPlus, isFalse);
    });
  });

  group('masquer', () {
    test('masque le message puis recharge la file', () async {
      when(() => adminService.signalements(page: any(named: 'page')))
          .thenAnswer((_) async => page([signalement('s1')]));
      when(() => adminService.masquerMessage(any(), any()))
          .thenAnswer((_) async {});
      await viewModel.load();

      final error =
          await viewModel.masquer(signalement('s1'), 'Insultes répétées');

      expect(error, isNull);
      // C'est le messageId qui est masqué, pas l'id du signalement
      verify(() => adminService.masquerMessage('m1', 'Insultes répétées'))
          .called(1);
      // Un même message peut avoir plusieurs signalements : le masquer les
      // fait TOUS disparaître, d'où le rechargement complet plutôt qu'un
      // retrait local de la seule carte cliquée.
      verify(() => adminService.signalements(page: any(named: 'page')))
          .called(2);
    });

    test('erreur : message remonté, rien n\'est rechargé', () async {
      when(() => adminService.signalements(page: any(named: 'page')))
          .thenAnswer((_) async => page([signalement('s1')]));
      await viewModel.load();
      when(() => adminService.masquerMessage(any(), any()))
          .thenThrow(const ApiException(
        code: 'NOT_FOUND',
        message: 'Message introuvable',
        statusCode: 404,
      ));

      final error = await viewModel.masquer(signalement('s1'), 'Motif');

      expect(error, 'Message introuvable');
    });
  });

  group('file des annonces signalées (APP-121)', () {
    LogementReport annonce(String id, {String? libelle = 'STUDIO · Paris'}) =>
        LogementReport(
          id: id,
          logementId: 'l1',
          motif: 'Annonce frauduleuse',
          createdAt: DateTime(2026, 6, 1),
          logementLibelle: libelle,
          proprietaire: libelle == null ? null : 'Bob B',
          signalePar: 'Alice A',
        );

    ({List<LogementReport> signalements, bool hasNext, int total}) pageA(
      List<LogementReport> items, {
      bool hasNext = false,
    }) =>
        (signalements: items, hasNext: hasNext, total: items.length);

    setUp(() {
      when(() => adminService.annoncesSignalees(page: any(named: 'page')))
          .thenAnswer((_) async => pageA([annonce('r1')]));
    });

    test("basculer sur les annonces charge l'autre file", () async {
      await viewModel.setFile(FileModeration.annonces);

      expect(viewModel.file, FileModeration.annonces);
      expect(viewModel.annoncesSignalees, hasLength(1));
      // Les deux files ne se mélangent pas
      expect(viewModel.signalements, isEmpty);
    });

    test('rebasculer sur la même file ne recharge pas', () async {
      await viewModel.setFile(FileModeration.annonces);
      clearInteractions(adminService);

      await viewModel.setFile(FileModeration.annonces);

      verifyNever(
          () => adminService.annoncesSignalees(page: any(named: 'page')));
    });

    test('annonce disparue : le signalement reste consultable', () async {
      when(() => adminService.annoncesSignalees(page: any(named: 'page')))
          .thenAnswer((_) async => pageA([annonce('r1', libelle: null)]));

      await viewModel.setFile(FileModeration.annonces);

      expect(viewModel.annoncesSignalees.single.annonceDisponible, isFalse);
    });

    test("retirer suspend l'annonce puis recharge la file", () async {
      await viewModel.setFile(FileModeration.annonces);
      when(() => adminService.suspendreLogement('l1', 'Photos volées'))
          .thenAnswer((_) async => Logement(
                id: 'l1',
                ownerId: 'o1',
                adresse: '1 rue X',
                ville: 'Paris',
                codePostal: '75001',
                type: LogementType.STUDIO,
                surface: 25,
                nbPieces: 1,
                loyer: 700,
                charges: 0,
                statut: LogementStatut.SUSPENDU,
                isVerified: false,
                isMeuble: true,
              ));

      final error =
          await viewModel.retirerAnnonce(annonce('r1'), '  Photos volées ');

      expect(error, isNull);
      // C'est le logementId qui est suspendu, pas l'id du signalement
      verify(() => adminService.suspendreLogement('l1', 'Photos volées'))
          .called(1);
      // L'annonce sort de la file côté serveur : on recharge plutôt que de
      // retirer la carte localement
      verify(() => adminService.annoncesSignalees(page: any(named: 'page')))
          .called(2);
    });

    test('motif vide : refusé sans appel réseau', () async {
      await viewModel.setFile(FileModeration.annonces);
      clearInteractions(adminService);

      final error = await viewModel.retirerAnnonce(annonce('r1'), '   ');

      expect(error, 'Le motif est obligatoire');
      verifyNever(() => adminService.suspendreLogement(any(), any()));
    });
  });
}
