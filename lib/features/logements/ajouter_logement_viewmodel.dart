import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../services/logement_service.dart';
import '../../shared/models/address_suggestion.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique du formulaire d'ajout / modification de logement.
class AjouterLogementViewModel extends BaseViewModel {
  final LogementService _logements;
  final NavigationService _nav;

  /// Logement à modifier ; null = création d'un nouveau logement.
  final Logement? existant;

  AjouterLogementViewModel(
      {this.existant,
      LogementService? logementService,
      NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _nav = navigationService ?? locator<NavigationService>() {
    _prefill();
  }

  bool get isEdition => existant != null;

  /// true si on édite un logement déjà publié (pas de bouton « brouillon »).
  bool get dejaPublie => existant?.statut == LogementStatut.ACTIF;

  /// Pré-remplit le formulaire depuis le logement existant (mode édition).
  void _prefill() {
    final l = existant;
    if (l == null) return;
    adresseController.text = l.adresse;
    villeController.text = l.ville;
    codePostalController.text = l.codePostal;
    surfaceController.text = l.surface.toStringAsFixed(0);
    nbPiecesController.text = l.nbPieces.toString();
    loyerController.text = l.loyer.toStringAsFixed(0);
    chargesController.text = l.charges.toStringAsFixed(0);
    descriptionController.text = l.description ?? '';
    selectedType = l.type;
    isMeuble = l.isMeuble;
    equipements.addAll(l.equipements);
  }

  // ─── Champs du formulaire ─────────────────────────────────────
  final adresseController = TextEditingController();
  final villeController = TextEditingController();
  final codePostalController = TextEditingController();
  final surfaceController = TextEditingController();
  final nbPiecesController = TextEditingController(text: '1');
  final loyerController = TextEditingController();
  final chargesController = TextEditingController(text: '0');
  final descriptionController = TextEditingController();

  LogementType selectedType = LogementType.STUDIO;
  bool isMeuble = true;

  /// Équipements proposés — clés envoyées telles quelles au backend
  static const equipementsDisponibles = [
    'wifi', 'parking', 'lave-linge', 'sèche-linge', 'lave-vaisselle', 'balcon',
  ];
  final Set<String> equipements = {};

  /// Photos sélectionnées (max 10). XFile fonctionne web ET mobile.
  final List<XFile> photos = [];

  String? errorMessage;

  // ─── Autocomplétion d'adresse (Base Adresse Nationale) ────────
  List<AddressSuggestion> addressSuggestions = [];
  Timer? _addressDebounce;

  /// Appelé à chaque frappe dans le champ adresse. Débounce 350ms puis
  /// interroge le backend. En dessous de 3 caractères, on vide les suggestions.
  void onAddressChanged(String query) {
    _addressDebounce?.cancel();
    if (query.trim().length < 3) {
      addressSuggestions = [];
      notifyListeners();
      return;
    }
    _addressDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        addressSuggestions = await _logements.autocompleteAddress(query.trim());
      } on ApiException {
        addressSuggestions = [];
      }
      notifyListeners();
    });
  }

  /// L'utilisateur choisit une suggestion : on remplit adresse + ville + CP.
  void applyAddressSuggestion(AddressSuggestion s) {
    if (s.adresse != null) adresseController.text = s.adresse!;
    if (s.ville != null) villeController.text = s.ville!;
    if (s.codePostal != null) codePostalController.text = s.codePostal!;
    addressSuggestions = [];
    notifyListeners();
  }

  void clearAddressSuggestions() {
    addressSuggestions = [];
    notifyListeners();
  }

  void selectType(LogementType? type) {
    if (type == null) return;
    selectedType = type;
    notifyListeners();
  }

  void toggleMeuble(bool value) {
    isMeuble = value;
    notifyListeners();
  }

  void toggleEquipement(String equipement) {
    equipements.contains(equipement)
        ? equipements.remove(equipement)
        : equipements.add(equipement);
    notifyListeners();
  }

  /// Ajoute une photo. Retourne false si la limite de 10 est atteinte.
  bool addPhoto(XFile photo) {
    if (photos.length >= 10) return false;
    photos.add(photo);
    notifyListeners();
    return true;
  }

  void removePhoto(XFile photo) {
    photos.remove(photo);
    notifyListeners();
  }

  String? _validate() {
    final required = Validators.requiredField(
            adresseController.text, 'L\'adresse') ??
        Validators.requiredField(villeController.text, 'Le nom de la ville');
    if (required != null) return required;

    if (!RegExp(r'^\d{5}$').hasMatch(codePostalController.text.trim())) {
      return 'Le code postal doit contenir 5 chiffres';
    }

    final surface = double.tryParse(surfaceController.text.replaceAll(',', '.'));
    if (surface == null || surface <= 0) {
      return 'La surface doit être un nombre supérieur à 0';
    }

    final loyer = double.tryParse(loyerController.text.replaceAll(',', '.'));
    if (loyer == null || loyer < 0) {
      return 'Le loyer doit être un nombre positif';
    }
    return null;
  }

  /// Crée (ou met à jour en mode édition) le logement, upload les nouvelles
  /// photos, puis publie si [publierMaintenant] (uniquement possible sur un
  /// brouillon).
  Future<void> submit({required bool publierMaintenant}) async {
    errorMessage = _validate();
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    final adresse = adresseController.text.trim();
    final ville = villeController.text.trim();
    final codePostal = codePostalController.text.trim();
    final surface = double.parse(surfaceController.text.replaceAll(',', '.'));
    final nbPieces = int.tryParse(nbPiecesController.text) ?? 1;
    final loyer = double.parse(loyerController.text.replaceAll(',', '.'));
    final charges =
        double.tryParse(chargesController.text.replaceAll(',', '.')) ?? 0;
    final description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();

    setBusy(true);
    try {
      final Logement logement;
      if (isEdition) {
        logement = await _logements.updateLogement(
          logementId: existant!.id,
          adresse: adresse,
          ville: ville,
          codePostal: codePostal,
          type: selectedType,
          surface: surface,
          nbPieces: nbPieces,
          loyer: loyer,
          charges: charges,
          description: description,
          equipements: equipements.toList(),
          isMeuble: isMeuble,
        );
      } else {
        logement = await _logements.createLogement(
          adresse: adresse,
          ville: ville,
          codePostal: codePostal,
          type: selectedType,
          surface: surface,
          nbPieces: nbPieces,
          loyer: loyer,
          charges: charges,
          description: description,
          equipements: equipements.toList(),
          isMeuble: isMeuble,
        );
      }

      // Photos nouvellement sélectionnées (ajoutées aux éventuelles existantes)
      if (photos.isNotEmpty) {
        await _logements.addPhotos(logement.id, photos);
      }

      if (publierMaintenant) {
        await _logements.publish(logement.id);
      }

      // Retour à la liste — elle se recharge au retour
      _nav.back(result: true);
    } on ApiException catch (e) {
      errorMessage = e.isConflict
          ? 'Ce logement est lié à un accord et ne peut plus être modifié'
          : e.message;
      setBusy(false);
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    adresseController.dispose();
    villeController.dispose();
    codePostalController.dispose();
    surfaceController.dispose();
    nbPiecesController.dispose();
    loyerController.dispose();
    chargesController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
