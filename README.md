# StudUp — application mobile

Application Flutter de **StudUp**, une plateforme de logement pour alternants et étudiants.

Un alternant partage son année entre deux villes selon un rythme fixe : trois semaines
en entreprise à Paris, une semaine à l'école à Lyon, et ainsi de suite. Beaucoup paient
deux loyers pour des logements qu'ils occupent à moitié. StudUp met en relation deux
alternants dont les rythmes se complètent, pour qu'ils échangent leurs logements ou en
partagent un seul.

Ce dépôt contient l'application. L'API Spring Boot est dans un dépôt séparé.

---

## Trois profils, trois applications

La barre de navigation et l'écran d'accueil changent entièrement selon le rôle. Ce n'est
pas la même personne qui utilise l'app :

| Profil | Navigation |
|---|---|
| **Alternant** | Accueil · Matches · Recherche · Messages · Profil |
| **Étudiant** | Accueil · Recherche · Candidatures · Messages · Profil |
| **Propriétaire** | Accueil · Logements · Messages · Alertes · Profil |

Étudiant et alternant sont deux situations d'une même personne : le mode se change
depuis le profil, sans recréer de compte. Le propriétaire est un compte distinct.

---

## Écrans principaux

- **Création de profil d'alternance** — deux villes, un rythme, des dates. Le calendrier
  des 52 semaines se génère automatiquement côté serveur.
- **Mon calendrier** — la liste des semaines à venir, ville par ville, avec possibilité
  de corriger une semaine à la main (rattrapage, congés).
- **Suggestions de matching** — les alternants compatibles, classés par score, avec le
  type d'arrangement possible et ce qu'il manque le cas échéant.
- **Calendrier de compatibilité** — l'écran le plus dense de l'app : les deux calendriers
  côte à côte, semaine par semaine, en trois vues (liste, mensuelle, annuelle).
- **Annonces** — publication avec photos, recherche filtrée, fiche détaillée.
- **Candidatures** — suivi des annonces qui intéressent l'étudiant, avec un statut qu'il
  fait évoluer lui-même.
- **Messagerie** — temps réel, un fil par annonce, avec la carte du match en tête de
  conversation quand l'interlocuteur est un alternant compatible.

---

## Stack

| Domaine | Choix |
|---|---|
| Framework | Flutter 3, Dart 3.10 |
| Architecture | Stacked (MVVM) |
| Navigation et injection | Stacked Router + get_it, générés par build_runner |
| HTTP | Dio, avec intercepteur JWT |
| Stockage sécurisé | flutter_secure_storage (Keychain / Keystore) |
| Temps réel | stomp_dart_client (WebSocket STOMP) |
| Images | cached_network_image, image_picker |
| Dates | intl (format français) |
| Tests | flutter_test, mocktail, http_mock_adapter |

---

## Architecture

Stacked impose une séparation stricte, tenue partout dans le projet :

```
lib/
├── app/          app.dart — routes et services déclarés ici, le reste est généré
├── core/
│   ├── api/      client Dio, intercepteur d'authentification, configuration
│   ├── theme/    couleurs, espacements, thème — aucune couleur en dur ailleurs
│   └── utils/    formatage de dates, validateurs
├── features/     un dossier par écran : xxx_view.dart + xxx_viewmodel.dart
├── services/     appels API et logique partagée
└── shared/
    ├── models/   miroirs Dart des DTO backend, fromJson/toJson écrits à la main
    └── widgets/  composants réutilisés (cartes, badges, navigation)
```

Trois règles tenues partout :

1. **Une vue ne contient aucune logique.** Elle lit le ViewModel et affiche. Toute
   condition métier vit dans le ViewModel, ce qui la rend testable sans widget.
2. **Un ViewModel ne contient aucun widget** et n'appelle jamais Dio directement — il
   passe par un service.
3. **Chaque dépendance est injectable par constructeur.** Le locator sert de valeur par
   défaut ; les tests passent des mocks. C'est ce qui permet de tester chaque ViewModel
   sans lancer l'application.

Après toute modification de `lib/app/app.dart` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Sécurité côté client

- Les tokens JWT vont **exclusivement** dans `flutter_secure_storage` (Keychain iOS,
  Keystore Android) — jamais dans `shared_preferences`.
- L'intercepteur Dio attache l'access token, et sur un `401` tente un rafraîchissement
  puis rejoue la requête une seule fois. En cas d'échec, il déconnecte proprement.
- Aucune URL de production en dur : l'URL de l'API est injectée au build
  (`--dart-define=API_URL=...`), avec `localhost` comme seul défaut.
- Aucun token, e-mail ni mot de passe dans les logs.
- La validation des formulaires est faite côté client pour le confort, mais c'est
  toujours la réponse du serveur qui fait foi.

---

## Choix de conception

**Ne jamais afficher un chiffre inventé.** Si une donnée vaut zéro parce qu'aucun calcul
n'a pu être fait, l'écran n'affiche rien plutôt qu'un « 0 € économisés ». Plusieurs
indicateurs ont été retirés en cours de projet pour cette raison : ils affichaient un
zéro permanent faute de source de données réelle.

**Accessibilité (référentiel OPQUAST).** Une information n'est jamais portée par la seule
couleur : chaque état colorisé du calendrier porte aussi un libellé texte. Les zones
tactiles respectent une taille minimale et les contrastes sont vérifiés.

**La messagerie d'abord.** L'application informe et met en relation ; l'organisation
concrète se règle dans la conversation entre les deux personnes. C'est ce qui a conduit
à retirer les accords formels : ils ajoutaient des écrans sans rien produire de plus
qu'un changement de statut.

---

## Démarrer en local

**Prérequis** : Flutter 3, et l'API accessible.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

L'URL de l'API dépend de la cible — `localhost` ne fonctionne pas depuis un émulateur
Android, qui voit la machine hôte sur une autre adresse :

```bash
# Web ou desktop, API sur la même machine (valeur par défaut)
flutter run -d chrome

# Émulateur Android
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api/v1

# Téléphone réel sur le même réseau (adresse du PC via ipconfig)
flutter run --dart-define=API_URL=http://192.168.1.20:8080/api/v1

# Contre l'environnement de production
flutter run -d chrome --dart-define=API_URL=https://<hôte-railway>/api/v1
```

---

## Tests

```bash
flutter analyze    # doit rester à zéro avertissement
flutter test
```

La convention est un fichier de test par ViewModel, avec les services mockés (mocktail),
plus des tests de service qui vérifient les requêtes envoyées et le parsing des réponses
(http_mock_adapter). Les écrans critiques ont en plus des tests de widget : démarrage,
redirection selon l'état de session, navigation par rôle.

Le piège le plus fréquent sur ce projet : ajouter une dépendance au constructeur d'un
ViewModel fait échouer ses tests avec `GetIt: Object/factory ... is not registered`.
Il faut alors ajouter le mock correspondant dans le `setUp` du test.
