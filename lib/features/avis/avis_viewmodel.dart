import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/profile_service.dart';
import '../../services/review_service.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';

/// Logique du dépôt d'avis après un accord terminé.
class AvisViewModel extends BaseViewModel {
  final ReviewService _reviews;
  final ProfileService _profile;
  final NavigationService _nav;

  /// L'accord TERMINE sur lequel porte l'avis
  final Accord accord;

  AvisViewModel({
    required this.accord,
    ReviewService? reviewService,
    ProfileService? profileService,
    NavigationService? navigationService,
  })  : _reviews = reviewService ?? locator<ReviewService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _nav = navigationService ?? locator<NavigationService>();

  final commentController = TextEditingController();

  /// 0 = pas encore noté (le bouton reste désactivé)
  int rating = 0;

  ReviewTargetType targetType = ReviewTargetType.USER;

  String? currentUserId;
  String? errorMessage;

  Future<void> init() async {
    currentUserId = await _profile.currentUserId();
    notifyListeners();
  }

  /// L'autre partie de l'accord (celle qu'on évalue)
  String? get partnerId {
    if (currentUserId == null) return null;
    return accord.isInitiator(currentUserId!)
        ? accord.receiverId
        : accord.initiatorId;
  }

  /// Le logement apporté par l'autre partie
  /// (logementA = initiateur, logementB = destinataire)
  String? get partnerLogementId {
    if (currentUserId == null) return null;
    return accord.isInitiator(currentUserId!)
        ? accord.logementBId
        : accord.logementAId;
  }

  /// La cible LOGEMENT n'est proposable que si l'autre partie
  /// a apporté un logement à l'accord
  bool get peutNoterLogement => partnerLogementId != null;

  void setRating(int value) {
    rating = value;
    notifyListeners();
  }

  void setTargetType(ReviewTargetType type) {
    targetType = type;
    notifyListeners();
  }

  Future<void> submit() async {
    if (rating < 1) {
      errorMessage = 'Choisis une note de 1 à 5 étoiles';
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      await _reviews.createReview(
        accordId: accord.id,
        targetType: targetType,
        targetUserId:
            targetType == ReviewTargetType.USER ? partnerId : null,
        targetLogementId: targetType == ReviewTargetType.LOGEMENT
            ? partnerLogementId
            : null,
        rating: rating,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      _nav.back(result: true);
    } on ApiException catch (e) {
      errorMessage = e.isConflict
          ? 'Tu as déjà laissé un avis pour cet accord'
          : e.message;
      setBusy(false);
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
