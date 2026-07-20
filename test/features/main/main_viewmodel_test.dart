import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/main/main_viewmodel.dart';
import 'package:studup_app/services/chat_socket_service.dart';
import 'package:studup_app/services/message_service.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/conversation_summary.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/message.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockMessageService extends Mock implements MessageService {}

class MockChatSocketService extends Mock implements ChatSocketService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockProfileService profile;
  late MockMessageService messages;
  late MockChatSocketService socket;
  late MockNotificationService notifications;
  late MainViewModel viewModel;

  ConversationSummary buildConv({required int unread}) => ConversationSummary(
        conversationId: 'c-$unread',
        partnerId: 'p1',
        partnerName: 'Thomas D.',
        lastMessage: 'Salut',
        unreadCount: unread,
      );

  setUpAll(() {
    registerFallbackValue((ChatMessage _) {});
  });

  setUp(() {
    profile = MockProfileService();
    messages = MockMessageService();
    socket = MockChatSocketService();
    notifications = MockNotificationService();
    // Par défaut : aucune conversation ni notification (badges à 0)
    when(() => messages.getConversations()).thenAnswer((_) async => []);
    when(() => notifications.getUnreadCount()).thenAnswer((_) async => 0);
    when(() => profile.currentUserId()).thenAnswer((_) async => 'moi');
    when(() => socket.subscribeToUserMessages(any(), any()))
        .thenAnswer((_) {});
    viewModel = MainViewModel(
      profileService: profile,
      messageService: messages,
      notificationService: notifications,
      chatSocketService: socket,
    );
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

    // APP-117 : sans ce compteur, une candidature créée depuis une annonce
    // n'apparaissait jamais dans l'onglet (les onglets d'un IndexedStack
    // restent montés, donc load() n'était rappelé qu'au relancement de l'app).
    test('ouvrir l\'onglet Candidatures incrémente candidaturesReloadKey '
        '(étudiant)', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ETUDIANT);
      await viewModel.init();
      final before = viewModel.candidaturesReloadKey;

      viewModel.setIndex(2); // étudiant : index 2 = Candidatures

      expect(viewModel.candidaturesReloadKey, before + 1);
    });
  });

  group('badge Messages (APP-102)', () {
    test('compte les CONVERSATIONS non lues, pas les messages', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => messages.getConversations()).thenAnswer((_) async => [
            buildConv(unread: 5), // 1 conversation, 5 messages non lus
            buildConv(unread: 1),
            buildConv(unread: 0), // lue : ne compte pas
          ]);

      await viewModel.init();

      expect(viewModel.conversationsNonLues, 2);
    });

    test('changement d\'onglet : le badge se rafraîchit', () async {
      when(() => messages.getConversations())
          .thenAnswer((_) async => [buildConv(unread: 1)]);

      viewModel.setIndex(1);
      // refreshMessagesBadge est async après notifyListeners
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.conversationsNonLues, 1);
      verify(() => messages.getConversations()).called(1);
    });

    test('erreur réseau : silencieuse, badge inchangé', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => messages.getConversations()).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.init();

      expect(viewModel.conversationsNonLues, 0); // pas de crash
    });

    test('proprio : badge Alertes chargé avec les notifs non lues (APP-102)',
        () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.PROPRIETAIRE);
      when(() => notifications.getUnreadCount()).thenAnswer((_) async => 4);

      await viewModel.init();

      expect(viewModel.notificationsNonLues, 4);
    });

    test('alternant : pas d\'appel au compteur de notifs (pas d\'onglet Alertes)',
        () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);

      await viewModel.init();

      verifyNever(() => notifications.getUnreadCount());
      expect(viewModel.notificationsNonLues, 0);
    });

    test('init s\'abonne au topic personnel de l\'utilisateur', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);

      await viewModel.init();

      verify(() => socket.subscribeToUserMessages('moi', any())).called(1);
    });

    test('message reçu en temps réel : le badge se rafraîchit', () async {
      when(() => profile.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      // Capture le callback passé au socket pour simuler un message entrant
      void Function(ChatMessage)? onMessage;
      when(() => socket.subscribeToUserMessages(any(), any()))
          .thenAnswer((invocation) {
        onMessage =
            invocation.positionalArguments[1] as void Function(ChatMessage);
      });

      await viewModel.init();
      expect(viewModel.conversationsNonLues, 0);

      // Un nouveau message arrive → le serveur compte 1 conversation non lue
      when(() => messages.getConversations()).thenAnswer(
          (_) async => [buildConv(unread: 1)]);
      onMessage!(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'lui',
        content: 'salut',
        isRead: false,
        createdAt: DateTime.now(),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.conversationsNonLues, 1);
    });
  });
}
