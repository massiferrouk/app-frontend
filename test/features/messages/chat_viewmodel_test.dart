import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/messages/chat_viewmodel.dart';
import 'package:studup_app/services/message_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/conversation_summary.dart';
import 'package:studup_app/shared/models/message.dart';

class MockMessageService extends Mock implements MessageService {}

class MockProfileService extends Mock implements ProfileService {}

void main() {
  late MockMessageService messageService;
  late MockProfileService profileService;

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
      );

  setUp(() {
    messageService = MockMessageService();
    profileService = MockProfileService();
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
    when(() => messageService.markAsRead(any())).thenAnswer((_) async {});
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
