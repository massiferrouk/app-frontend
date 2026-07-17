import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/services/onboarding_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late OnboardingService service;

  setUp(() {
    storage = MockSecureStorage();
    service = OnboardingService(storage: storage);
  });

  test('dejaVu → true quand le flag vaut "true"', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'true');

    expect(await service.dejaVu(), isTrue);
  });

  test('dejaVu → false quand le flag est absent', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);

    expect(await service.dejaVu(), isFalse);
  });

  test('dejaVu → false (sans planter) si la lecture échoue', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenThrow(Exception('storage indisponible'));

    expect(await service.dejaVu(), isFalse);
  });

  test('marquerVu écrit le flag "true"', () async {
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await service.marquerVu();

    verify(() => storage.write(key: 'onboarding_vu', value: 'true')).called(1);
  });
}
