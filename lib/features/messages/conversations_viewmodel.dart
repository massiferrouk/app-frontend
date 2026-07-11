import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/message_service.dart';
import '../../shared/models/conversation_summary.dart';

/// Logique de la liste des conversations.
class ConversationsViewModel extends BaseViewModel {
  final MessageService _messages;
  final NavigationService _nav;

  ConversationsViewModel(
      {MessageService? messageService, NavigationService? navigationService})
      : _messages = messageService ?? locator<MessageService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<ConversationSummary> conversations = [];
  String? errorMessage;

  Future<void> load() async {
    setBusy(true);
    try {
      conversations = await _messages.getConversations();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Ouvre le chat, recharge au retour (les non-lus ont changé)
  Future<void> openConversation(ConversationSummary conversation) async {
    await _nav.navigateTo(
      Routes.chatView,
      arguments: ChatViewArguments(conversation: conversation),
    );
    await load();
  }
}
