import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Popup de confirmation unifiée (APP-119).
///
/// Avant, chaque écran construisait son AlertDialog Material : « Annuler » en
/// simple texte à côté d'un gros bouton plein — déséquilibré et daté. Ici,
/// deux boutons de MÊME taille côte à côte, pleine largeur :
/// Annuler (contour neutre) · Confirmer (plein, rouge si destructif).
///
/// Retourne true si l'utilisateur confirme, false sinon (bouton Annuler,
/// tap hors de la popup ou retour système).
Future<bool> confirmerAction(
  BuildContext context, {
  required String titre,
  String? message,
  String confirmer = 'Confirmer',
  String annuler = 'Annuler',
  bool destructif = false,
}) async {
  final confirme = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    // FittedBox : un libellé long rétrécit au lieu de passer
                    // sur deux lignes — un bouton tient toujours sur UNE ligne
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(annuler,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: destructif
                        ? ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          )
                        : ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(confirmer,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirme == true;
}
