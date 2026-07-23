import 'enums.dart';

/// Miroir de l'AdminDashboardResponse backend (APP-121).
///
/// Uniquement des chiffres réellement calculables. Aucune métrique de revenus
/// (paiements hors périmètre), d'accords ni d'avis (retirés en APP-120) :
/// elles afficheraient un zéro permanent.
class AdminDashboard {
  final int totalComptes;
  final Map<UserRole, int> comptesParRole;
  final int comptesSuspendus;
  final int comptesBannis;
  final int inscriptions7Jours;
  final int inscriptions30Jours;

  final int totalAnnonces;
  final Map<LogementStatut, int> annoncesParStatut;

  final int signalementsEnAttente;

  /// Annonces signalées encore en ligne (APP-121)
  final int annoncesSignalees;
  final int motsInterdits;

  const AdminDashboard({
    required this.totalComptes,
    required this.comptesParRole,
    required this.comptesSuspendus,
    required this.comptesBannis,
    required this.inscriptions7Jours,
    required this.inscriptions30Jours,
    required this.totalAnnonces,
    required this.annoncesParStatut,
    required this.signalementsEnAttente,
    required this.annoncesSignalees,
    required this.motsInterdits,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalComptes: _int(json['totalComptes']),
      comptesParRole: _map(json['comptesParRole'], UserRole.fromJson),
      comptesSuspendus: _int(json['comptesSuspendus']),
      comptesBannis: _int(json['comptesBannis']),
      inscriptions7Jours: _int(json['inscriptions7Jours']),
      inscriptions30Jours: _int(json['inscriptions30Jours']),
      totalAnnonces: _int(json['totalAnnonces']),
      annoncesParStatut: _map(json['annoncesParStatut'], LogementStatut.fromJson),
      signalementsEnAttente: _int(json['signalementsEnAttente']),
      annoncesSignalees: _int(json['annoncesSignalees']),
      motsInterdits: _int(json['motsInterdits']),
    );
  }

  static int _int(dynamic value) => (value as num? ?? 0).toInt();

  /// Les clés JSON sont les noms des valeurs d'enum côté backend.
  /// Une clé inconnue est ignorée plutôt que de faire échouer tout l'écran :
  /// un enum élargi côté serveur ne doit pas casser une version déjà déployée.
  static Map<T, int> _map<T>(dynamic json, T Function(String) parse) {
    final result = <T, int>{};
    (json as Map<String, dynamic>? ?? {}).forEach((cle, valeur) {
      try {
        result[parse(cle)] = _int(valeur);
      } on ArgumentError {
        // valeur d'enum inconnue de cette version de l'app
      }
    });
    return result;
  }
}
