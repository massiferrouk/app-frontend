# Changelog — StudUp (application mobile Flutter)

Toutes les évolutions notables de l'application sont consignées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/) ;
versions selon [SemVer](https://semver.org/lang/fr/).

Rappel format Flutter : `version: 1.0.0+1` = version affichée `1.0.0`, numéro de build `1`.
Le détail fin est traçable dans l'historique Git (tickets Jira APP-XX) et les pull requests.

## [Non publié]

_Rien pour l'instant._

## [1.0.0+1] — 2026-07-18

Première version complète et fonctionnelle de l'application.

### Fondations
- Architecture Stacked (MVVM) : Views / ViewModels / Services (APP-60)
- Client HTTP Dio + intercepteur JWT + gestion d'erreurs (APP-61)
- Splash, connexion, inscription, stockage sécurisé des tokens (APP-63)

### Parcours alternant
- Création du profil (villes, rythme, dates, première semaine école/entreprise) (APP-64, APP-110)
- Navigation par rôle (bottom nav dynamique) (APP-65)
- Tableau de bord alternant (économies, prochaine semaine) (APP-66)
- Mon calendrier personnel avec override de semaine (APP-67)
- Suggestions de matching (cartes actives/potentielles, 4 mécanismes) (APP-68, APP-107)
- Calendrier de compatibilité colorisé + scénarios « Vos options » (APP-69, APP-109)

### Logements & accords
- Mes logements, ajout/édition avec photos, association aux villes (APP-70, APP-71, APP-72)
- Mes accords et détail (accepter/refuser/annuler) (APP-73, APP-74)

### Social & autres profils
- Messagerie temps réel + badge de non-lus (APP-75, APP-102)
- Notifications, avis et réputation (APP-76, APP-77)
- Recherche étudiant, tableau de bord propriétaire (APP-79, APP-80)

### Qualité & accessibilité
- 252 tests (ViewModels, services, widgets) ; couverture services 71 %
- Accessibilité OPQUAST : contrastes AA, alternatives textuelles, intitulés (APP-112)
- Pipeline CI GitHub Actions : analyze + tests sur chaque push et PR

[Non publié]: https://github.com/massiferrouk/studup-frontend/compare/v1.0.0...HEAD
[1.0.0+1]: https://github.com/massiferrouk/studup-frontend/releases/tag/v1.0.0
