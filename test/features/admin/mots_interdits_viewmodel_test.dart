import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/admin/mots_interdits_viewmodel.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/mot_interdit.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService adminService;
  late MotsInterditsViewModel viewModel;

  MotInterdit mot(String texte) => MotInterdit(
        id: 'id-$texte',
        mot: texte,
        createdAt: DateTime(2026, 6, 1),
      );

  setUp(() {
    adminService = MockAdminService();
    viewModel = MotsInterditsViewModel(adminService: adminService);
  });

  group('load', () {
    test('charge la liste', () async {
      when(() => adminService.motsInterdits())
          .thenAnswer((_) async => [mot('arnaque'), mot('spam')]);

      await viewModel.load();

      expect(viewModel.mots.map((m) => m.mot), ['arnaque', 'spam']);
      expect(viewModel.errorMessage, isNull);
    });

    test('erreur API : message stocké', () async {
      when(() => adminService.motsInterdits()).thenThrow(const ApiException(
        code: 'FORBIDDEN',
        message: 'Accès refusé',
        statusCode: 403,
      ));

      await viewModel.load();

      expect(viewModel.mots, isEmpty);
      expect(viewModel.errorMessage, 'Accès refusé');
    });
  });

  group('ajouter', () {
    setUp(() {
      when(() => adminService.motsInterdits())
          .thenAnswer((_) async => [mot('spam')]);
    });

    test('ajoute puis recharge depuis le serveur', () async {
      when(() => adminService.ajouterMotInterdit(any()))
          .thenAnswer((_) async => mot('spam'));

      final error = await viewModel.ajouter('  SPAM  ');

      expect(error, isNull);
      // La saisie est envoyée telle quelle : c'est le serveur qui normalise
      // en minuscules, et le rechargement affiche ce qui est réellement stocké.
      verify(() => adminService.ajouterMotInterdit('SPAM')).called(1);
      verify(() => adminService.motsInterdits()).called(1);
    });

    test('saisie vide : refusée sans appel réseau', () async {
      final error = await viewModel.ajouter('   ');

      expect(error, 'Saisis un mot');
      verifyNever(() => adminService.ajouterMotInterdit(any()));
    });

    test('409 : message métier plutôt que l\'erreur brute', () async {
      when(() => adminService.ajouterMotInterdit(any()))
          .thenThrow(const ApiException(
        code: 'CONFLICT',
        message: 'Conflit',
        statusCode: 409,
      ));

      final error = await viewModel.ajouter('spam');

      expect(error, 'Ce mot est déjà dans la liste');
    });
  });

  group('supprimer', () {
    test('supprime puis recharge', () async {
      when(() => adminService.motsInterdits()).thenAnswer((_) async => []);
      when(() => adminService.supprimerMotInterdit('id-spam'))
          .thenAnswer((_) async {});

      final error = await viewModel.supprimer(mot('spam'));

      expect(error, isNull);
      verify(() => adminService.motsInterdits()).called(1);
    });

    test('erreur : message remonté', () async {
      when(() => adminService.supprimerMotInterdit(any()))
          .thenThrow(const ApiException(
        code: 'NOT_FOUND',
        message: 'Mot introuvable',
        statusCode: 404,
      ));

      final error = await viewModel.supprimer(mot('spam'));

      expect(error, 'Mot introuvable');
    });
  });
}
