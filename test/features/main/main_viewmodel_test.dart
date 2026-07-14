import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/features/main/main_viewmodel.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockProfileService extends Mock implements ProfileService {}

void main() {
  late MockProfileService profile;
  late MainViewModel viewModel;

  setUp(() {
    profile = MockProfileService();
    viewModel = MainViewModel(profileService: profile);
  });

  group('MainViewModel', () {
    test('init lit le rôle depuis le token', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.PROPRIETAIRE);

      await viewModel.init();

      expect(viewModel.role, UserRole.PROPRIETAIRE);
    });

    test('rôle illisible : défaut ALTERNANT', () async {
      when(() => profile.currentRole()).thenAnswer((_) async => null);

      await viewModel.init();

      expect(viewModel.role, UserRole.ALTERNANT);
    });

    test('setIndex change l\'onglet courant', () {
      viewModel.setIndex(2);

      expect(viewModel.currentIndex, 2);
    });

    test('ouvrir l\'onglet Accueil incrémente homeReloadKey', () {
      viewModel.setIndex(1); // on quitte l'accueil
      final before = viewModel.homeReloadKey;

      viewModel.setIndex(0); // on revient sur l'accueil

      expect(viewModel.homeReloadKey, before + 1);
    });

    test('ouvrir l\'onglet Messages incrémente messagesReloadKey (alternant)',
        () {
      // rôle par défaut ALTERNANT → onglet Messages = index 3
      final before = viewModel.messagesReloadKey;

      viewModel.setIndex(3);

      expect(viewModel.messagesReloadKey, before + 1);
    });
  });
}
