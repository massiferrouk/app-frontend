import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/models/enums.dart';
import 'notifications_viewmodel.dart';

/// Notifications — utilisé en onglet (Alertes propriétaire) et
/// en écran empilé ([standalone] = true, avec AppBar).
class NotificationsView extends StackedView<NotificationsViewModel> {
  final bool standalone;

  const NotificationsView({super.key, this.standalone = false});

  @override
  Widget builder(
    BuildContext context,
    NotificationsViewModel viewModel,
    Widget? child,
  ) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
            child: Row(
              children: [
                if (!standalone)
                  Expanded(
                    child: Text('Notifications',
                        style: Theme.of(context).textTheme.headlineMedium),
                  )
                else
                  const Spacer(),
                if (viewModel.unreadCount > 0)
                  TextButton(
                    onPressed: viewModel.markAllAsRead,
                    child: const Text('Tout marquer comme lu'),
                  ),
              ],
            ),
          ),
          // Alertes sur le parc du propriétaire (APP-119) — pas des
          // notifications en base : rien à marquer comme lu, c'est un état.
          if (viewModel.alertesLogements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                  AppSpacing.screenPadding, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in viewModel.alertesLogements)
                    _AlerteLogement(texte: a),
                ],
              ),
            ),
          Expanded(child: _buildList(context, viewModel)),
        ],
      ),
    );

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: content,
    );
  }

  Widget _buildList(BuildContext context, NotificationsViewModel viewModel) {
    if (viewModel.isBusy && viewModel.notifications.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.errorMessage != null && viewModel.notifications.isEmpty) {
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
      child: viewModel.notifications.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.notifications_none,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('Aucune notification pour l\'instant.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final n = viewModel.notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    // Marque lue + ouvre l'écran ciblé par le deepLink
                    final error = await viewModel.ouvrirNotification(n);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  },
                );
              },
            ),
    );
  }

  @override
  NotificationsViewModel viewModelBuilder(BuildContext context) =>
      NotificationsViewModel();

  @override
  void onViewModelReady(NotificationsViewModel viewModel) => viewModel.load();
}

// ─── Tuile de notification ────────────────────────────────────────

/// Alerte sur le parc du propriétaire (APP-119) — état déduit des annonces,
/// visuellement distinct des notifications pour qu'on ne les confonde pas.
class _AlerteLogement extends StatelessWidget {
  final String texte;

  const _AlerteLogement({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.chevauchementLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.chevauchement),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});


  /// Icône + couleur par type de notification
  (IconData, Color) get _style => switch (notification.type) {
        NotificationType.NOUVEAU_MATCH => (
            Icons.swap_horiz,
            AppColors.echange
          ),
        NotificationType.DEMANDE_ACCORD => (
            Icons.handshake_outlined,
            AppColors.colocation
          ),
        NotificationType.ACCORD_ACCEPTE => (
            Icons.check_circle_outline,
            AppColors.echange
          ),
        NotificationType.ACCORD_REFUSE => (
            Icons.cancel_outlined,
            AppColors.error
          ),
        NotificationType.NOUVEAU_MESSAGE => (
            Icons.chat_bubble_outline,
            AppColors.textSecondary
          ),
        NotificationType.AVIS_RECU => (
            Icons.star_outline,
            AppColors.chevauchement
          ),
        NotificationType.DOCUMENT_VALIDE => (
            Icons.verified_outlined,
            AppColors.echange
          ),
        NotificationType.DOCUMENT_REFUSE => (
            Icons.gpp_bad_outlined,
            AppColors.error
          ),
        NotificationType.RAPPEL_DEPART ||
        NotificationType.RAPPEL_ARRIVEE =>
          (Icons.calendar_today_outlined, AppColors.chevauchement),
        // Un étudiant a mis l'annonce en favori (APP-119)
        NotificationType.ANNONCE_SUIVIE => (
            Icons.favorite_outline,
            AppColors.colocation
          ),
        NotificationType.SYSTEME => (
            Icons.info_outline,
            AppColors.textSecondary
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          // Non lue : fond légèrement teinté
          color: notification.isRead
              ? AppColors.background
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            // Point non-lu
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.echange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "il y a 5 min" / "il y a 3 h" / date complète au-delà de 7 jours
  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
