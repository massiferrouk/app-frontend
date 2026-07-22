import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/enums.dart';

/// Définition d'un onglet de navigation
class NavTab {
  final String label;
  final IconData icon;

  const NavTab({required this.label, required this.icon});
}

/// Les onglets par rôle — source de vérité unique de la navigation.
/// Chaque profil a des besoins distincts : l'alternant cherche un binôme,
/// l'étudiant une location, le propriétaire gère ses annonces.
List<NavTab> navTabsForRole(UserRole role) {
  switch (role) {
    case UserRole.ALTERNANT:
      return const [
        NavTab(label: 'Accueil', icon: Icons.home_outlined),
        NavTab(label: 'Matches', icon: Icons.swap_horiz),
        NavTab(label: 'Recherche', icon: Icons.search),
        NavTab(label: 'Messages', icon: Icons.chat_bubble_outline),
        NavTab(label: 'Profil', icon: Icons.person_outline),
      ];
    case UserRole.ETUDIANT:
      return const [
        NavTab(label: 'Accueil', icon: Icons.home_outlined),
        NavTab(label: 'Recherche', icon: Icons.search),
        // APP-117 : le suivi des candidatures remplace les accords, qui
        // restaient vides pour un étudiant (aucun parcours n'en crée).
        // APP-120 : les accords ont été retirés de l'app pour de bon.
        NavTab(label: 'Candidatures', icon: Icons.fact_check_outlined),
        NavTab(label: 'Messages', icon: Icons.chat_bubble_outline),
        NavTab(label: 'Profil', icon: Icons.person_outline),
      ];
    case UserRole.PROPRIETAIRE:
    case UserRole.ADMIN: // l'admin mobile voit la nav propriétaire
      return const [
        NavTab(label: 'Accueil', icon: Icons.home_outlined),
        NavTab(label: 'Logements', icon: Icons.apartment_outlined),
        NavTab(label: 'Messages', icon: Icons.chat_bubble_outline),
        NavTab(label: 'Alertes', icon: Icons.notifications_outlined),
        NavTab(label: 'Profil', icon: Icons.person_outline),
      ];
  }
}

/// Bottom nav StudUp — style du design system (sélection noire).
/// [messagesBadge] : conversations non lues sur l'onglet Messages.
/// [alertesBadge] : notifications non lues sur l'onglet Alertes (proprio).
class StudUpBottomNav extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int messagesBadge;
  final int alertesBadge;

  const StudUpBottomNav({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
    this.messagesBadge = 0,
    this.alertesBadge = 0,
  });

  /// Badge du tab selon son label — 0 = pas de badge
  int _badgeFor(NavTab tab) => switch (tab.label) {
        'Messages' => messagesBadge,
        'Alertes' => alertesBadge,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final tabs = navTabsForRole(role);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: tabs.map((t) {
        final badge = _badgeFor(t);
        return BottomNavigationBarItem(
          icon: badge > 0
              ? Badge(
                  label: Text('$badge'),
                  backgroundColor: AppColors.error,
                  child: Icon(t.icon),
                )
              : Icon(t.icon),
          label: t.label,
        );
      }).toList(),
    );
  }
}
