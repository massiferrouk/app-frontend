# CLAUDE.md — StudUp Frontend (Flutter)
> Fichier lu automatiquement par Claude Code à chaque session.
> Contient le contexte complet du frontend, les décisions d'architecture et le backlog.
> Le backend Spring Boot est dans un repo séparé : `Partie Code/backend` (voir son CLAUDE.md pour l'API).

---

## ÉTAT ACTUEL DU PROJET

- [x] Projet Flutter créé (Flutter 3.x, Dart 3.10)
- [x] Dépendances installées : stacked, stacked_services, dio, flutter_secure_storage, cached_network_image, intl
- [x] Design system créé : lib/core/theme/ (app_colors.dart, app_theme.dart, app_spacing.dart)
- [x] Repo GitHub : studup-frontend (privé)
- [x] CLAUDE.md + 21 tickets Jira créés (APP-60 → APP-80)
- [ ] Prochain ticket : APP-60 (F-01) Setup Stacked — app.dart + router + locator

> 💡 À mettre à jour après chaque ticket terminé.

---

## ⚠️ MODE PÉDAGOGIQUE — LIS CECI EN PREMIER

**Ce projet est un projet d'apprentissage autant qu'un projet professionnel réel.**
Le développeur est en phase de montée en compétences (premier projet Flutter). Ton rôle est d'enseigner tout en construisant.

### Règles absolues de collaboration

1. **Un ticket à la fois — jamais d'avance.** Attends la validation avant de passer à la suite. Si un ticket est long, découpe-le en étapes numérotées.
2. **Explique tout** : ce que fait le code, pourquoi ce choix, les erreurs fréquentes à éviter.
3. **Distingue 🔵 UNIVERSEL (pattern Flutter standard) de 🟣 SPÉCIFIQUE (logique StudUp).**
4. **Donne le contexte avant le code** : où le fichier se place, de quoi il dépend.
5. **Vérifie la compréhension après chaque bloc de code** avec une question.
6. **Explique les erreurs** : pourquoi ça a planté, comment reconnaître ce type d'erreur.
7. **Fiche de synthèse obligatoire après chaque ticket terminé** — format texte pur compatible Word (pas de bordures Unicode, pas de blocs code dans la fiche), même structure que le backend : CE QU'ON A CONSTRUIT / FICHIERS / PATTERNS UNIVERSELS / DÉCISIONS SPÉCIFIQUES / POINTS SOUTENANCE / QUESTIONS JURY / ERREURS FRÉQUENTES / CE QUE ÇA DÉBLOQUE.
8. **Guide Git à chaque étape** : branche par ticket, commits conventionnels avec clé Jira, PR vers main.
9. **Ne jamais exécuter de commandes git** — les donner au développeur dans le chat.
10. **Demander la clé Jira réelle (APP-XX) avant de créer une branche** — ne jamais l'inventer.

---

## 1. DESCRIPTION DU PROJET

**StudUp** — plateforme mobile de logement pour alternants en France.
Les alternants partagent leur temps entre deux villes selon un rythme fixe et paient souvent deux loyers. StudUp permet à deux alternants aux rythmes inversés d'échanger leurs logements gratuitement.

**4 mécanismes :** Échange total / Échange partiel / Colocation tournante / Location classique
**3 profils :** ALTERNANT / ETUDIANT / PROPRIETAIRE (+ ADMIN, non géré côté mobile)

**⛔ EXCLUS DE CETTE VERSION (ne jamais implémenter) :** tout ce qui touche aux paiements Stripe (US-025/026/027/048) et les notifications PAIEMENT_RECU, PAIEMENT_ECHOUE, CAUTION_RESTITUEE.

---

## 2. STACK TECHNIQUE

```
Framework   : Flutter 3.x (Dart 3.10)
Architecture: Stacked (MVVM) — View + ViewModel + Services
Navigation  : Stacked Router (généré par build_runner)
DI          : get_it via Stacked locator (généré)
HTTP        : Dio + intercepteurs JWT
Stockage    : flutter_secure_storage (tokens JWT), shared_preferences si besoin
Images      : cached_network_image (URLs signées MinIO)
Dates       : intl (format français)
Codegen     : stacked_generator + build_runner
```

**Commande après toute modification de app.dart :**
```
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. ARCHITECTURE STACKED — RÈGLES

- Chaque écran = 2 fichiers : `xxx_view.dart` (UI pure, zéro logique) + `xxx_viewmodel.dart` (logique pure, zéro widget)
- Les ViewModels étendent `BaseViewModel` (ou `FutureViewModel` pour un chargement initial)
- Les Services contiennent les appels API et la logique partagée — jamais d'appel Dio directement dans un ViewModel
- Tout est déclaré dans `lib/app/app.dart` via `@StackedApp(routes: [...], dependencies: [...])`
- `setBusy(true/false)` pour les états de chargement, `setError()` pour les erreurs

### Structure des dossiers

```
lib/
├── app/
│   ├── app.dart              # @StackedApp — routes + services déclarés ici
│   ├── app.router.dart       # GÉNÉRÉ — ne jamais éditer à la main
│   └── app.locator.dart      # GÉNÉRÉ — ne jamais éditer à la main
│
├── core/
│   ├── api/                  # api_client.dart (Dio), auth_interceptor.dart
│   ├── theme/                # app_colors.dart, app_theme.dart, app_spacing.dart
│   └── utils/                # date_formatter.dart, validators.dart
│
├── features/                 # un dossier par feature, view + viewmodel dedans
│   ├── auth/                 # splash, login, register, profil_creation
│   ├── dashboard/            # home_alternant, home_etudiant, home_proprio
│   ├── matching/             # suggestions, calendrier_compatibilite
│   ├── calendrier/           # mon_calendrier
│   ├── logements/            # mes_logements, ajouter, detail, disponibilites, recherche
│   ├── accords/              # mes_accords, accord_detail
│   ├── messages/             # conversations, chat
│   ├── notifications/
│   ├── avis/
│   └── profil/
│
├── services/                 # auth_service, matching_service, logement_service...
│
└── shared/
    ├── widgets/              # match_card, semaine_card, statut_badge, bottom_nav...
    └── models/               # DTOs Dart (user, logement, accord, matching_result...)
```

---

## 4. DESIGN SYSTEM — NE PAS DÉVIER

Validé sur le prototype HTML (Desktop/studup-prototype.html). Style : minimaliste, moderne, professionnel, clair.

```
Background      : #FFFFFF          AppColors.background
Texte principal : #1A1A1A          AppColors.textPrimary
Surfaces        : #FAFAFA/#F5F5F5  AppColors.surface / surfaceDark
Bordures        : #F0F0F0          AppColors.border
Vert (échange)  : #27AE60          AppColors.echange       ← CTA principaux
Bleu (coloc)    : #3498DB          AppColors.colocation
Orange (chevau.): #F39C12          AppColors.chevauchement
Rouge (erreur)  : #E74C3C          AppColors.error
Ville A (école) : #1A1A1A          AppColors.villeA
Ville B (entr.) : #9E9E9E          AppColors.villeB
```

- Jamais de couleur en dur dans un écran — toujours AppColors
- Espacements : AppSpacing (4/8/16/24/32/48), padding écran 20
- Coins : cards 12px, boutons 8px, chips 100px
- Pas de dark mode dans cette version

### Calendriers — affichage en LISTE VERTICALE, jamais en grille

**Mon calendrier (personnel)** : cartes semaine horizontales, barre colorée gauche 6px (villeA=foncé, villeB=gris), numéro semaine + dates à gauche, ville en gras au centre, badge A/B à droite, badge orange "Modifié" si override. Résumé rythme en haut avec barre bicolore.

**Calendrier compatibilité** : header deux profils côte à côte, chips résumé (vert/orange/bleu) + score en %, cartes semaine ~72px avec fond teinté selon type : ÉCHANGE #F0FAF4, CHEVAUCHEMENT #FFF8F0, COLOCATION #F0F7FF, INCOMPATIBLE #FAFAFA.

### Navigation par profil (bottom nav dynamique selon rôle)

```
Alternant    : Accueil | Matches | Logement | Messages | Profil
Étudiant     : Accueil | Recherche | Accords | Messages | Profil
Propriétaire : Accueil | Logements | Messages | Alertes | Profil
```

---

## 5. API BACKEND — CE QU'IL FAUT SAVOIR

```
Base URL dev : http://localhost:8080/api/v1
             : http://10.0.2.2:8080/api/v1 (émulateur Android — localhost ne marche pas !)
Auth         : JWT Bearer — access token 15 min + refresh token 7 jours
Erreurs      : {code, message, timestamp, path, details[]}
```

### Flow auth
1. POST /auth/register → 201 (compte PENDING_EMAIL, pas de token)
2. POST /auth/confirm → confirmation email
3. POST /auth/login → 200 {accessToken, refreshToken}
4. POST /auth/refresh → nouveau pair de tokens (rotation)
5. POST /auth/logout → révocation + blacklist

### Intercepteur Dio obligatoire
- Ajoute `Authorization: Bearer <accessToken>` sur chaque requête
- Sur 401 : tente POST /auth/refresh, rejoue la requête, sinon déconnecte
- Tokens stockés dans flutter_secure_storage, JAMAIS dans shared_preferences

### Endpoints principaux (détail complet dans le CLAUDE.md backend)
```
Auth        : POST /auth/register|confirm|login|refresh|logout
Profils     : POST/PUT /profile/alternant, POST /profile/proprietaire, GET /profile/{userId}
Logements   : GET/POST /logements, GET/PUT/DELETE /logements/{id},
              PUT /logements/{id}/publish, PATCH /logements/{id}/ville
Matching    : GET /matching/suggestions, GET /matching/score, GET /matching/partial
Calendrier  : GET /calendrier/compatibilite?user1=&user2=,
              PATCH /calendrier/{profileId}/semaines/{semaine}, GET /calendrier/export
Accords     : GET /accords/mes-accords, POST /accords, PUT /accords/{id}/accept|refuse|cancel
Messages    : GET /messages/{conversationId}, WS /ws (STOMP)
Avis        : POST /reviews, GET /reviews/user/{userId}, POST /reviews/{id}/report
Notifs      : GET /notifications, PUT /notifications/{id}/read, GET/PUT /notifications/preferences
Dashboards  : GET /dashboard/alternant, GET /dashboard/proprietaire
```

### Enums backend à répliquer en Dart (mêmes valeurs exactes)
```
UserRole          : ALTERNANT, ETUDIANT, PROPRIETAIRE, ADMIN
RythmeAlternance  : SEMAINE_1_1, SEMAINE_3_1, MOIS_1_1, AUTRE
AccordType        : ECHANGE_TOTAL, ECHANGE_PARTIEL, COLOCATION_TOURNANTE, LOCATION_CLASSIQUE, HEBERGEMENT_PONCTUEL
AccordStatut      : EN_ATTENTE, ACCEPTE, REFUSE, EN_COURS, TERMINE, ANNULE, LITIGE
LogementType      : STUDIO, T1, T2, T3_PLUS, CHAMBRE_COLOC
LogementStatut    : BROUILLON, ACTIF, SUSPENDU, ARCHIVE
CompatibiliteType : ECHANGE, COLOCATION, CHEVAUCHEMENT, INCOMPATIBLE
NotificationType  : NOUVEAU_MATCH, DEMANDE_ACCORD, ACCORD_ACCEPTE, ACCORD_REFUSE, NOUVEAU_MESSAGE,
                    AVIS_RECU, DOCUMENT_VALIDE, DOCUMENT_REFUSE, RAPPEL_DEPART, RAPPEL_ARRIVEE, SYSTEME
```

---

## 6. SÉCURITÉ — RÈGLES NON NÉGOCIABLES

- Tokens JWT dans flutter_secure_storage uniquement (Keychain iOS / Keystore Android)
- Jamais de token, email, mot de passe ou PII dans les logs (print/debugPrint)
- Jamais de secret ou d'URL de prod en dur dans le code — fichier de config par environnement
- Valider les entrées côté client (email, mots de passe ≥ 8 chars, champs requis) — mais la validation serveur fait foi
- Déconnexion = suppression des tokens du secure storage + appel POST /auth/logout

---

## 7. CONVENTIONS DE CODE

- Fichiers : snake_case (login_view.dart), classes : PascalCase (LoginView)
- Commentaires en français, code en anglais
- Un widget partagé dès qu'un composant est utilisé 2 fois → shared/widgets/
- Modèles : classes Dart immutables avec fromJson/toJson manuels (pas de codegen json_serializable pour l'instant — pédagogie d'abord)
- Textes UI en français directement (pas d'i18n dans cette version)
- Tests : viewmodel tests obligatoires par ticket (mocker les services), widget tests sur les écrans critiques (login, matching)

### Git
- Branches : feature/APP-XX-nom-court (clé Jira réelle, à demander)
- Commits : feat/fix/test/refactor/docs/chore(scope): message + clé Jira
- PR vers main après chaque ticket, CI verte avant merge

---

## 8. BACKLOG FRONTEND — ORDRE IMPOSÉ

> Tickets créés dans Jira (projet APP, labels frontend + phase-X). L'ordre est imposé par les dépendances techniques.

### Phase 1 — Fondations
```
APP-60  F-01  Setup Stacked : app.dart, router, locator, main.dart propre  (2 SP)  ✅ prérequis de tout
APP-61  F-02  Client API Dio + AuthInterceptor + gestion erreurs backend    (3 SP)
APP-62  F-03  Modèles Dart : User, AuthResponse, enums                      (2 SP)
APP-63  F-04  Splash + Login + Register (AuthService, secure storage)       (5 SP)
APP-64  F-05  Création profil alternant (villes, rythme, dates)             (3 SP)
APP-65  F-06  Bottom nav dynamique par rôle + shell de navigation           (3 SP)
```

### Phase 2 — Cœur alternant
```
APP-66  F-07  Dashboard alternant (économies, prochaine semaine)            (3 SP)
APP-67  F-08  Mon calendrier personnel (liste semaines, override)           (5 SP)
APP-68  F-09  Suggestions de matching (cards actifs/potentiels, 4 types)    (5 SP)
APP-69  F-10  Calendrier de compatibilité (duo, chips, semaines colorées)   (5 SP)
```

### Phase 3 — Logements & Accords
```
APP-70  F-11  Mes logements (statuts, association VILLE_A/VILLE_B)         (3 SP)
APP-71  F-12  Ajouter/éditer un logement (formulaire complet, photos)      (5 SP)
APP-72  F-13  Détail logement (carousel, équipements, dispo, contact)      (3 SP)
APP-73  F-14  Mes accords (tabs, statuts, actions accepter/refuser)        (5 SP)
APP-74  F-15  Détail accord (parties, logements, dates, actions)           (3 SP)
```

### Phase 4 — Social & autres profils
```
APP-75  F-16  Messagerie (liste conversations + chat, WebSocket STOMP)     (8 SP)
APP-76  F-17  Notifications (liste, types, marquer lu)                     (3 SP)
APP-77  F-18  Avis (étoiles interactives, commentaire, réputation)         (3 SP)
APP-78  F-19  Profil utilisateur (réputation, badges, logements, avis)     (3 SP)
APP-79  F-20  Dashboard + recherche étudiant (filtres)                     (5 SP)
APP-80  F-21  Dashboard propriétaire (KPIs, alertes)                       (3 SP)
```

---

## 9. ENVIRONNEMENT LOCAL

```
Backend local  : mvn spring-boot:run dans Partie Code/backend (port 8080)
BDD            : docker start yuniv-postgres (PostgreSQL 15, port 5433)
Émulateur      : Android Studio AVD — le backend est joignable sur http://10.0.2.2:8080
Device réel    : utiliser l'IP locale du PC (ipconfig) au lieu de localhost
Codegen        : dart run build_runner build --delete-conflicting-outputs
Analyse        : flutter analyze (0 erreur avant chaque commit)
Tests          : flutter test
```

---

*Dernière mise à jour : juillet 2026 — Phase 1 en cours — prochain ticket : APP-60 (F-01) Setup Stacked*
*Prototype HTML de référence : C:\Users\massi\Desktop\studup-prototype.html*
*Maquettes Figma générées à partir du prompt validé*
