import 'dart:convert';

/// Lecture des claims d'un JWT côté client.
///
/// ⚠️ Un JWT est signé, pas chiffré : son contenu est lisible par tous.
/// On LIT les claims (userId, role) pour adapter l'UI — mais aucune
/// décision de sécurité ne repose dessus : c'est le backend qui vérifie
/// la signature et applique les autorisations.
class JwtDecoder {
  JwtDecoder._();

  /// Décode le payload (2e bloc) d'un JWT. null si le token est malformé.
  static Map<String, dynamic>? decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      // base64Url.normalize ajoute le padding '=' manquant
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null; // token corrompu : on ne plante pas, on renvoie null
    }
  }

  /// Claim userId (sub ou userId selon la convention du backend)
  static String? userId(String token) {
    final payload = decodePayload(token);
    return (payload?['userId'] ?? payload?['sub']) as String?;
  }

  /// Claim role (ex: "ALTERNANT")
  static String? role(String token) =>
      decodePayload(token)?['role'] as String?;
}
