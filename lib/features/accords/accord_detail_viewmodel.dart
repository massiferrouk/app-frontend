import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/accord.dart';

/// Logique du détail d'un accord.
class AccordDetailViewModel extends BaseViewModel {
  final AccordService _accords;
  final ProfileService _profile;

  /// Mis à jour après chaque action (accept → statut ACCEPTE...)
  Accord accord;

  AccordDetailViewModel({
    required this.accord,
    AccordService? accordService,
    ProfileService? profileService,
  })  : _accords = accordService ?? locator<AccordService>(),
        _profile = profileService ?? locator<ProfileService>();

  String? currentUserId;

  Future<void> init() async {
    currentUserId = await _profile.currentUserId();
    notifyListeners();
  }

  bool get canAcceptOrRefuse =>
      currentUserId != null && accord.canBeAnsweredBy(currentUserId!);

  bool get canCancel =>
      currentUserId != null && accord.canBeCancelledBy(currentUserId!);

  /// true si l'utilisateur connecté a envoyé cette demande
  bool get jeSuisInitiateur =>
      currentUserId != null && accord.isInitiator(currentUserId!);

  Future<String?> accept() => _run(() => _accords.accept(accord.id));

  Future<String?> refuse() => _run(() => _accords.refuse(accord.id));

  Future<String?> cancel() => _run(() => _accords.cancel(accord.id));

  Future<String?> _run(Future<Accord> Function() action) async {
    setBusy(true);
    try {
      accord = await action(); // l'écran reflète le nouveau statut
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      setBusy(false);
    }
  }
}
