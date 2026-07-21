import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/candidature_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/logement_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/alternant_profile.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/user.dart';

/// Logique de l'écran profil (mon profil).
class ProfilViewModel extends BaseViewModel {
  final ProfileService _profile;
  final LogementService _logements;
  final CandidatureService _candidatures;
  final AuthService _auth;
  final ChatSocketService _socket;
  final NavigationService _nav;

  ProfilViewModel({
    ProfileService? profileService,
    LogementService? logementService,
    CandidatureService? candidatureService,
    AuthService? authService,
    ChatSocketService? chatSocketService,
    NavigationService? navigationService,
  })  : _profile = profileService ?? locator<ProfileService>(),
        _logements = logementService ?? locator<LogementService>(),
        _candidatures = candidatureService ?? locator<CandidatureService>(),
        _auth = authService ?? locator<AuthService>(),
        _socket = chatSocketService ?? locator<ChatSocketService>(),
        _nav = navigationService ?? locator<NavigationService>();

  User? user;
  AlternantProfile? alternantProfile;
  List<Logement> logements = [];

  /// Résumé des candidatures pour la carte du profil (APP-117).
  int nbCandidatures = 0;
  int nbCandidaturesContactees = 0;

  String? errorMessage;

  bool get isAlternant => user?.role == UserRole.ALTERNANT;

  /// APP-117 : le changement de mode ne concerne que les comptes étudiant et
  /// alternant (deux situations d'une même personne). Un propriétaire (bailleur)
  /// ou un admin ne voit pas cette option.
  bool get canChangeMode =>
      user?.role == UserRole.ETUDIANT || user?.role == UserRole.ALTERNANT;

  /// Le mode « opposé » vers lequel on peut basculer, null si non applicable.
  UserRole? get otherStudentMode => switch (user?.role) {
        UserRole.ETUDIANT => UserRole.ALTERNANT,
        UserRole.ALTERNANT => UserRole.ETUDIANT,
        _ => null,
      };

  /// Change le mode du compte (APP-117), puis rafraîchit la session pour que le
  /// nouveau rôle soit dans le token (→ le menu du bas se met à jour).
  /// - Devient alternant SANS profil d'alternance → direction le formulaire.
  /// - Sinon → on relance l'app sur le menu, qui relit le rôle à jour.
  Future<void> changeMode(UserRole newRole) async {
    // Mémorisé AVANT le changement : c'est le rôle à rétablir si
    // l'utilisateur annule depuis le formulaire (APP-119)
    final ancienRole = user?.role;

    setBusy(true);
    try {
      await _profile.changeMode(newRole);
      await _auth.refreshSession();
    } on ApiException catch (e) {
      errorMessage = e.message;
      setBusy(false);
      notifyListeners();
      return;
    }

    // On vérifie en base (pas via le champ potentiellement périmé) s'il a déjà
    // un profil d'alternance — il a pu être alternant, repasser étudiant, revenir.
    if (newRole == UserRole.ALTERNANT) {
      AlternantProfile? existing;
      try {
        existing = await _profile.getMyAlternantProfile();
      } on ApiException {/* réseau : on tente quand même la création */}
      if (existing == null) {
        setBusy(false);
        // L'ancien rôle voyage avec la route : le formulaire propose alors
        // « Annuler » qui rétablit ce rôle (APP-119)
        await _nav.navigateTo(
          Routes.profilCreationView,
          arguments: ProfilCreationViewArguments(roleAnnulation: ancienRole),
        );
        return;
      }
    }

    await _nav.clearStackAndShow(Routes.mainView);
  }

  Future<void> load() async {
    setBusy(true);
    try {
      // L'identité est essentielle : son échec bloque l'écran
      user = await _profile.getMe();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
      setBusy(false);
      return;
    }

    // Enrichissements — chacun peut échouer sans bloquer
    if (isAlternant) {
      try {
        alternantProfile = await _profile.getMyAlternantProfile();
      } on ApiException {/* profil pas encore rempli */}
    }
    // APP-119 : réputation et avis ne sont plus chargés — plus rien ne les
    // affiche (fonctionnalité reportée en V2). Les services restent en place.
    try {
      logements = await _logements.getMesLogements();
    } on ApiException {/* section vide */}
    // Résumé des candidatures (APP-117) — pour la carte du profil
    try {
      final candidatures = await _candidatures.getMesCandidatures();
      nbCandidatures = candidatures.length;
      nbCandidaturesContactees = candidatures
          .where((c) => c.statut != CandidatureStatut.A_CONTACTER)
          .length;
    } on ApiException {/* carte masquée */}

    setBusy(false);
  }

  void goToCalendrier() => _nav.navigateTo(Routes.monCalendrierView);

  /// Mes accords formels (APP-117) : ils n'ont plus d'onglet dédié — les
  /// accords sont devenus rares (décision « messagerie-first »), on y accède
  /// donc depuis le Profil.
  void goToMesAccords() => _nav.navigateTo(
        Routes.mesAccordsView,
        arguments: const MesAccordsViewArguments(standalone: true),
      );

  /// Mes candidatures (APP-117). L'étudiant a un onglet dédié ; l'alternant,
  /// dont la bottom nav est pleine, y accède ici — il cherche lui aussi une
  /// location classique et crée donc des candidatures.
  void goToMesCandidatures() => _nav.navigateTo(
        Routes.mesCandidaturesView,
        arguments: const MesCandidaturesViewArguments(standalone: true),
      );

  /// Ouvre le formulaire en mode édition, pré-rempli avec le profil actuel.
  /// Au retour d'une modification, on recharge (calendrier/matchs recalculés).
  Future<void> goToEditAlternance() async {
    if (alternantProfile == null) return;
    final updated = await _nav.navigateTo(
      Routes.profilCreationView,
      arguments: ProfilCreationViewArguments(profile: alternantProfile),
    );
    if (updated == true) await load();
  }

  /// Ouvre le détail d'un de mes logements (données passées en argument).
  void goToLogementDetail(Logement logement) => _nav.navigateTo(
        Routes.logementDetailView,
        arguments: LogementDetailViewArguments(logement: logement),
      );

  /// Ouvre l'écran complet de gestion des logements (ajout, publication,
  /// association ville). Recharge le profil au retour (la liste a pu changer).
  Future<void> goToGererLogements() async {
    await _nav.navigateTo(
      Routes.mesLogementsView,
      arguments: const MesLogementsViewArguments(standalone: true),
    );
    await load();
  }

  /// Déconnexion : coupure du WebSocket (l'ancien compte ne doit plus
  /// recevoir de messages sur l'appareil), révocation serveur,
  /// purge locale, retour au login. (APP-89)
  Future<void> logout() async {
    setBusy(true);
    _socket.disconnect();
    await _auth.logout();
    await _nav.clearStackAndShow(Routes.loginView);
  }
}
