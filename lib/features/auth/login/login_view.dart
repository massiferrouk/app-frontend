import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'login_viewmodel.dart';

/// Écran de connexion — UI pure, toute la logique est dans le ViewModel.
class LoginView extends StackedView<LoginViewModel> {
  const LoginView({super.key});

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'StudUp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connecte-toi pour continuer',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Champs ─────────────────────────────────────
              TextField(
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: viewModel.passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Mot de passe'),
                onSubmitted: (_) => viewModel.login(),
              ),

              // ─── Erreur ─────────────────────────────────────
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ─── Bouton ─────────────────────────────────────
              ElevatedButton(
                onPressed: viewModel.isBusy ? null : viewModel.login,
                child: viewModel.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Se connecter'),
              ),

              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: viewModel.goToRegister,
                child: const Text('Pas encore de compte ? Inscris-toi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}
