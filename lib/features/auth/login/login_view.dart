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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // ─── En-tête « hero » : logo + accroche ─────────────
              // Le login n'a pas d'AppBar (écran d'accueil) : on pose donc
              // ici l'identité de marque avec un badge logo, là où le
              // register se contente d'un titre d'AppBar.
              const _BrandHeader(),
              const SizedBox(height: AppSpacing.xl),

              // ─── Champs (icônes + œil, comme l'inscription) ─────
              TextField(
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: viewModel.passwordController,
                obscureText: !viewModel.passwordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => viewModel.login(),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    tooltip: viewModel.passwordVisible
                        ? 'Masquer le mot de passe'
                        : 'Afficher le mot de passe',
                    icon: Icon(
                      viewModel.passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: viewModel.togglePasswordVisibility,
                  ),
                ),
              ),

              // ─── Erreur ─────────────────────────────────────────
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ErrorBanner(message: viewModel.errorMessage!),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ─── Bouton principal ───────────────────────────────
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

              const SizedBox(height: AppSpacing.lg),

              // ─── Lien inscription ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: viewModel.goToRegister,
                    child: const Text('Inscris-toi'),
                  ),
                ],
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

// ─── En-tête de marque (logo rond + nom + accroche) ───────────────
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badge logo : cercle vert clair + icône « échange » (l'ADN produit
        // de StudUp), qui reprend l'icône du rôle Alternant du register.
        Container(
          height: 72,
          width: 72,
          decoration: const BoxDecoration(
            color: AppColors.echangeLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sync_alt,
            size: 34,
            color: AppColors.echange,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'StudUp',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Content de te revoir',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─── Bandeau d'erreur discret (icône + message sur fond rouge clair) ──
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
