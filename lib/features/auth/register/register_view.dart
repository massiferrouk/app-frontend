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
          // ─── Sélecteur de rôle compact ────────────────────
          // Choix rapide en une rangée + une ligne d'explication : le
          // formulaire reste immédiatement accessible en dessous.
          Text('Je suis…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _RoleChip(
                role: UserRole.ALTERNANT,
                icon: Icons.sync_alt,
                label: 'Alternant',
                viewModel: viewModel,
              ),
              const SizedBox(width: AppSpacing.sm),
              _RoleChip(
                role: UserRole.ETUDIANT,
                icon: Icons.school_outlined,
                label: 'Étudiant',
                viewModel: viewModel,
              ),
              const SizedBox(width: AppSpacing.sm),
              _RoleChip(
                role: UserRole.PROPRIETAIRE,
                icon: Icons.vpn_key_outlined,
                label: 'Propriétaire',
                viewModel: viewModel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_roleHelper(viewModel.selectedRole),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),

          // ─── Identité (prénom + nom côte à côte) ──────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: viewModel.firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: viewModel.lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Nom'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: viewModel.emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: viewModel.passwordController,
            obscureText: !viewModel.passwordVisible,
            decoration: InputDecoration(
              hintText: 'Mot de passe (8 caractères min.)',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                tooltip: viewModel.passwordVisible
                    ? 'Masquer le mot de passe'
                    : 'Afficher le mot de passe',
                icon: Icon(
                    viewModel.passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: viewModel.togglePasswordVisibility,
              ),
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
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: viewModel.backToLogin,
            child: const Text('Déjà un compte ? Se connecter'),
          ),
        ],
      ),
    );
  }
}

/// Une ligne d'explication du rôle sélectionné (englobe tous les cas).
String _roleHelper(UserRole role) => switch (role) {
      UserRole.ALTERNANT =>
        'Deux villes ? Échange ou partage ton logement pour payer moins.',
      UserRole.ETUDIANT => 'Trouve un logement à louer, près de ton école.',
      UserRole.PROPRIETAIRE => 'Loue ton logement à des étudiants vérifiés.',
      UserRole.ADMIN => '',
    };

// ─── Puce compacte de sélection de rôle (icône + libellé) ─────────

class _RoleChip extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String label;
  final RegisterViewModel viewModel;

  const _RoleChip({
    required this.role,
    required this.icon,
    required this.label,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedRole == role;
    final accent = isSelected ? AppColors.echange : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.selectRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.echangeLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: isSelected ? AppColors.echange : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? AppColors.echange : AppColors.textPrimary,
                ),
              ),
            ],
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
