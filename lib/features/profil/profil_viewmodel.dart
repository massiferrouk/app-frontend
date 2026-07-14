import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/logement_service.dart';
import '../../services/profile_service.dart';
import '../../services/review_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/reputation_score.dart';
import '../../shared/models/review.dart';
import '../../shared/models/user.dart';

/// Logique de l'écran profil (mon profil).
class ProfilViewModel extends BaseViewModel {
  final ProfileService _profile;
  final LogementService _logements;
  final ReviewService _reviews;
  final AuthService _auth;
  final ChatSocketService _socket;
  final NavigationService _nav;

  ProfilViewModel({
    ProfileService? profileService,
    LogementService? logementService,
    ReviewService? reviewService,
    AuthService? authService,
    ChatSocketService? chatSocketService,
    NavigationService? navigationService,
  })  : _profile = profileService ?? locator<ProfileService>(),
        _logements = logementService ?? locator<LogementService>(),
        _reviews = reviewService ?? locator<ReviewService>(),
        _auth = authService ?? locator<AuthService>(),
        _socket = chatSocketService ?? locator<ChatSocketService>(),
        _nav = navigationService ?? locator<NavigationService>();

  User? user;
  ReputationScore? reputation;
  List<Review> avisRecus = [];
  List<Logement> logements = [];
  String? errorMessage;

  bool get isAlternant => user?.role == UserRole.ALTERNANT;

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
    try {
      reputation = await _logements.getReputation(user!.id);
    } on ApiException {/* pas encore de score */}
    try {
      avisRecus = await _reviews.getReviewsForUser(user!.id);
    } on ApiException {/* section vide */}
    try {
      logements = await _logements.getMesLogements();
    } on ApiException {/* section vide */}

    setBusy(false);
  }

  void goToCalendrier() => _nav.navigateTo(Routes.monCalendrierView);

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
