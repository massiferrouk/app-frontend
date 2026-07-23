# Changelog — StudUp (application mobile Flutter)

Toutes les évolutions notables de l'application sont consignées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/) ;
versions selon [SemVer](https://semver.org/lang/fr/).

Rappel format Flutter : `version: 1.0.0+1` = version affichée `1.0.0`, numéro de build `1`.
Le détail fin est traçable dans l'historique Git (tickets Jira APP-XX) et les pull requests.

## [Non publié]

### Ajouté
- **Candidatures** : l'étudiant suit les annonces auxquelles il a postulé.
  L'onglet « Accords » de la navigation étudiant devient « Candidatures » (APP-117)

### Modifié
- **Retrait des accords de l'application** (APP-120). Un accord ne produisait qu'un
  changement de statut : ni planning semaine par semaine, ni loyer partagé, ni logement
  réellement engagé — tout ce qui compte se décide dans la messagerie. Sont supprimés le
  bouton « Formaliser un échange / une coloc » de l'écran de compatibilité, « Mes accords »
  pour les trois profils, le détail d'un accord, les tuiles accords des accueils, et le
  dépôt d'avis qui en dépendait.
  Le backend est conservé en l'état, ses endpoints simplement plus appelés.
  `AccordType` reste : c'est le vocabulaire du matching, pas la fonctionnalité accord.

### Corrigé — anomalies relevées en recette
- L'historique de conversation s'affiche désormais à l'ouverture d'un chat depuis
  « Contacter » : quand l'identifiant de conversation est vide, la conversation existante
  avec ce partenaire est retrouvée avant le chargement de l'historique (A-02)
- Écran de modification du profil d'alternance : un utilisateur qui s'est trompé à
  l'inscription (rythme, villes, dates, première semaine) peut désormais se corriger.
  Le endpoint backend existait déjà mais n'était appelé par aucun écran (A-04)

### Qualité & accessibilité
- 273 tests (ViewModels, services, modèles, widgets, accessibilité)
- Trois guidelines d'accessibilité vérifiées à chaque build : contraste des textes,
  taille des zones tactiles, présence d'un intitulé sur les éléments actionnables

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
