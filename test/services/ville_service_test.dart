import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/services/ville_service.dart';

void main() {
  // rootBundle a besoin d'un binding initialisé pour charger l'asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  late VilleService service;

  setUp(() => service = VilleService());

  group('VilleService.rechercher', () {
    test('trouve une ville malgré une casse quelconque', () async {
      final r = await service.rechercher('marseil');
      expect(r, contains('Marseille'));
    });

    test('insensible aux accents (« etienne » retrouve « Étienne »)', () async {
      final r = await service.rechercher('saint etienne');
      // Le nom officiel est « Saint-Étienne » : accents + tiret ne bloquent pas.
      expect(r.any((v) => v.toLowerCase().contains('étienne')), isTrue);
    });

    test('query vide : retourne un début de liste (non vide, plafonné)',
        () async {
      final r = await service.rechercher('');
      expect(r, isNotEmpty);
      expect(r.length, lessThanOrEqualTo(50));
    });

    test('résultats plafonnés par la limite', () async {
      final r = await service.rechercher('a', limite: 10);
      expect(r.length, lessThanOrEqualTo(10));
    });
  });
}
