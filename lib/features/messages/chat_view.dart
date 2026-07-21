import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/message.dart';
import 'chat_viewmodel.dart';

/// Écran de chat — bulles envoyées à droite (vert), reçues à gauche (gris).
class ChatView extends StackedView<ChatViewModel> {
  final ConversationSummary conversation;

  const ChatView({super.key, required this.conversation});

  @override
  Widget builder(
    BuildContext context,
    ChatViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // L'annonce concernée est rappelée sous le nom (APP-119) : avec un
      // propriétaire qui publie plusieurs biens, on doit savoir de quel
      // logement on parle sans remonter tout le fil.
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.conversation.partnerName),
            if (viewModel.conversation.logementLabel != null)
              Text(
                viewModel.conversation.logementLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contexte de la conversation, en tête et cliquable.
            // Étudiant/proprio : l'annonce (APP-119).
            // Alternant ↔ alternant : le match, car le sujet est un
            // arrangement et non une annonce — il peut y en avoir deux,
            // une seule, ou aucune (APP-120).
            if (viewModel.logement != null)
              _AnnonceCard(
                logement: viewModel.logement!,
                onTap: viewModel.ouvrirAnnonce,
              )
            else if (viewModel.matchPartenaire != null)
              _MatchCard(
                match: viewModel.matchPartenaire!,
                onTap: viewModel.ouvrirCompatibilite,
                onVoirLogement: viewModel.partenaireAUnLogement
                    ? viewModel.ouvrirLogementPartenaire
                    : null,
              ),
            Expanded(child: _buildMessages(context, viewModel)),
            _InputBar(viewModel: viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context, ChatViewModel viewModel) {
    // Spinner pendant toute l'initialisation (résolution conversation +
    // chargement historique) pour ne pas faire clignoter l'état vide.
    if (viewModel.messages.isEmpty &&
        (viewModel.initializing || viewModel.isBusy)) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.echange));
    }

    if (viewModel.messages.isEmpty) {
      return Center(
        child: Text(
          'Dis bonjour à ${viewModel.conversation.partnerName} 👋',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    // reverse:true = ancré en bas comme toute messagerie ;
    // la liste est inversée pour l'affichage
    final reversed = viewModel.messages.reversed.toList();
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final m = reversed[index];
        return _Bubble(message: m, isMine: viewModel.isMine(m));
      },
    );
  }

  @override
  ChatViewModel viewModelBuilder(BuildContext context) =>
      ChatViewModel(conversation: conversation);

  @override
  void onViewModelReady(ChatViewModel viewModel) => viewModel.init();
}

// ─── Widgets internes ─────────────────────────────────────────────

/// Carte de l'annonce en tête de conversation (APP-119) — photo, type · ville
/// et loyer, cliquable pour ouvrir le détail. Comme sur leboncoin : on sait
/// toujours de quel bien on parle, et on y retourne en un tap.
///
/// Dégradation propre : si la photo manque ou ne charge pas (MinIO), on garde
/// une vignette neutre — l'info utile reste le texte.
class _AnnonceCard extends StatelessWidget {
  final Logement logement;
  final VoidCallback onTap;

  const _AnnonceCard({required this.logement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = logement.photoUrls.isEmpty ? null : logement.photoUrls.first;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: photo == null
                      ? const _VignetteVide()
                      : CachedNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const _VignetteVide(),
                          errorWidget: (_, _, _) => const _VignetteVide(),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${logement.type.label} · ${logement.ville}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${logement.loyer.round()} €/mois',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.echange),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de contexte d'une discussion entre alternants (APP-120).
///
/// Ici le sujet n'est pas une annonce mais un arrangement : selon les cas il y
/// a deux logements, un seul ou aucun. Le seul contexte valable partout est
/// donc le match — d'où le lien principal vers le calendrier de compatibilité,
/// l'écran qui explique pourquoi ces deux-là se parlent. Un accès secondaire
/// mène à l'annonce du partenaire quand il en a publié une.
class _MatchCard extends StatelessWidget {
  final MatchingSuggestion match;
  final VoidCallback onTap;
  final VoidCallback? onVoirLogement;

  const _MatchCard({
    required this.match,
    required this.onTap,
    this.onVoirLogement,
  });

  @override
  Widget build(BuildContext context) {
    final coloc = match.typePropose == AccordType.COLOCATION_TOURNANTE;
    final accent = coloc ? AppColors.colocation : AppColors.echange;

    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: coloc
                            ? AppColors.colocationLight
                            : AppColors.echangeLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${match.scorePercent}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            match.typePropose.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _resume,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            // Accès secondaire : son annonce, s'il en a publié une
            if (onVoirLogement != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.sm, bottom: AppSpacing.xs),
                  child: TextButton.icon(
                    onPressed: onVoirLogement,
                    icon: const Icon(Icons.apartment_outlined, size: 16),
                    label: const Text('Voir son logement',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Résumé court : les semaines qui comptent, et l'économie si elle est connue
  String get _resume {
    final parts = <String>[];
    if (match.nbSemainesEchange > 0) {
      parts.add('${match.nbSemainesEchange} sem. échange');
    }
    if (match.nbSemainesColocation > 0) {
      parts.add('${match.nbSemainesColocation} sem. coloc');
    }
    if (match.hasEconomie) {
      parts.add('jusqu\'à ${match.economieMensuelle} €/mois');
    }
    return parts.isEmpty ? 'Voir votre compatibilité' : parts.join(' · ');
  }
}

/// Vignette de repli quand il n'y a pas de photo exploitable
class _VignetteVide extends StatelessWidget {
  const _VignetteVide();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceDark,
        alignment: Alignment.center,
        child: const Icon(Icons.home_outlined,
            size: 22, color: AppColors.textTertiary),
      );
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppColors.echange : AppColors.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final ChatViewModel viewModel;

  const _InputBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: viewModel.inputController,
              maxLength: 2000, // limite backend
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => viewModel.send(),
              decoration: const InputDecoration(
                hintText: 'Ton message…',
                counterText: '',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Envoyer le message',
            onPressed: viewModel.sending ? null : viewModel.send,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.echange,
              disabledBackgroundColor: AppColors.surfaceDark,
            ),
            icon: viewModel.sending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
