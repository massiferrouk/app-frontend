import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/conversation_summary.dart';
import 'conversations_viewmodel.dart';

/// Liste des conversations — onglet Messages du shell (tous rôles).
class ConversationsView extends StackedView<ConversationsViewModel> {
  const ConversationsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ConversationsViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
            child: Text('Messages',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ConversationsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.conversations.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextButton(
                onPressed: viewModel.load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: viewModel.conversations.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.chat_bubble_outline,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucune conversation.\n'
                  'Contacte un match pour démarrer !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : ListView.separated(
              itemCount: viewModel.conversations.length,
              separatorBuilder: (_, _) => const Divider(
                  height: 1, indent: AppSpacing.screenPadding + 52),
              itemBuilder: (context, index) {
                final c = viewModel.conversations[index];
                return _ConversationTile(
                  conversation: c,
                  onTap: () => viewModel.openConversation(c),
                );
              },
            ),
    );
  }

  @override
  ConversationsViewModel viewModelBuilder(BuildContext context) =>
      ConversationsViewModel();

  @override
  void onViewModelReady(ConversationsViewModel viewModel) => viewModel.load();
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor:
            hasUnread ? AppColors.echangeLight : AppColors.surfaceDark,
        child: Text(
          conversation.partnerName.isNotEmpty
              ? conversation.partnerName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color:
                hasUnread ? AppColors.echange : AppColors.textPrimary,
          ),
        ),
      ),
      title: Text(
        conversation.partnerName,
        style: TextStyle(
          fontSize: 15,
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color:
              hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.echange,
                borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM').format(date);
  }
}
