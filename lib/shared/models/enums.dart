// Les valeurs sont volontairement en SCREAMING_SNAKE_CASE pour correspondre
// exactement aux enums Java du backend (parsing JSON direct via values.byName).
// ignore_for_file: constant_identifier_names

/// Enums répliqués depuis le backend StudUp.
/// ⚠️ Les noms des valeurs doivent correspondre EXACTEMENT aux enums Java
/// (UserRole.java, AccordType.java...) : ils voyagent tels quels en JSON.
///
/// Convention de parsing : `XxxEnum.fromJson('VALEUR')` — lève une erreur
/// claire si le backend envoie une valeur inconnue.
library;

// ─── Rôles utilisateur ──────────────────────────────────────────

enum UserRole {
  ALTERNANT,
  ETUDIANT,
  PROPRIETAIRE,
  ADMIN;

  static UserRole fromJson(String value) => values.byName(value);
  String toJson() => name;
}

// ─── Rythme d'alternance ────────────────────────────────────────

enum RythmeAlternance {
  SEMAINE_1_1,
  SEMAINE_2_2,
  SEMAINE_3_1,
  MOIS_1_1,
  AUTRE;

  static RythmeAlternance fromJson(String value) => values.byName(value);
  String toJson() => name;

  /// Rythmes proposés à la saisie (APP-110) : AUTRE est retiré du choix —
  /// il générait un calendrier 1/1 par défaut incohérent avec la réalité.
  /// La valeur reste dans l'enum pour LIRE les profils historiques.
  static List<RythmeAlternance> get selectable =>
      values.where((r) => r != AUTRE).toList();

  /// Libellé affichable dans les dropdowns
  String get label => switch (this) {
        SEMAINE_1_1 => '1 semaine / 1 semaine',
        SEMAINE_2_2 => '2 semaines / 2 semaines',
        SEMAINE_3_1 => '3 semaines / 1 semaine',
        MOIS_1_1 => '1 mois / 1 mois',
        AUTRE => 'Autre rythme',
      };
}

/// Ordre de départ du cycle d'alternance (APP-110).
/// Sans lui, les rythmes inversés (ex. 1 sem école PUIS 3 entreprise)
/// génèrent un calendrier faux côté backend.
enum PremiereSemaine {
  ECOLE,
  ENTREPRISE;

  static PremiereSemaine fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        ECOLE => 'École',
        ENTREPRISE => 'Entreprise',
      };

  /// Défaut aligné sur l'ordre historique du backend :
  /// le 3-1 commençait par l'entreprise, tous les autres par l'école.
  static PremiereSemaine defaultFor(RythmeAlternance rythme) =>
      rythme == RythmeAlternance.SEMAINE_3_1 ? ENTREPRISE : ECOLE;
}

// ─── Accords ────────────────────────────────────────────────────

enum AccordType {
  ECHANGE_TOTAL,
  ECHANGE_PARTIEL,
  COLOCATION_TOURNANTE,
  LOCATION_CLASSIQUE,
  HEBERGEMENT_PONCTUEL;

  static AccordType fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        ECHANGE_TOTAL => 'Échange total',
        ECHANGE_PARTIEL => 'Échange partiel',
        COLOCATION_TOURNANTE => 'Colocation tournante',
        LOCATION_CLASSIQUE => 'Location classique',
        HEBERGEMENT_PONCTUEL => 'Hébergement ponctuel',
      };
}

enum AccordStatut {
  EN_ATTENTE,
  ACCEPTE,
  REFUSE,
  EN_COURS,
  TERMINE,
  ANNULE,
  LITIGE;

  static AccordStatut fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        EN_ATTENTE => 'En attente',
        ACCEPTE => 'Accepté',
        REFUSE => 'Refusé',
        EN_COURS => 'En cours',
        TERMINE => 'Terminé',
        ANNULE => 'Annulé',
        LITIGE => 'Litige',
      };
}

// ─── Logements ──────────────────────────────────────────────────

enum LogementType {
  STUDIO,
  T1,
  T2,
  T3_PLUS,
  CHAMBRE_COLOC;

  static LogementType fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        STUDIO => 'Studio',
        T1 => 'T1',
        T2 => 'T2',
        T3_PLUS => 'T3 et plus',
        CHAMBRE_COLOC => 'Chambre en colocation',
      };
}

enum LogementStatut {
  BROUILLON,
  ACTIF,
  SUSPENDU,
  ARCHIVE;

  static LogementStatut fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        BROUILLON => 'Brouillon',
        ACTIF => 'Actif',
        SUSPENDU => 'Suspendu',
        ARCHIVE => 'Archivé',
      };
}

enum DisponibiliteType {
  LIBRE,
  OCCUPE,
  BLOQUE;

  static DisponibiliteType fromJson(String value) => values.byName(value);
  String toJson() => name;

  String get label => switch (this) {
        LIBRE => 'Libre',
        OCCUPE => 'Occupé',
        BLOQUE => 'Bloqué',
      };
}

// ─── Matching / calendrier ──────────────────────────────────────

enum CompatibiliteType {
  ECHANGE,
  COLOCATION,
  CHEVAUCHEMENT,
  INCOMPATIBLE;

  static CompatibiliteType fromJson(String value) => values.byName(value);
  String toJson() => name;
}

// ─── Avis ───────────────────────────────────────────────────────

enum ReviewTargetType {
  USER,
  LOGEMENT;

  static ReviewTargetType fromJson(String value) => values.byName(value);
  String toJson() => name;
}

// ─── Notifications ──────────────────────────────────────────────
// ⚠️ Types liés aux paiements volontairement absents (hors périmètre)

enum NotificationType {
  NOUVEAU_MATCH,
  DEMANDE_ACCORD,
  ACCORD_ACCEPTE,
  ACCORD_REFUSE,
  NOUVEAU_MESSAGE,
  AVIS_RECU,
  DOCUMENT_VALIDE,
  DOCUMENT_REFUSE,
  RAPPEL_DEPART,
  RAPPEL_ARRIVEE,
  SYSTEME;

  static NotificationType fromJson(String value) => values.byName(value);
  String toJson() => name;
}
