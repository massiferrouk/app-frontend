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
/// 🟣 Chaque profil StudUp a sa propre navigation (cf. CLAUDE.md).
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
        NavTab(label: 'Accords', icon: Icons.description_outlined),
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
/// [messagesBadge] : conversations non lues affichées sur l'onglet Messages.
class StudUpBottomNav extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int messagesBadge;

  const StudUpBottomNav({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
    this.messagesBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = navTabsForRole(role);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: tabs
          .map((t) => BottomNavigationBarItem(
                icon: t.label == 'Messages'
                    ? Badge(
                        label: Text('$messagesBadge'),
                        isLabelVisible: messagesBadge > 0,
                        backgroundColor: AppColors.error,
                        child: Icon(t.icon),
                      )
                    : Icon(t.icon),
                label: t.label,
              ))
          .toList(),
    );
  }
}
