import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/logements/logement_detail_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/disponibilite.dart';
import 'package:studup_app/shared/models/logement.dart';
import 'package:studup_app/shared/models/reputation_score.dart';

class MockLogementService extends Mock implements LogementService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockLogementService logementService;
  late MockProfileService profileService;
  late LogementDetailViewModel viewModel;

  final logement = Logement.fromJson({
    'id': 'log-1',
    'ownerId': 'owner-1',
    'adresse': '12 rue de la Paix',
    'ville': 'Paris',
    'codePostal': '75001',
    'type': 'STUDIO',
    'surface': 25.0,
    'nbPieces': 1,
    'loyer': 800.0,
    'charges': 50.0,
    'statut': 'ACTIF',
    'isVerified': true,
    'isMeuble': true,
  });

  Disponibilite dispo({required int startInDays, required int endInDays}) =>
      Disponibilite.fromJson({
        'id': 'd-$startInDays',
        'logementId': 'log-1',
        'dateDebut': DateTime.now()
            .add(Duration(days: startInDays))
            .toIso8601String()
            .substring(0, 10),
        'dateFin': DateTime.now()
            .add(Duration(days: endInDays))
            .toIso8601String()
            .substring(0, 10),
        'type': 'LIBRE',
      });

  setUp(() {
    logementService = MockLogementService();
    profileService = MockProfileService();
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
    // Rechargement du logement complet dans loadExtras
    when(() => logementService.getLogement('log-1'))
        .thenAnswer((_) async => logement);
    viewModel = LogementDetailViewModel(
      logement: logement,
      logementService: logementService,
      profileService: profileService,
      navigationService: MockNavigationService(),
    );
  });

  group('loadExtras', () {
    test('charge disponibilités et réputation', () async {
      when(() => logementService.getDisponibilites('log-1'))
          .thenAnswer((_) async => [dispo(startInDays: 3, endInDays: 10)]);
      when(() => logementService.getReputation('owner-1'))
          .thenAnswer((_) async => ReputationScore.fromJson(const {
                'userId': 'owner-1',
                'avgRating': 4.2,
                'totalReviews': 12,
                'logementScore': 4.5,
                'nbAccords': 8,
                'badge': 'Fiable',
              }));

      await viewModel.loadExtras();

      expect(viewModel.disponibilites, hasLength(1));
      expect(viewModel.reputation!.badge, 'Fiable');
      expect(viewModel.reputation!.avgRating, 4.2);
    });

    test('échec des extras : non bloquant, pas d\'exception', () async {
      when(() => logementService.getDisponibilites('log-1'))
          .thenThrow(const ApiException(
              code: 'ERROR', message: 'Erreur', statusCode: 500));
      when(() => logementService.getReputation('owner-1'))
          .thenThrow(const ApiException(
              code: 'NOT_FOUND', message: 'Pas de score', statusCode: 404));

      await viewModel.loadExtras(); // ne doit pas lever

      expect(viewModel.disponibilites, isEmpty);
      expect(viewModel.reputation, isNull);
      expect(viewModel.isBusy, isFalse);
    });
  });

  group('prochainesDisponibilites', () {
    test('filtre sur les 4 prochaines semaines', () async {
      when(() => logementService.getDisponibilites('log-1'))
          .thenAnswer((_) async => [
                dispo(startInDays: 3, endInDays: 10), // dans la fenêtre
                dispo(startInDays: 40, endInDays: 50), // trop loin
                dispo(startInDays: -20, endInDays: -10), // passée
              ]);
      when(() => logementService.getReputation(any())).thenThrow(
          const ApiException(
              code: 'NOT_FOUND', message: '', statusCode: 404));

      await viewModel.loadExtras();

      expect(viewModel.prochainesDisponibilites, hasLength(1));
    });
  });
}
