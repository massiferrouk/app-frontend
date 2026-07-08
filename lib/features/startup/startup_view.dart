import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import 'startup_viewmodel.dart';

/// Écran de démarrage (splash) — premier écran affiché.
/// UI pure : toute la logique est dans StartupViewModel.
class StartupView extends StackedView<StartupViewModel> {
  const StartupView({super.key});

  @override
  Widget builder(
    BuildContext context,
    StartupViewModel viewModel,
    Widget? child,
  ) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'StudUp',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "L'échange de logement pour alternants",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(BuildContext context) =>
      StartupViewModel();

  /// Appelé une seule fois quand le ViewModel est prêt.
  @override
  void onViewModelReady(StartupViewModel viewModel) =>
      viewModel.runStartupLogic();
}
