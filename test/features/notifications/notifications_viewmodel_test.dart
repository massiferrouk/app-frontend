import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/notifications/notifications_viewmodel.dart';
import 'package:studup_app/services/dashboard_service.dart';
import 'package:studup_app/services/matching_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/proprietaire_dashboard.dart';
import 'package:studup_app/shared/models/app_notification.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockMatchingService extends Mock implements MatchingService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockProfileService extends Mock implements ProfileService {}

class MockDashboardService extends Mock implements DashboardService {}

void main() {
  late MockNotificationService service;
  late MockMatchingService matching;
  late MockNavigationService nav;
  late MockProfileService profile;
  late MockDashboardService dashboard;
  late NotificationsViewModel viewModel;

  AppNotification build(
          {required String id, bool isRead = false, String? deepLink}) =>
      AppNotification.fromJson({
        'id': id,
        'type': 'NOUVEAU_MATCH',
        'title': 'Nouveau match !',
        'body': 'Thomas D. est compatible à 87%',
        'isRead': isRead,
        'deepLink': deepLink,
        'createdAt': DateTime.now().toIso8601String(),
      });

  MatchingSuggestion buildSuggestion(String userId) =>
      MatchingSuggestion.fromJson({
        'profileId': 'p-1',
        'userId': userId,
        'prenom': 'Thomas',
        'nom': 'Durand',
        'villeA': 'Lyon',
        'villeB': 'Paris',
        'score': 0.75,
        'scorePercent': 75,
        'typePropose': 'ECHANGE_PARTIEL',
        'isMatchActif': true,
        'messageMatchPotentiel': null,
        'nbSemainesEchange': 3,
        'nbSemainesColocation': 0,
        'nbSemainesChevauchement': 1,
        'messageResume': null,
        'logementAId': 'log-a',
        'logementBId': 'log-b',
        'semaines': const [],
      });

  setUp(() {
    service = MockNotificationService();
    matching = MockMatchingService();
    nav = MockNavigationService();
    profile = MockProfileService();
    dashboard = MockDashboardService();
    // Par défaut : pas un propriétaire → aucune alerte sur le parc (APP-119)
    when(() => profile.currentRole()).thenAnswer((_) async => UserRole.ETUDIANT);
    viewModel = NotificationsViewModel(
      notificationService: service,
      matchingService: matching,
      profileService: profile,
      dashboardService: dashboard,
      navigationService: nav,
    );
    // Le tap marque toujours comme lue avant de naviguer
    when(() => service.markAsRead(any())).thenAnswer((_) async {});
  });

  group('alertes sur le parc du propriétaire (APP-119)', () {
    ProprietaireDashboard buildDashboard({
      required int totaux,
      required int actifs,
      List<Map<String, dynamic>> logements = const [],
    }) =>
        ProprietaireDashboard.fromJson({
          'nbLogementsTotaux': totaux,
          'nbLogementsActifs': actifs,
          'nbEtudiantsInteresses': 0,
          'nbConversations': 0,
          'logements': logements,
        });

    test('propriétaire : brouillons et logements vacants remontés', () async {
      when(() => service.getNotifications()).thenAnswer((_) async => []);
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.PROPRIETAIRE);
      when(() => dashboard.getProprietaireDashboard()).thenAnswer((_) async =>
          buildDashboard(totaux: 3, actifs: 1, logements: [
            {
              'id': 'l1',
              'ville': 'Paris',
              'adresse': '1 rue Test',
              'type': 'STUDIO',
              'statut': 'ACTIF',
              'loyer': 700,
              'isOccupe': false,
            },
          ]));

      await viewModel.load();

      // 2 brouillons (3 - 1) + 1 logement actif sans locataire
      expect(viewModel.alertesLogements, hasLength(2));
      expect(viewModel.alertesLogements.first, contains('brouillon'));
      expect(viewModel.alertesLogements.last, contains('sans locataire'));
    });

    test('autre rôle : aucune alerte de parc', () async {
      when(() => service.getNotifications()).thenAnswer((_) async => []);
      // currentRole vaut ETUDIANT par défaut (setUp)

      await viewModel.load();

      expect(viewModel.alertesLogements, isEmpty);
      verifyNever(() => dashboard.getProprietaireDashboard());
    });
  });

  group('load', () {
    test('charge et compte les non lues', () async {
      when(() => service.getNotifications()).thenAnswer((_) async => [
            build(id: 'n1'),
            build(id: 'n2', isRead: true),
            build(id: 'n3'),
          ]);

      await viewModel.load();

      expect(viewModel.notifications, hasLength(3));
      expect(viewModel.unreadCount, 2);
    });

    test('erreur API : message stocké', () async {
      when(() => service.getNotifications()).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.load();

      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('ouvrirNotification (deep links, APP-101)', () {
    test('accord/{id} : marque lue sans rien ouvrir (APP-120)', () async {
      // Les accords ont été retirés de l'app, mais d'anciennes notifications
      // restent en base : le tap ne doit ni planter ni naviguer dans le vide.
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1', deepLink: 'accord/a42')]);
      await viewModel.load();

      final error =
          await viewModel.ouvrirNotification(viewModel.notifications.first);

      expect(error, isNull);
      expect(viewModel.unreadCount, 0); // marquée lue au passage
      verifyNever(
          () => nav.navigateTo(any(), arguments: any(named: 'arguments')));
    });

    test('match/{userId} : retrouve la suggestion et ouvre la compatibilité',
        () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1', deepLink: 'match/u-9')]);
      when(() => matching.getSuggestions()).thenAnswer(
          (_) async => [buildSuggestion('u-5'), buildSuggestion('u-9')]);
      when(() => nav.navigateTo(any(), arguments: any(named: 'arguments')))
          .thenAnswer((_) async => null);
      await viewModel.load();

      final error =
          await viewModel.ouvrirNotification(viewModel.notifications.first);

      expect(error, isNull);
      verify(() => nav.navigateTo(Routes.compatibiliteView,
          arguments: any(named: 'arguments'))).called(1);
    });

    test('match disparu des suggestions : message, pas de navigation',
        () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1', deepLink: 'match/u-9')]);
      when(() => matching.getSuggestions())
          .thenAnswer((_) async => [buildSuggestion('u-5')]);
      await viewModel.load();

      final error =
          await viewModel.ouvrirNotification(viewModel.notifications.first);

      expect(error, contains('plus disponible'));
      verifyNever(
          () => nav.navigateTo(any(), arguments: any(named: 'arguments')));
    });

    test('deepLink null : marque lue seulement, pas de navigation', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      await viewModel.load();

      final error =
          await viewModel.ouvrirNotification(viewModel.notifications.first);

      expect(error, isNull);
      expect(viewModel.unreadCount, 0);
      verifyNever(
          () => nav.navigateTo(any(), arguments: any(named: 'arguments')));
    });

  });

  group('markAsRead', () {
    test('optimiste : l\'UI change avant la réponse serveur', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);

      await viewModel.load();
      expect(viewModel.unreadCount, 1);

      await viewModel.markAsRead(viewModel.notifications.first);

      expect(viewModel.unreadCount, 0);
      verify(() => service.markAsRead('n1')).called(1);
    });

    test('déjà lue : aucun appel', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1', isRead: true)]);
      await viewModel.load();

      await viewModel.markAsRead(viewModel.notifications.first);

      verifyNever(() => service.markAsRead(any()));
    });

    test('échec serveur silencieux : l\'UI reste marquée lue', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      when(() => service.markAsRead('n1')).thenThrow(const ApiException(
          code: 'ERROR', message: 'Erreur', statusCode: 500));
      await viewModel.load();

      await viewModel.markAsRead(viewModel.notifications.first);

      expect(viewModel.unreadCount, 0); // pas de rollback, pas de crash
    });
  });

  group('markAllAsRead', () {
    test('appelle le serveur puis recharge', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      when(() => service.markAllAsRead()).thenAnswer((_) async {});
      await viewModel.load();

      await viewModel.markAllAsRead();

      verify(() => service.markAllAsRead()).called(1);
      verify(() => service.getNotifications()).called(2);
    });
  });
}
