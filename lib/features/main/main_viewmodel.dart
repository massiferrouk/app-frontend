import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/chat_socket_service.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/enums.dart';

/// ViewModel du shell de navigation.
/// Lit le rôle dans le JWT et pilote l'onglet courant.
class MainViewModel extends BaseViewModel {
  final ProfileService _profile;
  final MessageService _messages;
  final NotificationService _notifications;
  final ChatSocketService _socket;

  MainViewModel(
      {ProfileService? profileService,
      MessageService? messageService,
      NotificationService? notificationService,
      ChatSocketService? chatSocketService})
      : _profile = profileService ?? locator<ProfileService>(),
        _messages = messageService ?? locator<MessageService>(),
        _notifications = notificationService ?? locator<NotificationService>(),
        _socket = chatSocketService ?? locator<ChatSocketService>();

  /// Rôle par défaut le temps de lire le token (évite un écran vide)
  UserRole role = UserRole.ALTERNANT;

  int currentIndex = 0;

  /// Badge de l'onglet Messages : nombre de CONVERSATIONS avec des
  /// messages non lus (pas le total de messages — convention WhatsApp).
  int conversationsNonLues = 0;

  /// Badge de l'onglet Alertes (propriétaire) : notifications non lues
  int notificationsNonLues = 0;

  /// Compteurs incrémentés à chaque ouverture de l'onglet Accueil / Messages.
  /// Servent de clé aux vues correspondantes pour forcer un rechargement :
  /// dans un IndexedStack les onglets restent montés, donc sans ça une donnée
  /// arrivée côté serveur (accord reçu, nouveau message) ne s'afficherait
  /// jamais tant que l'utilisateur ne relance pas l'app.
  int homeReloadKey = 0;
  int messagesReloadKey = 0;
  int rechercheReloadKey = 0;

  /// Index de l'onglet Messages selon le rôle (voir _pagesForRole).
  int get _messagesTabIndex =>
      (role == UserRole.PROPRIETAIRE || role == UserRole.ADMIN) ? 2 : 3;

  /// Index de l'onglet Recherche : alternant = 2, étudiant = 1, aucun ailleurs.
  int get _rechercheTabIndex => switch (role) {
        UserRole.ALTERNANT => 2,
        UserRole.ETUDIANT => 1,
        _ => -1,
      };

  /// userId abonné au topic personnel — pour se désabonner au dispose
  String? _subscribedUserId;

  Future<void> init() async {
    role = await _profile.currentRole() ?? UserRole.ALTERNANT;
    notifyListeners();
    await refreshMessagesBadge();

    // Temps réel (APP-102) : tout message qui m'est adressé rafraîchit le
    // badge instantanément, quel que soit l'onglet ouvert.
    final userId = await _profile.currentUserId();
    if (userId != null) {
      _subscribedUserId = userId;
      _socket.subscribeToUserMessages(userId, (_) => refreshMessagesBadge());
    }
  }

  @override
  void dispose() {
    if (_subscribedUserId != null) {
      _socket.unsubscribeFromUserMessages(_subscribedUserId!);
    }
    super.dispose();
  }

  void setIndex(int index) {
    if (index == currentIndex) return;
    currentIndex = index;
    // Rechargement de la vue à chaque entrée dans l'onglet concerné
    if (index == 0) homeReloadKey++;
    if (index == _messagesTabIndex) messagesReloadKey++;
    if (index == _rechercheTabIndex) rechercheReloadKey++;
    notifyListeners();
    // Chaque changement d'onglet rafraîchit le badge : en quittant
    // Messages il retombe à zéro, ailleurs il capte les nouveautés.
    refreshMessagesBadge();
  }

  /// Le badge est secondaire : une erreur réseau ne doit rien bloquer.
  Future<void> refreshMessagesBadge() async {
    try {
      final conversations = await _messages.getConversations();
      conversationsNonLues =
          conversations.where((c) => c.unreadCount > 0).length;
      notifyListeners();
    } on ApiException {
      // silencieux
    }
    // Badge Alertes : uniquement pour le proprio/admin (seuls rôles
    // avec l'onglet) — inutile de charger pour les autres.
    if (role == UserRole.PROPRIETAIRE || role == UserRole.ADMIN) {
      try {
        notificationsNonLues = await _notifications.getUnreadCount();
        notifyListeners();
      } on ApiException {
        // silencieux
      }
    }
  }
}
