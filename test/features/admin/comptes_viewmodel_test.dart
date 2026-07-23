import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/admin/comptes_viewmodel.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/admin_user.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService adminService;
  late ComptesViewModel viewModel;

  AdminUser user(
    String id, {
    bool isActive = true,
    DateTime? deletedAt,
    UserRole role = UserRole.ETUDIANT,
  }) =>
      AdminUser(
        id: id,
        email: '$id@studup.fr',
        firstName: 'Prenom',
        lastName: 'Nom',
        role: role,
        isVerified: true,
        isActive: isActive,
        createdAt: DateTime(2026, 1, 1),
        deletedAt: deletedAt,
      );

  ({List<AdminUser> users, bool hasNext, int total}) page(
    List<AdminUser> users, {
    bool hasNext = false,
    int? total,
  }) =>
      (users: users, hasNext: hasNext, total: total ?? users.length);

  setUp(() {
    adminService = MockAdminService();
    viewModel = ComptesViewModel(adminService: adminService);
  });

  group('load', () {
    test('charge la première page et le total', () async {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([user('u1'), user('u2')], total: 42));

      await viewModel.load();

      expect(viewModel.comptes, hasLength(2));
      // Le total vient du serveur, pas de la page chargée
      expect(viewModel.total, 42);
      expect(viewModel.errorMessage, isNull);
    });

    test('erreur API : message stocké, liste vide', () async {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenThrow(const ApiException(
        code: 'FORBIDDEN',
        message: 'Accès refusé',
        statusCode: 403,
      ));

      await viewModel.load();

      expect(viewModel.comptes, isEmpty);
      expect(viewModel.errorMessage, 'Accès refusé');
    });
  });

  group('pagination', () {
    test('chargerPlus ajoute à la liste sans la remplacer', () async {
      when(() => adminService.listUsers(
                role: any(named: 'role'),
                etat: any(named: 'etat'),
                page: 0,
              ))
          .thenAnswer((_) async => page([user('u1')], hasNext: true, total: 2));
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: 1,
          )).thenAnswer((_) async => page([user('u2')], total: 2));

      await viewModel.load();
      expect(viewModel.peutChargerPlus, isTrue);

      await viewModel.chargerPlus();

      expect(viewModel.comptes.map((u) => u.id), ['u1', 'u2']);
      expect(viewModel.peutChargerPlus, isFalse);
    });

    test('chargerPlus ne fait rien sans page suivante', () async {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([user('u1')]));
      await viewModel.load();
      clearInteractions(adminService);

      await viewModel.chargerPlus();

      verifyNever(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          ));
    });
  });

  group('filtres', () {
    setUp(() {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([]));
    });

    test('repasser le même filtre le retire', () async {
      await viewModel.setFiltreEtat(EtatCompte.suspendu);
      expect(viewModel.filtreEtat, EtatCompte.suspendu);

      await viewModel.setFiltreEtat(EtatCompte.suspendu);

      expect(viewModel.filtreEtat, isNull);
    });

    test('changer de filtre repart de la première page', () async {
      await viewModel.setFiltreRole(UserRole.ALTERNANT);

      verify(() => adminService.listUsers(
          role: UserRole.ALTERNANT, etat: null, page: 0)).called(1);
    });
  });

  group('sanctions', () {
    test('suspendre recharge la liste depuis le serveur', () async {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([user('u1')]));
      when(() => adminService.suspendre('u1'))
          .thenAnswer((_) async => user('u1', isActive: false));
      await viewModel.load();

      final error = await viewModel.suspendre(user('u1'));

      expect(error, isNull);
      // L'état affiché doit venir du serveur, pas d'une supposition locale
      verify(() => adminService.listUsers(
          role: any(named: 'role'),
          etat: any(named: 'etat'),
          page: any(named: 'page'))).called(2);
    });

    test('erreur de sanction : message remonté, liste non rechargée',
        () async {
      when(() => adminService.listUsers(
            role: any(named: 'role'),
            etat: any(named: 'etat'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => page([user('u1')]));
      await viewModel.load();
      when(() => adminService.bannir('u1')).thenThrow(const ApiException(
        code: 'UNAUTHORIZED',
        message: 'Impossible de bannir un administrateur',
        statusCode: 403,
      ));

      final error = await viewModel.bannir(user('u1'));

      expect(error, 'Impossible de bannir un administrateur');
    });
  });

  group('état dérivé du compte', () {
    test('actif, suspendu et banni se distinguent', () {
      expect(user('a').etat, EtatCompte.actif);
      expect(user('b', isActive: false).etat, EtatCompte.suspendu);
      // Un compte banni est aussi inactif : c'est deletedAt qui tranche
      expect(
        user('c', isActive: false, deletedAt: DateTime(2026, 5, 1)).etat,
        EtatCompte.banni,
      );
    });
  });
}
