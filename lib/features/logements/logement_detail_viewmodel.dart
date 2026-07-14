import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/disponibilite.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/reputation_score.dart';

/// Logique du détail d'un logement.
/// Le logement arrive en argument de navigation ; les disponibilités
/// et la réputation du propriétaire se chargent ensuite.
class LogementDetailViewModel extends BaseViewModel {
  final LogementService _logements;
  final ProfileService _profile;
  final NavigationService _nav;

  /// Logement affiché. Reçu en argument (souvent sans photos car la recherche
  /// ne les charge pas), il est rechargé complet dans [loadExtras] pour
  /// récupérer les URLs signées des photos.
  Logement logement;

  LogementDetailViewModel(
      {required this.logement,
      LogementService? logementService,
      ProfileService? profileService,
      NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<Disponibilite> disponibilites = [];
  ReputationScore? reputation;
  String? currentUserId;

  /// On ne peut pas se contacter soi-même (mon propre logement).
  bool get canContact =>
      currentUserId != null && currentUserId != logement.ownerId;

  /// Ouvre le chat avec le propriétaire (nouvelle conversation au 1er message).
  void contacter() {
    _nav.navigateTo(
      Routes.chatView,
      arguments: ChatViewArguments(
        conversation: ConversationSummary(
          conversationId: '',
          partnerId: logement.ownerId,
          partnerName: logement.ownerPrenom ?? 'Le propriétaire',
          lastMessage: '',
          unreadCount: 0,
        ),
      ),
    );
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
    setBusy(false);
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
