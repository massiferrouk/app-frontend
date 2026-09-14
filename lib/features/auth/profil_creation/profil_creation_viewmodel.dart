import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/ville_service.dart';
import '../../../shared/models/alternant_profile.dart';
import '../../../shared/models/enums.dart';

/// Logique du formulaire de création — et de modification (APP-117 · A-04) —
/// du profil alternant. En mode édition, [existingProfile] pré-remplit le
/// formulaire et l'envoi passe par PUT au lieu de POST.
class ProfilCreationViewModel extends BaseViewModel {
  final ProfileService _profile;
  final AuthService _auth;
  final NavigationService _nav;
  final VilleService _villes;

  /// Profil déjà existant à modifier — null en création.
  final AlternantProfile? existingProfile;

  /// Rôle à rétablir si l'utilisateur annule un changement de mode (APP-119).
  /// Renseigné uniquement quand le formulaire s'ouvre depuis « Changer de
  /// mode » : le compte est alors DÉJÀ passé alternant côté serveur, donc
  /// annuler doit rétablir l'ancien rôle — un simple retour laisserait un
  /// alternant sans profil d'alternance (état incohérent).
  /// null dans le parcours d'inscription : la création reste obligatoire.
  final UserRole? roleAnnulation;

  ProfilCreationViewModel({
    this.existingProfile,
    this.roleAnnulation,
    ProfileService? profileService,
    AuthService? authService,
    NavigationService? navigationService,
    VilleService? villeService,
  })  : _profile = profileService ?? locator<ProfileService>(),
        _auth = authService ?? locator<AuthService>(),
        _nav = navigationService ?? locator<NavigationService>(),
        _villes = villeService ?? locator<VilleService>() {
    // Pré-remplissage en mode édition (les controllers sont déjà initialisés
    // car ce sont des champs, donc évalués avant ce corps de constructeur).
    final p = existingProfile;
    if (p != null) {
      villeAController.text = p.villeA;
      villeBController.text = p.villeB;
      // Villes existantes (déjà enregistrées) réputées valides → ✓ direct.
      villeAValide = true;
      villeBValide = true;
      selectedRythme = p.rythme;
      selectedPremiereSemaine = p.premiereSemaine;
      dateDebut = p.dateDebut;
      dateFin = p.dateFin;
    }
    // Validation « en direct » (APP-122) : dès qu'un champ ville perd le focus,
    // on vérifie qu'il correspond à une vraie commune.
    villeAFocus.addListener(() {
      if (!villeAFocus.hasFocus) verifierVilleA();
    });
    villeBFocus.addListener(() {
      if (!villeBFocus.hasFocus) verifierVilleB();
    });
  }

  bool get isEdition => existingProfile != null;

  /// true si un bouton Annuler doit être proposé (ouverture via « Changer de
  /// mode ») — jamais en édition ni dans le parcours d'inscription.
  bool get peutAnnuler => !isEdition && roleAnnulation != null;

  /// Annule le changement de mode (APP-119) : rétablit l'ancien rôle côté
  /// serveur, rafraîchit la session (le token doit reporter le rôle rétabli)
  /// puis revient en arrière — sur l'écran Profil d'où venait l'utilisateur,
  /// redevenu cohérent puisque le rôle est rétabli AVANT de quitter.
  /// En cas d'échec réseau, on reste sur le formulaire avec un message :
  /// quitter quand même laisserait le compte alternant sans profil.
  Future<void> annulerChangementMode() async {
    final role = roleAnnulation;
    if (role == null || isBusy) return;

    setBusy(true);
    try {
      await _profile.changeMode(role);
      await _auth.refreshSession();
      _nav.back();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }


  final villeAController = TextEditingController();
  final villeBController = TextEditingController();

  // FocusNodes requis par RawAutocomplete (il pilote l'ouverture du menu).
  final villeAFocus = FocusNode();
  final villeBFocus = FocusNode();

  /// Communes proposées pour [query] — délègue au service (asset local).
  /// Utilisé par l'autocomplétion des deux champs ville (APP-122).
  Future<Iterable<String>> rechercherVilles(String query) =>
      _villes.rechercher(query);

  // Retour « en direct » sur chaque ville (APP-122) : erreur = message rouge
  // sous le champ ; valide = ville reconnue (✓ vert). La liste guide, mais elle
  // n'empêchait pas une faute de frappe (« marseile ») de passer : on la bloque.
  String? villeAErreur;
  String? villeBErreur;
  bool villeAValide = false;
  bool villeBValide = false;

  Future<void> verifierVilleA() =>
      _verifierVille(villeAController, (err, ok) {
        villeAErreur = err;
        villeAValide = ok;
      });

  Future<void> verifierVilleB() =>
      _verifierVille(villeBController, (err, ok) {
        villeBErreur = err;
        villeBValide = ok;
      });

  /// Résout la ville saisie contre la liste des communes. Si elle correspond,
  /// on la réécrit à l'orthographe officielle (« marseille » → « Marseille »)
  /// et on marque valide ; sinon on affiche l'erreur. Champ vide = pas d'erreur
  /// ici (le « requis » est géré par la validation globale).
  Future<void> _verifierVille(
      TextEditingController c, void Function(String?, bool) setEtat) async {
    final saisie = c.text.trim();
    if (saisie.isEmpty) {
      setEtat(null, false);
      notifyListeners();
      return;
    }
    final officiel = await _villes.resoudre(saisie);
    if (officiel == null) {
      setEtat('Choisis une ville dans la liste', false);
    } else {
      if (officiel != c.text) c.text = officiel; // canonicalisation
      setEtat(null, true);
    }
    notifyListeners();
  }

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
            villeBController.text, 'Le nom de la ville de l\'entreprise');
    if (requiredError != null) return requiredError;

    // Les deux villes doivent être différentes, sinon il n'y a rien à
    // échanger (même contrainte CHECK côté BDD)
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
    // Filet de sécurité (APP-122) : on résout/canonicalise les deux villes.
    // Bloque une faute de frappe non corrigée en quittant le champ.
    await verifierVilleA();
    await verifierVilleB();

    errorMessage = _validate();
    if (errorMessage == null &&
        (villeAErreur != null || villeBErreur != null)) {
      errorMessage = 'Choisis des villes valides dans la liste';
    }
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      if (isEdition) {
        await _profile.updateAlternantProfile(
          villeA: villeAController.text.trim(),
          villeB: villeBController.text.trim(),
          dateDebut: dateDebut!,
          dateFin: dateFin!,
          rythme: selectedRythme,
          premiereSemaine: selectedPremiereSemaine,
        );
        // Modifié (+ calendrier régénéré côté backend) → retour au profil,
        // qui se recharge. On renvoie true pour signaler la mise à jour.
        _nav.back(result: true);
      } else {
        await _profile.createAlternantProfile(
          villeA: villeAController.text.trim(),
          villeB: villeBController.text.trim(),
          dateDebut: dateDebut!,
          dateFin: dateFin!,
          rythme: selectedRythme,
          premiereSemaine: selectedPremiereSemaine,
        );
        // Profil créé (+ calendrier généré côté backend) → accueil
        await _nav.clearStackAndShow(Routes.mainView);
      }
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
    villeAFocus.dispose();
    villeBFocus.dispose();
    super.dispose();
  }
}
