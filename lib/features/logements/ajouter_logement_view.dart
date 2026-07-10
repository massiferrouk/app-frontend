import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/enums.dart';
import 'ajouter_logement_viewmodel.dart';

/// Formulaire d'ajout de logement — créé en brouillon,
/// publiable immédiatement.
class AjouterLogementView extends StackedView<AjouterLogementViewModel> {
  const AjouterLogementView({super.key});

  @override
  Widget builder(
    BuildContext context,
    AjouterLogementViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ajouter un logement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Adresse ────────────────────────────────────
              TextField(
                controller: viewModel.adresseController,
                decoration: const InputDecoration(hintText: 'Adresse'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: viewModel.villeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Ville'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: viewModel.codePostalController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: const InputDecoration(
                          hintText: 'CP', counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Type + caractéristiques ────────────────────
              DropdownButtonFormField<LogementType>(
                initialValue: viewModel.selectedType,
                items: LogementType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: viewModel.selectType,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: viewModel.surfaceController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: 'Surface (m²)'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: viewModel.nbPiecesController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: 'Nb pièces'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: viewModel.loyerController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: 'Loyer (€/mois)'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: viewModel.chargesController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: 'Charges (€)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Meublé ─────────────────────────────────────
              SwitchListTile(
                value: viewModel.isMeuble,
                onChanged: viewModel.toggleMeuble,
                title: const Text('Meublé', style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.echange,
              ),

              // ─── Équipements ────────────────────────────────
              Text('Équipements',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: AjouterLogementViewModel.equipementsDisponibles
                    .map((e) => _EquipementChip(
                          label: e,
                          selected: viewModel.equipements.contains(e),
                          onTap: () => viewModel.toggleEquipement(e),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Description ────────────────────────────────
              TextField(
                controller: viewModel.descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                    hintText: 'Description (optionnelle)'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Photos ─────────────────────────────────────
              Text('Photos (${viewModel.photoPaths.length}/10)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _PhotosRow(viewModel: viewModel),

              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(viewModel.errorMessage!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ─── Boutons ────────────────────────────────────
              ElevatedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => viewModel.submit(publierMaintenant: true),
                child: viewModel.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Publier maintenant'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => viewModel.submit(publierMaintenant: false),
                child: const Text('Enregistrer en brouillon'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  AjouterLogementViewModel viewModelBuilder(BuildContext context) =>
      AjouterLogementViewModel();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _EquipementChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EquipementChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

class _PhotosRow extends StatelessWidget {
  final AjouterLogementViewModel viewModel;

  const _PhotosRow({required this.viewModel});

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    // maxWidth : compression côté client avant même l'envoi
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1920, imageQuality: 80);
    if (image == null) return;

    final added = viewModel.addPhoto(image.path);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 photos')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Bouton d'ajout
          GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.textTertiary),
            ),
          ),
          // Miniatures
          ...viewModel.photoPaths.map((path) => Stack(
                children: [
                  Container(
                    width: 84,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                          image: FileImage(File(path)), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => viewModel.removePhoto(path),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child:
                            Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
