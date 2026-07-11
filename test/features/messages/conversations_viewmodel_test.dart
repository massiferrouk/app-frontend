import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/messages/conversations_viewmodel.dart';
import 'package:studup_app/services/message_service.dart';
import 'package:studup_app/shared/models/conversation_summary.dart';

class MockMessageService extends Mock implements MessageService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockMessageService messageService;
  late ConversationsViewModel viewModel;

  setUp(() {
    messageService = MockMessageService();
    viewModel = ConversationsViewModel(
      messageService: messageService,
      navigationService: MockNavigationService(),
    );
  });

  test('charge les conversations', () async {
    when(() => messageService.getConversations()).thenAnswer((_) async => [
          ConversationSummary.fromJson({
            'conversationId': 'c1',
            'partnerId': 'u1',
            'partnerName': 'Thomas D.',
            'lastMessage': 'Salut !',
            'lastMessageAt': DateTime.now().toIso8601String(),
            'unreadCount': 2,
          }),
        ]);

    await viewModel.load();

    expect(viewModel.conversations, hasLength(1));
    expect(viewModel.conversations.first.partnerName, 'Thomas D.');
    expect(viewModel.conversations.first.unreadCount, 2);
  });

  test('erreur API : message stocké', () async {
    when(() => messageService.getConversations()).thenThrow(
        const ApiException(
            code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

    await viewModel.load();

    expect(viewModel.errorMessage, 'Hors ligne');
    expect(viewModel.conversations, isEmpty);
  });
}
