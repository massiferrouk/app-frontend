# StudUp — application mobile

Application Flutter de **StudUp**, une plateforme de logement pour alternants et étudiants.

Un alternant partage son année entre deux villes selon un rythme fixe : trois semaines
en entreprise à Paris, une semaine à l'école à Lyon, et ainsi de suite. Beaucoup paient
deux loyers pour des logements qu'ils occupent à moitié. StudUp met en relation deux
alternants dont les rythmes se complètent, pour qu'ils échangent leurs logements ou en
partagent un seul.

Ce dépôt contient l'application. L'API Spring Boot est dans un dépôt séparé :
[app-backend](https://github.com/massiferrouk/app-backend).

---

## Démarrage rapide

### Étape 1 — Démarrer l'API

**L'application ne sert à rien sans son API.** Elle doit tourner **avant** de lancer
l'app. Depuis le dépôt backend, une seule commande suffit (Docker uniquement, rien
d'autre à installer) :

```bash
docker compose up -d --build
```

**Cette commande est longue au premier lancement : 10 à 25 minutes** (téléchargement des
images et compilation de l'API). Profitez-en pour faire l'étape 2 en parallèle.

Vérification :

```bash
curl http://localhost:8080/actuator/health/liveness
```

Doit répondre `{"status":"UP"}`. La marche à suivre complète est dans le README du
backend.

### Étape 2 — Installer Flutter

Une seule chose à installer : le **SDK Flutter** (version 3.38 ou supérieure).
Guide officiel : <https://docs.flutter.dev/get-started/install>

Vérification :

```bash
flutter --version
flutter doctor
```

`flutter doctor` liste des cibles possibles. **Une seule ligne doit être verte pour
suivre ce guide : `Chrome - develop for the web`.** Les avertissements sur Android
Studio, Visual Studio ou le mode développeur Windows peuvent être ignorés si vous
lancez l'application dans le navigateur.

### Étape 3 — Lancer l'application

Depuis ce dossier :

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

> La deuxième commande régénère le routeur et le conteneur d'injection de dépendances
> (`lib/app/app.router.dart` et `lib/app/app.locator.dart`) à partir de
> `lib/app/app.dart`. Ces deux fichiers sont commités, donc le projet compile même sans
> elle — mais la lancer garantit qu'ils correspondent bien au code, et c'est ce que fait
> l'intégration continue. En cas d'erreur
> `Target of URI doesn't exist: 'app.router.dart'`, c'est exactement la commande qui la
> résout.

**Le premier lancement prend une à deux minutes** — Flutter compile tout le projet vers
JavaScript. La fenêtre reste blanche pendant ce temps : c'est normal, il faut laisser
faire. Les lancements suivants sont quasi instantanés.

L'écran d'accueil (« Deux villes. Deux loyers. ») s'affiche ensuite dans Chrome.

### Étape 4 — Se mettre en format téléphone

StudUp est une application mobile : dans une fenêtre de navigateur en pleine largeur,
les écrans sont étirés. Pour la voir telle qu'elle est conçue, ouvrir les outils de
développement de Chrome et activer l'émulation d'appareil :

`F12` puis `Ctrl + Shift + M` (`Cmd + Shift + M` sur macOS), et choisir un iPhone ou un
Pixel dans la liste déroulante.

---

## Comptes de démonstration

Créés automatiquement par l'API lancée avec `docker compose` (profil `demo`). Ils sont
déjà confirmés : la connexion fonctionne directement.

**Mot de passe commun : `Demo1234!`**

> **Tester la création de compte, ça marche aussi.** En profil `demo`, un compte créé
> depuis l'écran d'inscription est confirmé automatiquement — on se connecte juste après.
> En temps normal l'inscription enverrait un e-mail de confirmation, mais aucun e-mail ne
> peut partir en local (la clé d'envoi est un secret de production) : le profil `demo`
> confirme donc les comptes à la place, pour que le flux reste testable de bout en bout.

| E-mail | Rôle | Ce qu'il permet de voir |
|---|---|---|
| `alternant1@studup.demo` | Alternant | Ludovic — école à Lyon, entreprise à Paris. Studio à Lyon. **Le compte à utiliser en premier.** |
| `alternant2@studup.demo` | Alternant | Inès — situation inverse, T1 à Paris. C'est le match de Ludovic. |
| `alternant3@studup.demo` | Alternant | Karim — même rythme que Ludovic, sans logement : match potentiel et colocation. |
| `etudiant@studup.demo` | Étudiant | Léa — recherche et candidatures. |
| `proprietaire@studup.demo` | Propriétaire | Marc — deux annonces publiées. |
| `admin@studup.demo` | Admin | Modération. |

### Le parcours à suivre

Connectez-vous avec **`alternant1@studup.demo`**, puis :

1. **Accueil** — la prochaine semaine, la ville où l'on sera, l'économie estimée.
2. **Mon calendrier** — les 52 semaines générées automatiquement, ville par ville. Une
   semaine peut être corrigée à la main (rattrapage, congés).
3. **Matches** — Inès apparaît en tête avec **75 %** et un badge de match actif ; Karim
   suit en match potentiel, avec ce qu'il manque pour que ça devienne concret.
4. **Ouvrir le match avec Inès** — le calendrier de compatibilité : les deux calendriers
   côte à côte, semaine par semaine, en vert les semaines d'échange et en gris les
   semaines où chacun reste chez soi. Trois vues : liste, mensuelle, annuelle.
5. **Messages** — une conversation déjà entamée avec Inès. En ouvrant une seconde
   fenêtre de navigateur en navigation privée, connectée sur le compte d'Inès, on voit
   les messages arriver **en temps réel** des deux côtés.

Le score de 75 % n'est pas arbitraire : sur un rythme trois semaines / une semaine,
trois semaines sur quatre sont réellement échangeables, la quatrième voit chacun rentrer
chez soi. L'application ne la compte pas comme un gain.

---

## Autres cibles de lancement

L'URL de l'API dépend de la cible — `localhost` ne veut pas dire la même chose depuis un
émulateur Android, qui voit la machine hôte sur une autre adresse.

```bash
# Navigateur, API sur la même machine — c'est la valeur par défaut
flutter run -d chrome

# Émulateur Android (Android Studio requis)
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api/v1

# Téléphone Android réel sur le même réseau Wi-Fi
# (adresse du PC obtenue avec « ipconfig » sous Windows, « ifconfig » sinon)
flutter run --dart-define=API_URL=http://192.168.1.20:8080/api/v1

# Contre un environnement déployé
flutter run -d chrome --dart-define=API_URL=https://<hôte>/api/v1
```

Aucune URL de production n'est écrite en dur : elle est injectée au build, avec
`http://localhost:8080/api/v1` comme seul défaut.

---

## En cas de problème

| Symptôme | Cause | Solution |
|---|---|---|
| `Target of URI doesn't exist: 'app.router.dart'` ou `'app.locator.dart'` | Le code généré est absent ou périmé | `dart run build_runner build --delete-conflicting-outputs` |
| `flutter : command not found` | Le SDK Flutter n'est pas dans le `PATH` | Reprendre l'étape « Add Flutter to your PATH » du guide d'installation |
| `No devices found` / `Unable to locate a development device` | Aucune cible détectée | `flutter doctor` doit montrer Chrome en vert. Sinon, installer Google Chrome |
| Page blanche qui dure | Premier build web en cours | Attendre une à deux minutes. Si ça persiste au-delà : `flutter clean`, puis reprendre à `flutter pub get` |
| « Connexion impossible » / « Erreur réseau » à la connexion | L'API ne tourne pas | Vérifier `curl http://localhost:8080/actuator/health/liveness` |
| Connexion refusée depuis un émulateur Android | `localhost` désigne l'émulateur lui-même | Relancer avec `--dart-define=API_URL=http://10.0.2.2:8080/api/v1` |
| « Confirme ton adresse e-mail » après une inscription | L'API tourne sans le profil `demo` (aucun e-mail ne part en local) | Lancer l'API avec le profil `demo` — le cas par défaut de `docker compose` — où l'inscription confirme le compte automatiquement |
| Écrans vides après connexion | API démarrée sans le jeu de démonstration | Relancer l'API avec le profil `demo` (c'est le cas par défaut avec `docker compose`) |
| `Building with plugins requires symlink support` | Cible Windows desktop | Cette cible n'est pas prise en charge par le projet. Utiliser `-d chrome` |
| `GetIt: Object/factory ... is not registered` dans les tests | Une dépendance a été ajoutée au constructeur d'un ViewModel | Ajouter le mock correspondant dans le `setUp` du test |

---

## Trois profils, trois applications

La barre de navigation et l'écran d'accueil changent entièrement selon le rôle. Ce n'est
pas la même personne qui utilise l'app :

| Profil | Navigation |
|---|---|
| **Alternant** | Accueil · Matches · Recherche · Messages · Profil |
| **Étudiant** | Accueil · Recherche · Candidatures · Messages · Profil |
| **Propriétaire** | Accueil · Logements · Messages · Alertes · Profil |
| **Administrateur** | Accueil · Comptes · Annonces · Modération · Profil |

Étudiant et alternant sont deux situations d'une même personne : le mode se change
depuis le profil, sans recréer de compte. Le propriétaire est un compte distinct.
L'administrateur en est un aussi : à la connexion, l'application bascule automatiquement
sur son espace de supervision (aucune adresse ni build séparés — le rôle est lu dans le
jeton). Compte de démonstration : `admin@studup.demo` / `Demo1234!`.

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
tactiles respectent une taille minimale et les contrastes sont vérifiés. Le détail est
dans [docs/accessibilite-opquast.md](docs/accessibilite-opquast.md).

**La messagerie d'abord.** L'application informe et met en relation ; l'organisation
concrète se règle dans la conversation entre les deux personnes. C'est ce qui a conduit
à retirer les accords formels : ils ajoutaient des écrans sans rien produire de plus
qu'un changement de statut.

---

## Tests

```bash
flutter analyze    # doit rester à zéro avertissement
flutter test
```

Aucune API n'est nécessaire : les services sont mockés.

La convention est un fichier de test par ViewModel, avec les services mockés (mocktail),
plus des tests de service qui vérifient les requêtes envoyées et le parsing des réponses
(http_mock_adapter). Les écrans critiques ont en plus des tests de widget : démarrage,
redirection selon l'état de session, navigation par rôle.

Le piège le plus fréquent sur ce projet : ajouter une dépendance au constructeur d'un
ViewModel fait échouer ses tests avec `GetIt: Object/factory ... is not registered`.
Il faut alors ajouter le mock correspondant dans le `setUp` du test.
