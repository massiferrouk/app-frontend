import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/matching_service.dart';
import '../../services/notification_service.dart';
import '../../shared/models/app_notification.dart';

/// Logique de l'écran notifications.
class NotificationsViewModel extends BaseViewModel {
  final NotificationService _notifications;
  final AccordService _accords;
  final MatchingService _matching;
  final NavigationService _nav;

  NotificationsViewModel(
      {NotificationService? notificationService,
      AccordService? accordService,
      MatchingService? matchingService,
      NavigationService? navigationService})
      : _notifications =
            notificationService ?? locator<NotificationService>(),
        _accords = accordService ?? locator<AccordService>(),
        _matching = matchingService ?? locator<MatchingService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<AppNotification> notifications = [];
  String? errorMessage;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    setBusy(true);
    try {
      notifications = await _notifications.getNotifications();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Tap sur une notification : marque lue + suit le deepLink (APP-101).
  /// Formats backend : "accord/{id}" et "match/{userId}".
  /// Retourne null si OK (ou rien à ouvrir), un message d'erreur sinon.
  Future<String?> ouvrirNotification(AppNotification notification) async {
    await markAsRead(notification);

    final deepLink = notification.deepLink;
    if (deepLink == null || deepLink.isEmpty) return null;

    if (deepLink.startsWith('accord/')) {
      return _ouvrirAccord(deepLink.substring('accord/'.length));
    }
    if (deepLink.startsWith('match/')) {
      return _ouvrirMatch(deepLink.substring('match/'.length));
    }
    // Type sans destination (SYSTEME...) : marquer lue suffit
    return null;
  }

  Future<String?> _ouvrirAccord(String accordId) async {
    setBusy(true);
    try {
      final accord = await _accords.getAccord(accordId);
      setBusy(false);
      await _nav.navigateTo(
        Routes.accordDetailView,
        arguments: AccordDetailViewArguments(accord: accord),
      );
      return null;
    } on ApiException catch (e) {
      setBusy(false);
      return e.message;
    }
  }

  /// Le deepLink match ne porte qu'un userId : on recharge les suggestions
  /// pour retrouver la MatchingSuggestion complète (score, semaines...).
  Future<String?> _ouvrirMatch(String userId) async {
    setBusy(true);
    try {
      final suggestions = await _matching.getSuggestions();
      setBusy(false);

      final matches = suggestions.where((s) => s.userId == userId);
      if (matches.isEmpty) {
        // Profil modifié entre-temps : le match peut ne plus exister
        return 'Ce match n\'est plus disponible.';
      }

      await _nav.navigateTo(
        Routes.compatibiliteView,
        arguments: CompatibiliteViewArguments(suggestion: matches.first),
      );
      return null;
    } on ApiException catch (e) {
      setBusy(false);
      return e.message;
    }
  }

  /// Marque comme lue au tap. Optimiste : l'UI change tout de suite,
  /// l'appel part en arrière-plan (une notification lue deux fois
  /// n'a aucune conséquence).
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    final index = notifications.indexOf(notification);
    if (index == -1) return;

    notifications[index] = AppNotification(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      isRead: true,
      deepLink: notification.deepLink,
      createdAt: notification.createdAt,
    );
    notifyListeners();

    try {
      await _notifications.markAsRead(notification.id);
    } on ApiException {
      // Silencieux : au pire elle réapparaîtra non lue au prochain refresh
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notifications.markAllAsRead();
      await load();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}
