import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/main/main_viewmodel.dart';
import 'package:studup_app/services/message_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/conversation_summary.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockMessageService extends Mock implements MessageService {}

void main() {
  late MockProfileService profile;
  late MockMessageService messages;
  late MainViewModel viewModel;

  ConversationSummary buildConv({required int unread}) => ConversationSummary(
        conversationId: 'c-$unread',
        partnerId: 'p1',
        partnerName: 'Thomas D.',
        lastMessage: 'Salut',
        unreadCount: unread,
      );

  setUp(() {
    profile = MockProfileService();
    messages = MockMessageService();
    // Par défaut : aucune conversation (le badge reste à 0)
    when(() => messages.getConversations()).thenAnswer((_) async => []);
    viewModel = MainViewModel(
      profileService: profile,
      messageService: messages,
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
  });
}
