import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../services/profile_service.dart';
import '../../../shared/models/enums.dart';

/// Logique du formulaire de création de profil alternant.
class ProfilCreationViewModel extends BaseViewModel {
  final ProfileService _profile;
  final NavigationService _nav;

  ProfilCreationViewModel(
      {ProfileService? profileService, NavigationService? navigationService})
      : _profile = profileService ?? locator<ProfileService>(),
        _nav = navigationService ?? locator<NavigationService>();

  final villeAController = TextEditingController();
  final villeBController = TextEditingController();
  final ecoleController = TextEditingController();
  final entrepriseController = TextEditingController();

  RythmeAlternance selectedRythme = RythmeAlternance.SEMAINE_1_1;

  // Première semaine du cycle : école ou entreprise (APP-110).
  // C'est ce champ qui permet les rythmes inversés (ex. 1 école PUIS 3
  // entreprise) — sans lui le calendrier généré serait faux.
  PremiereSemaine selectedPremiereSemaine = PremiereSemaine.ECOLE;

  DateTime? dateDebut;
  DateTime? dateFin;

  String? errorMessage;

  void selectRythme(RythmeAlternance? rythme) {
    if (rythme == null) return;
    selectedRythme = rythme;
    // Changer de rythme réaligne le défaut (le 3-1 démarre le plus souvent
    // en entreprise) — l'utilisateur peut toujours choisir l'inverse après
    selectedPremiereSemaine = PremiereSemaine.defaultFor(rythme);
    notifyListeners();
  }

  void selectPremiereSemaine(PremiereSemaine premiereSemaine) {
    selectedPremiereSemaine = premiereSemaine;
    notifyListeners();
  }

  void setDateDebut(DateTime? date) {
    if (date == null) return;
    dateDebut = date;
    notifyListeners();
  }

  void setDateFin(DateTime? date) {
    if (date == null) return;
    dateFin = date;
    notifyListeners();
  }

  /// Validation métier — null si tout est valide
  String? _validate() {
    // Noms au masculin ("Le nom de...") : le validateur suffixe "est requis"
    final requiredError = Validators.requiredField(
            villeAController.text, 'Le nom de la ville de l\'école') ??
        Validators.requiredField(
            villeBController.text, 'Le nom de la ville de l\'entreprise') ??
        Validators.requiredField(ecoleController.text, 'Le nom de l\'école') ??
        Validators.requiredField(
            entrepriseController.text, 'Le nom de l\'entreprise');
    if (requiredError != null) return requiredError;

    // 🟣 Règle métier StudUp : les deux villes doivent être différentes,
    // sinon il n'y a rien à échanger (même contrainte CHECK côté BDD)
    final villeA = villeAController.text.trim().toLowerCase();
    final villeB = villeBController.text.trim().toLowerCase();
    if (villeA == villeB) {
      return 'Les deux villes doivent être différentes';
    }

    if (dateDebut == null || dateFin == null) {
      return 'Les dates de début et de fin sont requises';
    }
    if (!dateDebut!.isBefore(dateFin!)) {
      return 'La date de début doit être avant la date de fin';
    }
    return null;
  }

  Future<void> submit() async {
    errorMessage = _validate();
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      await _profile.createAlternantProfile(
        villeA: villeAController.text.trim(),
        villeB: villeBController.text.trim(),
        ecole: ecoleController.text.trim(),
        entreprise: entrepriseController.text.trim(),
        dateDebut: dateDebut!,
        dateFin: dateFin!,
        rythme: selectedRythme,
        premiereSemaine: selectedPremiereSemaine,
      );
      // Profil créé (+ calendrier généré côté backend) → accueil
      await _nav.clearStackAndShow(Routes.mainView);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    villeAController.dispose();
    villeBController.dispose();
    ecoleController.dispose();
    entrepriseController.dispose();
    super.dispose();
  }
}
