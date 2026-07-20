import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/studup_bottom_nav.dart';
import '../candidatures/mes_candidatures_view.dart';
import '../dashboard/home_alternant_view.dart';
import '../dashboard/home_etudiant_view.dart';
import '../dashboard/home_proprio_view.dart';
import '../recherche/recherche_view.dart';
import '../logements/mes_logements_view.dart';
import '../matching/suggestions_view.dart';
import '../messages/conversations_view.dart';
import '../notifications/notifications_view.dart';
import '../profil/profil_view.dart';
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
        messagesBadge: viewModel.conversationsNonLues,
        alertesBadge: viewModel.notificationsNonLues,
      ),
    );
  }

  /// Les pages de chaque onglet — placeholders remplacés ticket par ticket
  List<Widget> _pagesForRole(UserRole role, MainViewModel viewModel) {
    switch (role) {
      case UserRole.ALTERNANT:
        return [
          // Le dashboard peut basculer sur l'onglet Matches (index 1)
          HomeAlternantView(
            key: _homeKey(viewModel),
            onSeeMatches: () => viewModel.setIndex(1),
          ),
          const SuggestionsView(),
          // Recherche de logements : onglet principal (comme les étudiants).
          // La gestion de « Mes logements » est accessible depuis le Profil.
          // onSeeMatches : la carte matching de la recherche bascule sur
          // l'onglet Matches (index 1) — alternants uniquement (APP-104).
          _rechercheTab(viewModel, onSeeMatches: () => viewModel.setIndex(1)),
          _conversationsTab(viewModel),
          const ProfilView(),
        ];
      case UserRole.ETUDIANT:
        return [
          HomeEtudiantView(
            key: _homeKey(viewModel),
            onSearch: () => viewModel.setIndex(1),
            onAccords: () => viewModel.setIndex(2),
          ),
          _rechercheTab(viewModel),
          // APP-117 : suivi des candidatures (l'onglet Accords était toujours
          // vide côté étudiant). onSearch renvoie sur l'onglet Recherche.
          MesCandidaturesView(onSearch: () => viewModel.setIndex(1)),
          _conversationsTab(viewModel),
          const ProfilView(),
        ];
      case UserRole.PROPRIETAIRE:
      case UserRole.ADMIN:
        return [
          HomeProprioView(
            key: _homeKey(viewModel),
            onSeeLogements: () => viewModel.setIndex(1),
          ),
          const MesLogementsView(),
          _conversationsTab(viewModel),
          const NotificationsView(),
          const ProfilView(),
        ];
    }
  }

  /// Clé du dashboard Accueil — change à chaque ouverture de l'onglet pour
  /// forcer un rechargement (accord reçu, etc.).
  Key _homeKey(MainViewModel viewModel) =>
      ValueKey('home-${viewModel.homeReloadKey}');

  /// ConversationsView avec une clé qui change à chaque ouverture de l'onglet,
  /// ce qui force son rechargement (onViewModelReady → load()).
  Widget _conversationsTab(MainViewModel viewModel) => ConversationsView(
        key: ValueKey('conversations-${viewModel.messagesReloadKey}'),
      );

  /// RechercheView rechargée à chaque ouverture de l'onglet (nouveaux
  /// logements publiés visibles sans relancer l'app).
  Widget _rechercheTab(MainViewModel viewModel,
          {VoidCallback? onSeeMatches}) =>
      RechercheView(
        key: ValueKey('recherche-${viewModel.rechercheReloadKey}'),
        onSeeMatches: onSeeMatches,
      );

  @override
  MainViewModel viewModelBuilder(BuildContext context) => MainViewModel();

  @override
  void onViewModelReady(MainViewModel viewModel) => viewModel.init();
}

