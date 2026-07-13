import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../services/logement_service.dart';
import '../../shared/models/enums.dart';

/// Logique du formulaire d'ajout de logement.
class AjouterLogementViewModel extends BaseViewModel {
  final LogementService _logements;
  final NavigationService _nav;

  AjouterLogementViewModel(
      {LogementService? logementService, NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _nav = navigationService ?? locator<NavigationService>();

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

  /// Crée le logement (BROUILLON), upload les photos,
  /// puis publie si [publierMaintenant].
  Future<void> submit({required bool publierMaintenant}) async {
    errorMessage = _validate();
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      final logement = await _logements.createLogement(
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        codePostal: codePostalController.text.trim(),
        type: selectedType,
        surface: double.parse(surfaceController.text.replaceAll(',', '.')),
        nbPieces: int.tryParse(nbPiecesController.text) ?? 1,
        loyer: double.parse(loyerController.text.replaceAll(',', '.')),
        charges:
            double.tryParse(chargesController.text.replaceAll(',', '.')) ?? 0,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        equipements: equipements.toList(),
        isMeuble: isMeuble,
      );

      if (photos.isNotEmpty) {
        await _logements.addPhotos(logement.id, photos);
      }

      if (publierMaintenant) {
        await _logements.publish(logement.id);
      }

      // Retour à la liste — elle se recharge au retour
      _nav.back(result: true);
    } on ApiException catch (e) {
      errorMessage = e.message;
      setBusy(false);
    }
  }

  @override
  void dispose() {
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
