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

  ConversationSummary conv(String id, String name) =>
      ConversationSummary.fromJson({
        'conversationId': id,
        'partnerId': 'u-$id',
        'partnerName': name,
        'lastMessage': 'coucou',
        'lastMessageAt': DateTime.now().toIso8601String(),
        'unreadCount': 0,
      });

  // APP-122 — stale-while-revalidate : en ré-entrée sur l'onglet, la liste
  // connue s'affiche tout de suite (sans spinner) et se rafraîchit en fond.
  test('cache présent : affiche la liste connue sans spinner, puis rafraîchit',
      () async {
    final ancien = [conv('c1', 'Ancien')];
    final frais = [conv('c1', 'Frais'), conv('c2', 'Nouveau')];
    when(() => messageService.cachedConversations).thenReturn(ancien);
    when(() => messageService.getConversations()).thenAnswer((_) async => frais);

    final future = viewModel.load();

    // Avant la fin du fetch : la liste en cache est déjà là, aucun état busy
    expect(viewModel.conversations, ancien);
    expect(viewModel.isBusy, isFalse);

    await future;

    // Puis remplacée par les données fraîches
    expect(viewModel.conversations, frais);
  });

  test('erreur API mais cache présent : on garde la liste, pas de message',
      () async {
    final ancien = [conv('c1', 'Ancien')];
    when(() => messageService.cachedConversations).thenReturn(ancien);
    when(() => messageService.getConversations()).thenThrow(const ApiException(
        code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

    await viewModel.load();

    expect(viewModel.conversations, ancien); // liste conservée
    expect(viewModel.errorMessage, isNull); // pas d'erreur par-dessus du contenu
  });
}
