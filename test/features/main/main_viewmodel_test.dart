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
  });
}
