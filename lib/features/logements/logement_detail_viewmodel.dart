import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/candidature_service.dart';
import '../../services/logement_service.dart';
import '../../services/matching_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/disponibilite.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/matching_suggestion.dart';
import '../../shared/models/reputation_score.dart';

/// Logique du détail d'un logement.
/// Le logement arrive en argument de navigation ; les disponibilités
/// et la réputation du propriétaire se chargent ensuite.
class LogementDetailViewModel extends BaseViewModel {
  final LogementService _logements;
  final MatchingService _matching;
  final ProfileService _profile;
  final CandidatureService _candidatures;
  final NavigationService _nav;

  /// Logement affiché. Reçu en argument (souvent sans photos car la recherche
  /// ne les charge pas), il est rechargé complet dans [loadExtras] pour
  /// récupérer les URLs signées des photos.
  Logement logement;

  LogementDetailViewModel(
      {required this.logement,
      LogementService? logementService,
      MatchingService? matchingService,
      ProfileService? profileService,
      CandidatureService? candidatureService,
      NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _matching = matchingService ?? locator<MatchingService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _candidatures = candidatureService ?? locator<CandidatureService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<Disponibilite> disponibilites = [];
  ReputationScore? reputation;
  String? currentUserId;

  /// Si l'annonceur est un alternant compatible avec moi : sa suggestion
  /// de matching (score, économie, semaines) — null sinon (APP-104).
  MatchingSuggestion? matchAnnonceur;

  /// On ne peut pas se contacter soi-même (mon propre logement).
  bool get canContact =>
      currentUserId != null && currentUserId != logement.ownerId;

  /// true si l'annonce est déjà dans mes candidatures (APP-117)
  bool isSuivi = false;

  /// Ouvre l'écran « Mes candidatures » (depuis le bouton « Dans mes
  /// candidatures ») pour que l'utilisateur retrouve l'annonce sans la chercher.
  void voirMesCandidatures() => _nav.navigateTo(
        Routes.mesCandidaturesView,
        arguments: const MesCandidaturesViewArguments(standalone: true),
      );

  /// Ajoute l'annonce au suivi sans contacter (bouton « Suivre »).
  /// Retourne null si OK, le message d'erreur sinon.
  Future<String?> suivre() async {
    try {
      await _candidatures.suivre(logementId: logement.id);
      isSuivi = true;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Ouvre le chat avec le propriétaire (nouvelle conversation au 1er message).
  ///
  /// APP-117 : contacter, c'est postuler — l'annonce passe en « Contacté »
  /// dans le suivi, ce qui évite le « j'ai déjà postulé à celle-là ou pas ? ».
  ///
  /// APP-119 : mais on ne l'enregistre PLUS ici. Ouvrir la discussion n'est pas
  /// postuler : l'utilisateur peut faire demi-tour sans rien écrire, et
  /// l'annonce se retrouvait quand même en « Contacté ». C'est désormais le
  /// premier message RÉELLEMENT envoyé qui pose le statut. Au retour du chat,
  /// on rafraîchit donc l'état du suivi.
  Future<void> contacter() async {
    await _nav.navigateTo(
      Routes.chatView,
      arguments: ChatViewArguments(
        conversation: ConversationSummary(
          conversationId: '',
          partnerId: logement.ownerId,
          partnerName: logement.ownerPrenom ?? 'Le propriétaire',
          lastMessage: '',
          unreadCount: 0,
          // La discussion porte sur CETTE annonce (APP-119) : un propriétaire
          // qui publie plusieurs biens a un fil par bien.
          logementId: logement.id,
          logementVille: logement.ville,
          logementType: logement.type,
        ),
      ),
    );

    // Un message a peut-être été envoyé pendant la discussion : le suivi a
    // alors changé côté serveur, on resynchronise le bouton.
    try {
      final mes = await _candidatures.getMesCandidatures();
      isSuivi = mes.any((c) => c.logement.id == logement.id);
      notifyListeners();
    } on ApiException {
      // non bloquant : le bouton garde son état actuel
    }
  }

  /// Charge les données secondaires. Chacune peut échouer sans bloquer
  /// l'écran : le logement principal est déjà affichable.
  Future<void> loadExtras() async {
    setBusy(true);
    currentUserId = await _profile.currentUserId();
    // Recharge le logement complet (avec URLs signées des photos) : la version
    // reçue de la recherche n'a pas les photos.
    try {
      logement = await _logements.getLogement(logement.id);
    } on ApiException {
      // Non bloquant : on garde la version reçue en argument
    }
    try {
      disponibilites = await _logements.getDisponibilites(logement.id);
    } on ApiException {
      // Non bloquant : la section disponibilités restera vide
    }
    try {
      reputation = await _logements.getReputation(logement.ownerId);
    } on ApiException {
      // Non bloquant : la carte propriétaire s'affiche sans score
    }
    // Déjà suivie ? Sert à afficher « Suivie ✓ » plutôt que « Suivre » (APP-117)
    try {
      final mes = await _candidatures.getMesCandidatures();
      isSuivi = mes.any((c) => c.logement.id == logement.id);
    } on ApiException {
      // Non bloquant : le bouton restera sur « Suivre »
    }
    await _loadMatchAnnonceur();
    setBusy(false);
  }

  /// Cherche l'annonceur dans mes suggestions de matching (APP-104).
  /// Alternants uniquement, jamais sur mon propre logement, erreurs muettes.
  Future<void> _loadMatchAnnonceur() async {
    if (currentUserId == null || currentUserId == logement.ownerId) return;
    try {
      if (await _profile.currentRole() != UserRole.ALTERNANT) return;
      final suggestions = await _matching.getSuggestions();
      final matches =
          suggestions.where((s) => s.userId == logement.ownerId);
      matchAnnonceur = matches.isEmpty ? null : matches.first;
    } on ApiException {
      // silencieux — la fiche reste complète sans la section matching
    }
  }

  /// Ouvre le calendrier de compatibilité avec l'annonceur
  void voirCompatibilite() {
    final match = matchAnnonceur;
    if (match == null) return;
    _nav.navigateTo(
      Routes.compatibiliteView,
      arguments: CompatibiliteViewArguments(suggestion: match),
    );
  }

  /// Disponibilités des 4 prochaines semaines uniquement
  List<Disponibilite> get prochainesDisponibilites {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 28));
    return disponibilites
        .where((d) =>
            d.dateFin.isAfter(now) && d.dateDebut.isBefore(horizon))
        .toList();
  }
}
