import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/messages/chat_viewmodel.dart';
import 'package:studup_app/services/chat_socket_service.dart';
import 'package:studup_app/services/message_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/conversation_summary.dart';
import 'package:studup_app/shared/models/message.dart';

class MockMessageService extends Mock implements MessageService {}

class MockProfileService extends Mock implements ProfileService {}

class MockChatSocketService extends Mock implements ChatSocketService {}

void main() {
  late MockMessageService messageService;
  late MockProfileService profileService;
  late MockChatSocketService socketService;

  const conversation = ConversationSummary(
    conversationId: 'conv-1',
    partnerId: 'lui',
    partnerName: 'Thomas D.',
    lastMessage: 'Salut',
    unreadCount: 1,
  );

  ChatMessage buildMessage({
    required String id,
    String senderId = 'lui',
    bool isRead = false,
  }) =>
      ChatMessage.fromJson({
        'id': id,
        'conversationId': 'conv-1',
        'senderId': senderId,
        'content': 'Message $id',
        'isRead': isRead,
        'createdAt': DateTime.now().toIso8601String(),
      });

  ChatViewModel makeViewModel([ConversationSummary conv = conversation]) =>
      ChatViewModel(
        conversation: conv,
        messageService: messageService,
        profileService: profileService,
        chatSocketService: socketService,
      );

  setUp(() {
    messageService = MockMessageService();
    profileService = MockProfileService();
    socketService = MockChatSocketService();
    when(() => socketService.subscribeToConversation(any(), any()))
        .thenAnswer((_) {});
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
    when(() => messageService.markAsRead(any())).thenAnswer((_) async {});
    // Par défaut : aucune conversation existante (ouverture "Contacter")
    when(() => messageService.getConversations())
        .thenAnswer((_) async => []);
  });

  group('init', () {
    test('inverse l\'historique (backend = plus récents en premier)',
        () async {
      when(() => messageService.getHistory('conv-1')).thenAnswer(
          (_) async => [buildMessage(id: 'm2'), buildMessage(id: 'm1')]);

      final viewModel = makeViewModel();
      await viewModel.init();

      expect(viewModel.messages.map((m) => m.id), ['m1', 'm2']);
    });

    test('marque les messages reçus non lus', () async {
      when(() => messageService.getHistory('conv-1')).thenAnswer(
          (_) async => [
                buildMessage(id: 'm-recu'), // non lu, de lui
                buildMessage(id: 'm-moi', senderId: 'moi'), // de moi
                buildMessage(id: 'm-lu', isRead: true),
              ]);

      final viewModel = makeViewModel();
      await viewModel.init();

      verify(() => messageService.markAsRead('m-recu')).called(1);
      verifyNever(() => messageService.markAsRead('m-moi'));
      verifyNever(() => messageService.markAsRead('m-lu'));
    });

    test(
        'ouverture via "Contacter" (id vide) mais conversation existante : '
        'charge l\'historique (A-02)', () async {
      const viaContacter = ConversationSummary(
        conversationId: '', // ouverture depuis le bouton « Contacter »
        partnerId: 'lui',
        partnerName: 'Thomas D.',
        lastMessage: '',
        unreadCount: 0,
      );
      // Une conversation avec ce partenaire existe déjà côté serveur
      when(() => messageService.getConversations()).thenAnswer((_) async => [
            const ConversationSummary(
              conversationId: 'conv-existante',
              partnerId: 'lui',
              partnerName: 'Thomas D.',
              lastMessage: 'Salut',
              unreadCount: 0,
            ),
          ]);
      when(() => messageService.getHistory('conv-existante'))
          .thenAnswer((_) async => [buildMessage(id: 'ancien')]);

      final viewModel = makeViewModel(viaContacter);
      await viewModel.init();

      // Plus de chat vide : l'historique de la conversation existante est chargé
      expect(viewModel.messages.map((m) => m.id), ['ancien']);
      verify(() => messageService.getHistory('conv-existante')).called(1);
      // …et on s'abonne bien au temps réel sur cette conversation
      verify(() =>
              socketService.subscribeToConversation('conv-existante', any()))
          .called(1);
    });

    test('nouvelle conversation (id vide) : aucun chargement', () async {
      const nouvelle = ConversationSummary(
        conversationId: '',
        partnerId: 'lui',
        partnerName: 'Thomas D.',
        lastMessage: '',
        unreadCount: 0,
      );

      final viewModel = makeViewModel(nouvelle);
      await viewModel.init();

      verifyNever(() => messageService.getHistory(any()));
      expect(viewModel.messages, isEmpty);
    });
  });

  group('send', () {
    test('envoie au partenaire et ajoute le message localement', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => []);
      when(() => messageService.sendMessage('lui', 'Salut !'))
          .thenAnswer((_) async => buildMessage(id: 'm-new', senderId: 'moi'));

      final viewModel = makeViewModel();
      await viewModel.init();
      viewModel.inputController.text = 'Salut !';

      await viewModel.send();

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.inputController.text, isEmpty);
    });

    test(
        'écho WebSocket arrivé AVANT la réponse REST : pas de doublon '
        'chez l\'émetteur (APP-102)', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => []);

      final viewModel = makeViewModel();
      await viewModel.init();

      final sent = buildMessage(id: 'm-new', senderId: 'moi');
      // Reproduit la course réelle : le backend broadcast le message
      // pendant le traitement du POST, donc l'écho STOMP est injecté
      // avant que sendMessage ne retourne sa réponse.
      when(() => messageService.sendMessage('lui', 'Salut !'))
          .thenAnswer((_) async {
        viewModel.onMessageReceived(sent);
        return sent;
      });

      viewModel.inputController.text = 'Salut !';
      await viewModel.send();

      expect(viewModel.messages, hasLength(1)); // et pas 2
      expect(viewModel.messages.single.id, 'm-new');
    });

    test('message vide : aucun envoi', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => []);

      final viewModel = makeViewModel();
      await viewModel.init();
      viewModel.inputController.text = '   ';

      await viewModel.send();

      verifyNever(() => messageService.sendMessage(any(), any()));
    });

    test('erreur réseau : message conservé dans le champ', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => []);
      when(() => messageService.sendMessage(any(), any()))
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Hors ligne',
        statusCode: 0,
      ));

      final viewModel = makeViewModel();
      await viewModel.init();
      viewModel.inputController.text = 'Message important';

      await viewModel.send();

      // Le texte n'est PAS perdu : l'utilisateur peut réessayer
      expect(viewModel.inputController.text, 'Message important');
      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('abonnement temps réel', () {
    test('conversation existante : abonnement au topic au demarrage', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => []);

      final viewModel = makeViewModel();
      await viewModel.init();

      verify(() =>
              socketService.subscribeToConversation('conv-1', any()))
          .called(1);
    });

    test('nouvelle conversation : abonnement après le premier message',
        () async {
      const nouvelle = ConversationSummary(
        conversationId: '',
        partnerId: 'lui',
        partnerName: 'Thomas D.',
        lastMessage: '',
        unreadCount: 0,
      );
      when(() => messageService.sendMessage('lui', 'Premier !'))
          .thenAnswer((_) async => buildMessage(id: 'm1', senderId: 'moi'));

      final viewModel = makeViewModel(nouvelle);
      await viewModel.init();
      verifyNever(
          () => socketService.subscribeToConversation(any(), any()));

      viewModel.inputController.text = 'Premier !';
      await viewModel.send();

      // Le message renvoyé porte l'id de la conversation créée
      verify(() =>
              socketService.subscribeToConversation('conv-1', any()))
          .called(1);
    });
  });

  group('onMessageReceived (temps réel)', () {
    test('ajoute un message reçu, ignore les doublons', () async {
      when(() => messageService.getHistory('conv-1'))
          .thenAnswer((_) async => [buildMessage(id: 'm1')]);

      final viewModel = makeViewModel();
      await viewModel.init();

      final nouveau = buildMessage(id: 'm2');
      viewModel.onMessageReceived(nouveau);
      viewModel.onMessageReceived(nouveau); // doublon (broadcast + REST)

      expect(viewModel.messages, hasLength(2));
    });
  });
}
