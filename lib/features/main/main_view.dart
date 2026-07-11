import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/studup_bottom_nav.dart';
import '../accords/mes_accords_view.dart';
import '../dashboard/home_alternant_view.dart';
import '../logements/mes_logements_view.dart';
import '../matching/suggestions_view.dart';
import '../notifications/notifications_view.dart';
import 'main_viewmodel.dart';

/// Shell de navigation — l'écran conteneur post-connexion.
/// Possède la bottom nav (variante selon le rôle) et conserve l'état
/// de chaque onglet grâce à IndexedStack.
class MainView extends StackedView<MainViewModel> {
  const MainView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MainViewModel viewModel,
    Widget? child,
  ) {
    final pages = _pagesForRole(viewModel.role, viewModel);

    return Scaffold(
      backgroundColor: AppColors.background,
      // IndexedStack : tous les onglets restent montés — le scroll et
      // les saisies ne sont pas perdus quand on change d'onglet
      body: IndexedStack(
        index: viewModel.currentIndex,
        children: pages,
      ),
      bottomNavigationBar: StudUpBottomNav(
        role: viewModel.role,
        currentIndex: viewModel.currentIndex,
        onTap: viewModel.setIndex,
      ),
    );
  }

  /// Les pages de chaque onglet — placeholders remplacés ticket par ticket
  List<Widget> _pagesForRole(UserRole role, MainViewModel viewModel) {
    switch (role) {
      case UserRole.ALTERNANT:
        return [
          // Le dashboard peut basculer sur l'onglet Matches (index 1)
          HomeAlternantView(onSeeMatches: () => viewModel.setIndex(1)),
          const SuggestionsView(),
          const MesLogementsView(),
          const _PlaceholderTab(title: 'Messages', ticket: 'APP-75'),
          const _PlaceholderTab(title: 'Profil', ticket: 'APP-78'),
        ];
      case UserRole.ETUDIANT:
        return const [
          _PlaceholderTab(title: 'Accueil', ticket: 'APP-79'),
          _PlaceholderTab(title: 'Recherche', ticket: 'APP-79'),
          MesAccordsView(),
          _PlaceholderTab(title: 'Messages', ticket: 'APP-75'),
          _PlaceholderTab(title: 'Profil', ticket: 'APP-78'),
        ];
      case UserRole.PROPRIETAIRE:
      case UserRole.ADMIN:
        return const [
          _PlaceholderTab(title: 'Accueil', ticket: 'APP-80'),
          MesLogementsView(),
          _PlaceholderTab(title: 'Messages', ticket: 'APP-75'),
          NotificationsView(),
          _PlaceholderTab(title: 'Profil', ticket: 'APP-78'),
        ];
    }
  }

  @override
  MainViewModel viewModelBuilder(BuildContext context) => MainViewModel();

  @override
  void onViewModelReady(MainViewModel viewModel) => viewModel.init();
}

/// Contenu provisoire d'un onglet
class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String ticket;

  const _PlaceholderTab({required this.title, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'À venir ($ticket)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
