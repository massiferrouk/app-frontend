import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/candidature_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/logement_service.dart';
import '../../services/matching_service.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/message.dart';

/// Logique de l'écran de chat.
class ChatViewModel extends BaseViewModel {
  final MessageService _messages;
  final ProfileService _profile;
  final ChatSocketService _socket;
  final CandidatureService _candidatures;
  final LogementService _logements;
  final MatchingService _matching;
  final NavigationService _nav;
  final ConversationSummary conversation;

  ChatViewModel({
    required this.conversation,
    MessageService? messageService,
    ProfileService? profileService,
    ChatSocketService? chatSocketService,
    CandidatureService? candidatureService,
    LogementService? logementService,
    MatchingService? matchingService,
    NavigationService? navigationService,
  })  : _messages = messageService ?? locator<MessageService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _socket = chatSocketService ?? locator<ChatSocketService>(),
        _candidatures = candidatureService ?? locator<CandidatureService>(),
        _logements = logementService ?? locator<LogementService>(),
        _matching = matchingService ?? locator<MatchingService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Annonce sur laquelle porte la discussion — chargée depuis son id pour
  /// afficher la carte cliquable en tête de conversation (APP-119).
  /// null tant qu'elle n'est pas chargée, ou si le fil ne porte pas sur une
  /// annonce (mise en relation alternant ↔ alternant).
  Logement? logement;

  /// Charge l'annonce en arrière-plan. Échec silencieux : la conversation
  /// doit rester utilisable même si l'annonce ne se charge pas.
  Future<void> _loadLogement() async {
    final logementId = conversation.logementId;
    if (logementId == null) return;
    try {
      logement = await _logements.getLogement(logementId);
      notifyListeners();
    } on ApiException {
      // non bloquant : on garde l'en-tête texte de l'AppBar
    }
  }

  /// Tap sur la carte : ouvre le détail de l'annonce
  void ouvrirAnnonce() {
    final l = logement;
    if (l == null) return;
    _nav.navigateTo(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(logement: l),
    );
  }

  // ─── Contexte alternant ↔ alternant (APP-120) ────────────────────

  /// Match qui a mis les deux alternants en relation — null si la discussion
  /// porte sur une annonce (étudiant/proprio) ou s'ils ne sont plus
  /// compatibles (profil modifié depuis).
  ///
  /// Ici le sujet de la conversation n'est PAS une annonce mais un
  /// arrangement : il peut y avoir deux logements, un seul, ou aucun. Le seul
  /// contexte valable dans tous les cas, c'est le match lui-même.
  MatchingSuggestion? matchPartenaire;

  /// Cherche le match correspondant au partenaire. Silencieux : sans match,
  /// on n'affiche simplement aucune carte.
  Future<void> _loadMatch() async {
    // Une discussion rattachée à une annonce a déjà sa carte
    if (conversation.logementId != null) return;
    final partnerId = conversation.partnerId;
    if (partnerId == null) return;
    try {
      final suggestions = await _matching.getSuggestions();
      final trouve = suggestions.where((s) => s.userId == partnerId);
      matchPartenaire = trouve.isEmpty ? null : trouve.first;
      notifyListeners();
    } on ApiException {
      // non bloquant : pas de carte, la conversation reste utilisable
    }
  }

  /// Le partenaire a-t-il publié un logement ? (accès secondaire de la carte)
  bool get partenaireAUnLogement => matchPartenaire?.logementBId != null;

  /// Tap principal : le calendrier de compatibilité — l'écran qui explique
  /// pourquoi ces deux-là se parlent (semaines, options, économies).
  void ouvrirCompatibilite() {
    final match = matchPartenaire;
    if (match == null) return;
    _nav.navigateTo(
      Routes.compatibiliteView,
      arguments: CompatibiliteViewArguments(suggestion: match),
    );
  }

  /// Accès secondaire : l'annonce du partenaire, quand il en a publié une.
  /// Chargée à la demande — la suggestion ne porte que son identifiant.
  Future<void> ouvrirLogementPartenaire() async {
    final logementId = matchPartenaire?.logementBId;
    if (logementId == null) return;
    try {
      final l = await _logements.getLogement(logementId);
      await _nav.navigateTo(
        Routes.logementDetailView,
        arguments: LogementDetailViewArguments(logement: l),
      );
    } on ApiException {
      // silencieux : l'annonce a pu être dépubliée entre-temps
    }
  }

  /// Conversation à laquelle on est abonné en temps réel
  String? _subscribedConversationId;

  /// Id de conversation effectif. Vide à l'ouverture via « Contacter » ;
  /// résolu depuis le partenaire si une conversation existe déjà (A-02).
  String _conversationId = '';

  final inputController = TextEditingController();

  /// Vrai tant que `init()` n'a pas fini (résolution + chargement historique).
  /// Évite de faire clignoter l'état vide « Dis bonjour » avant l'historique.
  bool initializing = true;

  /// Messages du plus ancien au plus récent (ordre d'affichage du chat)
  List<ChatMessage> messages = [];
  String? currentUserId;
  String? errorMessage;
  bool sending = false;

  bool isMine(ChatMessage m) => m.senderId == currentUserId;

  Future<void> init() async {
    currentUserId = await _profile.currentUserId();
    _conversationId = conversation.conversationId;
    // Le contexte (annonce OU match) se charge en parallèle : il n'est pas
    // requis pour discuter. Les deux s'excluent — voir _loadMatch.
    unawaited(_loadLogement());
    unawaited(_loadMatch());
    await _resolveExistingConversation();
    await load();
    initializing = false;
    notifyListeners();
    _markUnreadAsRead();
    _subscribeIfPossible(_conversationId);
  }

  /// Ouverture via « Contacter » (id vide) : si une conversation existe déjà
  /// avec ce partenaire, on la retrouve pour charger son historique au lieu
  /// d'afficher un chat vide « Dites bonjour à… » (anomalie A-02).
  ///
  /// APP-119 : on compare aussi l'ANNONCE. Chercher sur le seul partenaire
  /// rouvrait le fil d'un autre logement du même propriétaire — c'est
  /// exactement l'anomalie remontée en recette.
  Future<void> _resolveExistingConversation() async {
    if (_conversationId.isNotEmpty || conversation.partnerId == null) return;
    try {
      final convs = await _messages.getConversations();
      for (final c in convs) {
        if (c.partnerId == conversation.partnerId &&
            c.logementId == conversation.logementId) {
          _conversationId = c.conversationId;
          break;
        }
      }
    } on ApiException {
      // silencieux : on démarre alors une nouvelle conversation
    }
  }

  /// Abonnement temps réel — dès qu'on connaît l'id de la conversation
  void _subscribeIfPossible(String conversationId) {
    if (conversationId.isEmpty ||
        _subscribedConversationId == conversationId) {
      return;
    }
    _subscribedConversationId = conversationId;
    _socket.subscribeToConversation(conversationId, onMessageReceived);
  }

  Future<void> load() async {
    // Vraiment nouvelle conversation (aucune existante avec ce partenaire) :
    // pas encore d'historique. Elle sera créée au premier message envoyé.
    if (_conversationId.isEmpty) return;

    setBusy(true);
    try {
      // Le backend renvoie du plus récent au plus ancien : on inverse
      final history = await _messages.getHistory(_conversationId);
      messages = history.reversed.toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Marque les messages reçus non lus — en arrière-plan, sans bloquer
  Future<void> _markUnreadAsRead() async {
    final unread = messages
        .where((m) => !m.isRead && !isMine(m))
        .toList();
    for (final m in unread) {
      try {
        await _messages.markAsRead(m.id);
      } on ApiException {
        // silencieux
      }
    }
  }

  Future<void> send() async {
    final content = inputController.text.trim();
    if (content.isEmpty || sending) return;
    if (conversation.partnerId == null) return;

    sending = true;
    notifyListeners();
    try {
      // L'annonce voyage avec le message : le backend range le fil sur le
      // bon logement au lieu de tout regrouper par personne (APP-119)
      final sent = await _messages.sendMessage(
        conversation.partnerId!,
        content,
        logementId: conversation.logementId,
      );
      // Le broadcast WebSocket arrive souvent AVANT cette réponse REST :
      // le message est alors déjà dans la liste (via onMessageReceived).
      // Sans ce garde, l'émetteur voyait son message en double.
      if (!messages.any((m) => m.id == sent.id)) {
        messages.add(sent);
      }
      inputController.clear();
      errorMessage = null;
      // Nouvelle conversation : le backend vient de la créer,
      // on retient son id et on s'abonne au temps réel
      _conversationId = sent.conversationId;
      _subscribeIfPossible(sent.conversationId);
      // C'est l'envoi effectif qui vaut candidature (APP-119)
      _marquerContacte();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Vrai une fois l'annonce marquée « Contactée » — évite un POST par message
  bool _contacteMarque = false;

  /// Passe l'annonce en « Contacté » dans le suivi, au premier message envoyé.
  ///
  /// APP-119 : c'était fait au clic sur « Contacter », donc une annonce
  /// finissait en « Contacté » même si l'utilisateur repartait sans écrire.
  /// Ne s'applique qu'aux discussions portant sur une annonce.
  /// Silencieux : le suivi ne doit jamais gêner la messagerie.
  Future<void> _marquerContacte() async {
    final logementId = conversation.logementId;
    if (logementId == null || _contacteMarque) return;
    _contacteMarque = true;
    try {
      await _candidatures.suivre(
          logementId: logementId, statut: CandidatureStatut.CONTACTE);
    } on ApiException {
      // silencieux
    }
  }

  /// Injecte un message reçu en temps réel (WebSocket — étape 3).
  /// Ignore les doublons (le message envoyé revient aussi par le broadcast).
  void onMessageReceived(ChatMessage message) {
    if (messages.any((m) => m.id == message.id)) return;
    messages.add(message);
    notifyListeners();
    if (!isMine(message)) {
      _messages.markAsRead(message.id).catchError((_) {});
    }
  }

  @override
  void dispose() {
    if (_subscribedConversationId != null) {
      _socket.unsubscribeFromConversation(_subscribedConversationId!);
    }
    inputController.dispose();
    super.dispose();
  }
}
