import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/enums.dart';
import 'register_viewmodel.dart';

/// Écran d'inscription avec sélecteur de rôle.
class RegisterView extends StackedView<RegisterViewModel> {
  const RegisterView({super.key});

  @override
  Widget builder(
    BuildContext context,
    RegisterViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: viewModel.emailSent
            ? _EmailSentMessage(onBack: viewModel.backToLogin)
            : _RegisterForm(viewModel: viewModel),
      ),
    );
  }

  @override
  RegisterViewModel viewModelBuilder(BuildContext context) =>
      RegisterViewModel();
}

// ─── Formulaire ───────────────────────────────────────────────────

class _RegisterForm extends StatelessWidget {
  final RegisterViewModel viewModel;

  const _RegisterForm({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Sélecteur de rôle ────────────────────────────
          Text('Je suis…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _RoleChip(
                label: 'Alternant',
                role: UserRole.ALTERNANT,
                viewModel: viewModel,
              ),
              const SizedBox(width: AppSpacing.sm),
              _RoleChip(
                label: 'Étudiant',
                role: UserRole.ETUDIANT,
                viewModel: viewModel,
              ),
              const SizedBox(width: AppSpacing.sm),
              _RoleChip(
                label: 'Propriétaire',
                role: UserRole.PROPRIETAIRE,
                viewModel: viewModel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Champs ───────────────────────────────────────
          TextField(
            controller: viewModel.firstNameController,
            decoration: const InputDecoration(hintText: 'Prénom'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: viewModel.lastNameController,
            decoration: const InputDecoration(hintText: 'Nom'),
          ),
          const SizedBox(height: AppSpacing.md),
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
            decoration: const InputDecoration(
              hintText: 'Mot de passe (8 caractères min.)',
            ),
          ),

          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              viewModel.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: viewModel.isBusy ? null : viewModel.register,
            child: viewModel.isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Créer mon compte'),
          ),
        ],
      ),
    );
  }
}

// ─── Chip de sélection de rôle ────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String label;
  final UserRole role;
  final RegisterViewModel viewModel;

  const _RoleChip({
    required this.label,
    required this.role,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.selectRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message post-inscription ─────────────────────────────────────

class _EmailSentMessage extends StatelessWidget {
  final VoidCallback onBack;

  const _EmailSentMessage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 64, color: AppColors.echange),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Vérifie ta boîte mail',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'On t\'a envoyé un lien de confirmation.\n'
            'Il est valable 24 heures.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: onBack,
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }
}
