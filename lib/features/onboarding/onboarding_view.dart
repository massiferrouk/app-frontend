import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'onboarding_viewmodel.dart';

/// Onboarding du premier lancement — 3 écrans qui expliquent le concept
/// StudUp (APP-105). Les couleurs vert/bleu sont celles que l'utilisateur
/// retrouvera ensuite dans les calendriers et les match cards.
class OnboardingView extends StackedView<OnboardingViewModel> {
  const OnboardingView({super.key});

  static const _pages = [
    _PageData(
      icon: Icons.location_city_outlined,
      accent: AppColors.chevauchement,
      accentLight: AppColors.chevauchementLight,
      titre: 'Deux villes.\nDeux loyers.',
      texte: 'En alternance, tu vis entre ta ville d\'école et ta ville '
          'd\'entreprise. Résultat : jusqu\'à deux loyers à payer chaque '
          'mois.',
    ),
    _PageData(
      icon: Icons.swap_horiz,
      accent: AppColors.echange,
      accentLight: AppColors.echangeLight,
      titre: 'Échange ton logement.\nGratuitement.',
      texte: 'StudUp te matche avec un alternant au rythme inverse du tien : '
          'quand tu pars dans sa ville, il vient dans la tienne. Vos '
          'logements s\'échangent, zéro loyer en plus.',
    ),
    _PageData(
      icon: Icons.group_outlined,
      accent: AppColors.colocation,
      accentLight: AppColors.colocationLight,
      titre: 'Même rythme ?\nDivisez vos loyers.',
      texte: 'Deux alternants au même rythme partagent un logement dans '
          'chaque ville. Chacun paie moitié prix. C\'est la colocation '
          'tournante.',
    ),
  ];

  @override
  Widget builder(
    BuildContext context,
    OnboardingViewModel viewModel,
    Widget? child,
  ) {
    final page = _pages[viewModel.pageCourante];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Passer (masqué sur la dernière page) ───────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: viewModel.dernierePage
                    ? const SizedBox(height: 48)
                    : TextButton(
                        onPressed: viewModel.terminer,
                        child: const Text('Passer',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
              ),
            ),

            // ─── Les 3 pages swipables ──────────────────────────
            Expanded(
              child: PageView.builder(
                controller: viewModel.pageController,
                onPageChanged: viewModel.onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),

            // ─── Points indicateurs ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: viewModel.pageCourante == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: viewModel.pageCourante == i
                          ? page.accent
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),

            // ─── Bouton principal ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.suivant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.accent,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(
                      viewModel.dernierePage ? 'C\'est parti !' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) =>
      OnboardingViewModel();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _PageData {
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final String titre;
  final String texte;

  const _PageData({
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.titre,
    required this.texte,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration : grande pastille colorée + icône
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 72, color: data.accent),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.texte,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
