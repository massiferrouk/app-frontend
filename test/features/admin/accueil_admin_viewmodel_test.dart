import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/admin/accueil_admin_viewmodel.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/admin_dashboard.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService adminService;
  late AccueilAdminViewModel viewModel;

  AdminDashboard dashboard({int signalements = 0, int annonces = 0}) =>
      AdminDashboard(
        totalComptes: 42,
        comptesParRole: const {UserRole.ALTERNANT: 12, UserRole.ETUDIANT: 30},
        comptesSuspendus: 3,
        comptesBannis: 1,
        inscriptions7Jours: 5,
        inscriptions30Jours: 20,
        totalAnnonces: 10,
        annoncesParStatut: const {LogementStatut.ACTIF: 8},
        signalementsEnAttente: signalements,
        annoncesSignalees: annonces,
        motsInterdits: 7,
      );

  setUp(() {
    adminService = MockAdminService();
    viewModel = AccueilAdminViewModel(adminService: adminService);
  });

  test('charge les chiffres', () async {
    when(() => adminService.dashboard()).thenAnswer((_) async => dashboard());

    await viewModel.load();

    expect(viewModel.dashboard!.totalComptes, 42);
    expect(viewModel.errorMessage, isNull);
  });

  test('erreur API : message stocké, écran en repli', () async {
    when(() => adminService.dashboard()).thenThrow(const ApiException(
      code: 'FORBIDDEN',
      message: 'Accès refusé',
      statusCode: 403,
    ));

    await viewModel.load();

    expect(viewModel.dashboard, isNull);
    expect(viewModel.errorMessage, 'Accès refusé');
  });

  group('mise en avant des signalements', () {
    test('aucun signalement : pas d\'alerte', () async {
      when(() => adminService.dashboard())
          .thenAnswer((_) async => dashboard());

      await viewModel.load();

      expect(viewModel.aDesSignalements, isFalse);
    });

    test('des messages signalés : alerte affichée', () async {
      when(() => adminService.dashboard())
          .thenAnswer((_) async => dashboard(signalements: 4));

      await viewModel.load();

      expect(viewModel.aDesSignalements, isTrue);
    });

    test('des annonces signalées seules : alerte quand même', () async {
      // N'en compter qu'une des deux files masquerait l'autre (APP-121)
      when(() => adminService.dashboard())
          .thenAnswer((_) async => dashboard(annonces: 2));

      await viewModel.load();

      expect(viewModel.aDesSignalements, isTrue);
    });

    test('le total additionne les deux files', () async {
      when(() => adminService.dashboard())
          .thenAnswer((_) async => dashboard(signalements: 4, annonces: 2));

      await viewModel.load();

      expect(viewModel.totalSignalements, 6);
    });

    test('avant chargement : pas d\'alerte plutôt qu\'un plantage', () {
      expect(viewModel.aDesSignalements, isFalse);
    });
  });

  group('désérialisation', () {
    test('les clés d\'enum absentes ne cassent pas la lecture', () {
      final d = AdminDashboard.fromJson(const {
        'totalComptes': 5,
        'comptesParRole': {'ALTERNANT': 5},
        'annoncesParStatut': <String, dynamic>{},
      });

      expect(d.comptesParRole[UserRole.ALTERNANT], 5);
      // Champs absents du JSON → 0, jamais null
      expect(d.comptesBannis, 0);
      expect(d.annoncesParStatut, isEmpty);
    });

    test('une valeur d\'enum inconnue est ignorée, pas fatale', () {
      // Un enum élargi côté serveur ne doit pas casser une version déployée
      final d = AdminDashboard.fromJson(const {
        'comptesParRole': {'ALTERNANT': 2, 'ROLE_DU_FUTUR': 9},
      });

      expect(d.comptesParRole[UserRole.ALTERNANT], 2);
      expect(d.comptesParRole, hasLength(1));
    });
  });
}
