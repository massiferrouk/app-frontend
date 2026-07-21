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
          // Recherche par contact — dès qu'il y a plusieurs conversations
          if (viewModel.afficheRecherche)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                  AppSpacing.screenPadding, AppSpacing.sm),
              child: TextField(
                onChanged: viewModel.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un contact',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
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

    // Aucune conversation du tout — état vide guidé
    if (viewModel.conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.load,
        color: AppColors.echange,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune conversation pour l\'instant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Contacte un propriétaire depuis une annonce, ou un alternant '
              'depuis tes matches, pour démarrer une discussion.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Filtre de recherche actif mais aucun résultat
    final items = viewModel.conversationsFiltrees;
    if (items.isEmpty) {
      return Center(
        child: Text('Aucun contact ne correspond à ta recherche.',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      color: AppColors.echange,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(
            height: 1, indent: AppSpacing.screenPadding + 64),
        itemBuilder: (context, index) {
          final c = items[index];
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
    final preview = conversation.lastMessage.trim();

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor:
            hasUnread ? AppColors.echangeLight : AppColors.surfaceDark,
        child: Text(
          _initials(conversation.partnerName),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: hasUnread ? AppColors.echange : AppColors.textPrimary,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              conversation.partnerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Annonce concernée (APP-119) : distingue deux fils avec le même
          // propriétaire quand il publie plusieurs logements.
          if (conversation.logementLabel != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(
                  conversation.logementLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        // Jamais de ligne vide : à défaut de message, une invite claire.
        preview.isEmpty ? 'Nouvelle conversation — dis bonjour 👋' : preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontStyle: preview.isEmpty ? FontStyle.italic : FontStyle.normal,
          color: preview.isEmpty
              ? AppColors.textTertiary
              : (hasUnread ? AppColors.textPrimary : AppColors.textSecondary),
          fontWeight:
              (preview.isNotEmpty && hasUnread) ? FontWeight.w600 : FontWeight.w400,
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

  /// Initiales sur 2 lettres (« Léa Martin » → « LM », « Léa » → « L »).
  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
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
