import 'package:flutter_test/flutter_test.dart';
import 'package:studup_app/shared/models/auth_response.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/user.dart';

void main() {
  group('Enums — parsing des valeurs backend', () {
    test('fromJson parse les valeurs exactes du backend', () {
      expect(UserRole.fromJson('ALTERNANT'), UserRole.ALTERNANT);
      expect(RythmeAlternance.fromJson('SEMAINE_3_1'),
          RythmeAlternance.SEMAINE_3_1);
      expect(AccordType.fromJson('COLOCATION_TOURNANTE'),
          AccordType.COLOCATION_TOURNANTE);
      expect(AccordStatut.fromJson('EN_ATTENTE'), AccordStatut.EN_ATTENTE);
      expect(LogementType.fromJson('T3_PLUS'), LogementType.T3_PLUS);
      expect(LogementStatut.fromJson('BROUILLON'), LogementStatut.BROUILLON);
      expect(CompatibiliteType.fromJson('ECHANGE'), CompatibiliteType.ECHANGE);
      expect(NotificationType.fromJson('NOUVEAU_MATCH'),
          NotificationType.NOUVEAU_MATCH);
    });

    test('toJson restitue la valeur exacte', () {
      expect(UserRole.ALTERNANT.toJson(), 'ALTERNANT');
      expect(RythmeAlternance.SEMAINE_1_1.toJson(), 'SEMAINE_1_1');
      expect(AccordStatut.EN_COURS.toJson(), 'EN_COURS');
    });

    test('fromJson lève une erreur sur une valeur inconnue', () {
      expect(() => UserRole.fromJson('SUPERADMIN'), throwsArgumentError);
    });

    test('les labels français sont définis', () {
      expect(RythmeAlternance.SEMAINE_3_1.label, '3 semaines / 1 semaine');
      expect(AccordType.ECHANGE_TOTAL.label, 'Échange total');
      expect(AccordStatut.EN_ATTENTE.label, 'En attente');
      expect(LogementType.STUDIO.label, 'Studio');
    });
  });

  group('User', () {
    final json = {
      'id': 'a1b2c3d4-0000-0000-0000-000000000001',
      'email': 'alice@studup.fr',
      'firstName': 'Alice',
      'lastName': 'Martin',
      'role': 'ALTERNANT',
      'phone': null,
      'isVerified': true,
    };

    test('fromJson désérialise correctement', () {
      final user = User.fromJson(json);

      expect(user.email, 'alice@studup.fr');
      expect(user.role, UserRole.ALTERNANT);
      expect(user.phone, isNull);
      expect(user.isVerified, isTrue);
    });

    test('toJson puis fromJson restitue le même objet (aller-retour)', () {
      final user = User.fromJson(json);
      final roundTrip = User.fromJson(user.toJson());

      expect(roundTrip.id, user.id);
      expect(roundTrip.email, user.email);
      expect(roundTrip.role, user.role);
    });

    test('isVerified absent du JSON vaut false par défaut', () {
      final incomplete = Map<String, dynamic>.from(json)..remove('isVerified');

      expect(User.fromJson(incomplete).isVerified, isFalse);
    });

    test('initials et fullName', () {
      final user = User.fromJson(json);

      expect(user.initials, 'AM');
      expect(user.fullName, 'Alice Martin');
    });
  });

  group('AuthResponse', () {
    test('fromJson désérialise la paire de tokens', () {
      final response = AuthResponse.fromJson({
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
      });

      expect(response.accessToken, 'access-123');
      expect(response.refreshToken, 'refresh-456');
    });
  });
}
