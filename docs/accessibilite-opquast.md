# Accessibilité StudUp — Référentiel OPQUAST (APP-112)

## Choix et justification du référentiel

Référentiel retenu : **OPQUAST** (Open Quality Standards), sous-ensemble accessibilité.

Justification :
- Référentiel de qualité web reconnu, explicitement cité par le référentiel RNCP.
- **Certification OPQUAST obtenue** par le développeur (module dédié en formation) : le
  choix est maîtrisé et défendable en soutenance.
- OPQUAST étant orienté web, ses règles d'accessibilité ont été **adaptées à une
  application mobile Flutter**. Le socle technique visé correspond au niveau AA de WCAG
  (dont OPQUAST reprend les principes) : contraste 4.5:1, alternatives textuelles,
  intitulés explicites, zones tactiles suffisantes.

## Grille de correspondance — règle OPQUAST → action StudUp

| Règle OPQUAST (principe) | Action mise en œuvre dans StudUp | Preuve |
|---|---|---|
| Chaque image porteuse d'information a une alternative textuelle | `semanticLabel` sur les photos de logement (`Image.network`) ; `Semantics(image, label)` sur les `CachedNetworkImage` (carrousel + plein écran) | `logement_detail_view.dart`, `mes_logements_view.dart`, `recherche_view.dart`, `home_etudiant_view.dart`, `ajouter_logement_view.dart` |
| Les boutons et liens ont un intitulé explicite | `tooltip` sur les 6 `IconButton` (notifications, envoyer, rechercher, ajouter logement, notation) | `chat_view`, `recherche_view`, `home_*`, `mes_logements_view`, `avis_view` |
| Le contraste texte/fond est suffisant | Couleur `textTertiary` foncée de `#9E9E9E` (2.7:1, non conforme) à `#757575` (4.6:1, conforme AA) | `app_colors.dart` + test `textContrastGuideline` |
| L'information n'est pas donnée par la seule couleur | La distinction ville école / entreprise dans le calendrier est toujours doublée d'un badge A/B et du nom de ville en texte (la barre colorée est décorative) | `semaine_card.dart`, `app_colors.dart` (villeB) |
| Les zones cliquables sont suffisamment grandes | `IconButton` Material : cible tactile 48x48 dp par défaut (conforme) | test `androidTapTargetGuideline` |
| Les composants d'interface exposent leur rôle | Composants Material Flutter (boutons, champs, listes) accessibles nativement à TalkBack/VoiceOver | test `labeledTapTargetGuideline` |
| La langue du contenu est définie | Application francophone, textes en français ; `locale` FR | `main.dart` |

## Vérification automatisée

Trois guidelines officielles Flutter sont exécutées en test (`test/accessibility/accessibility_test.dart`) :
- `textContrastGuideline` — contraste des textes (échouait avec l'ancien gris, verrouille la correction)
- `androidTapTargetGuideline` — zones tactiles ≥ 48x48 dp
- `labeledTapTargetGuideline` — tout élément actionnable possède un intitulé

## Vérification manuelle

- Test au lecteur d'écran **TalkBack** (Android) : parcours création de profil → matching →
  détail logement, annonces vocales cohérentes.
- (Capture vidéo de démonstration à joindre au dossier de soutenance.)

## Limites assumées

- OPQUAST est un référentiel web : l'adaptation mobile porte sur le sous-ensemble
  accessibilité, pas sur les règles spécifiquement web (SEO, URLs…).
- Le carrousel photo en plein écran reste perfectible (gestes de zoom non annoncés).
