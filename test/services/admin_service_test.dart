import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/admin_service.dart';
import 'package:studup_app/shared/models/admin_user.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late AdminService service;

  const userJson = {
    'id': 'u1',
    'email': 'bob@studup.fr',
    'firstName': 'Bob',
    'lastName': 'Dupont',
    'role': 'ETUDIANT',
    'isVerified': true,
    'isActive': true,
    'createdAt': '2026-01-15T10:00:00Z',
    'deletedAt': null,
  };

  setUp(() {
    api = MockApiClient();
    service = AdminService(apiClient: api);
  });

  group('listUsers', () {
    test('parse la page et son total', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/users',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [userJson],
                'page': 0,
                'size': 20,
                'totalElements': 137,
                'hasNext': true,
              });

      final result = await service.listUsers();

      expect(result.users, hasLength(1));
      expect(result.users.first.fullName, 'Bob Dupont');
      expect(result.total, 137);
      expect(result.hasNext, isTrue);
    });

    test('n\'envoie que les filtres réellement posés', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/users',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {'content': []});

      await service.listUsers(role: UserRole.ALTERNANT);

      final envoye = verify(() => api.get<Map<String, dynamic>>('/admin/users',
              queryParameters: captureAny(named: 'queryParameters')))
          .captured
          .single as Map<String, dynamic>;
      expect(envoye['role'], 'ALTERNANT');
      // Aucun état demandé : le filtre ne doit pas partir du tout, sinon le
      // backend interpréterait isActive=null comme un filtre explicite.
      expect(envoye.containsKey('isActive'), isFalse);
      expect(envoye['page'], 0);
    });

    test('filtrer sur « banni » interroge les comptes inactifs', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/users',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {'content': []});

      await service.listUsers(etat: EtatCompte.banni);

      final envoye = verify(() => api.get<Map<String, dynamic>>('/admin/users',
              queryParameters: captureAny(named: 'queryParameters')))
          .captured
          .single as Map<String, dynamic>;
      // Le backend ne connaît pas « banni » : c'est deletedAt qui départage
      // suspendu et banni à l'affichage.
      expect(envoye['isActive'], isFalse);
    });
  });

  group('sanctions', () {
    test('suspendre, bannir et réactiver appellent la bonne route', () async {
      for (final (action, appel) in [
        ('suspend', service.suspendre),
        ('ban', service.bannir),
        ('reactivate', service.reactiver),
      ]) {
        when(() => api.put<Map<String, dynamic>>('/admin/users/u1/$action'))
            .thenAnswer((_) async => userJson);

        final result = await appel('u1');

        expect(result.id, 'u1');
        verify(() => api.put<Map<String, dynamic>>('/admin/users/u1/$action'))
            .called(1);
      }
    });
  });

  group('modération', () {
    const reportJson = {
      'id': 's1',
      'messageId': 'm1',
      'reporterId': 'r1',
      'motif': 'Propos déplacés',
      'createdAt': '2026-06-01T10:00:00Z',
      'contenuMessage': 'le texte signalé',
      'auteurId': 'a1',
      'auteurNom': 'Bob B',
      'messageCreeLe': '2026-05-30T09:00:00Z',
      'signalePar': 'Alice A',
    };

    test('signalements parse le contexte joint par le backend', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/moderation/messages',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [reportJson],
                'totalElements': 3,
                'hasNext': false,
              });

      final result = await service.signalements();

      expect(result.total, 3);
      final s = result.signalements.single;
      expect(s.contenuMessage, 'le texte signalé');
      expect(s.auteurNom, 'Bob B');
      expect(s.signalePar, 'Alice A');
      expect(s.contenuDisponible, isTrue);
    });

    test('signalements tolère un message disparu', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/moderation/messages',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [
                  {
                    'id': 's1',
                    'messageId': 'm1',
                    'reporterId': 'r1',
                    'motif': 'Motif',
                    'createdAt': '2026-06-01T10:00:00Z',
                    'contenuMessage': null,
                    'signalePar': 'Alice A',
                  }
                ],
              });

      final result = await service.signalements();

      expect(result.signalements.single.contenuDisponible, isFalse);
    });

    test('masquerMessage envoie la note de modération', () async {
      when(() => api.put<void>('/admin/moderation/messages/m1/hide',
          data: any(named: 'data'))).thenAnswer((_) async {});

      await service.masquerMessage('m1', 'Insultes répétées');

      final envoye = verify(() => api.put<void>(
                  '/admin/moderation/messages/m1/hide',
                  data: captureAny(named: 'data')))
              .captured
              .single as Map<String, dynamic>;
      // Obligatoire côté serveur : un envoi sans note repartirait en 400
      expect(envoye['moderationNote'], 'Insultes répétées');
    });
  });
  group('mots interdits', () {
    const motJson = {
      'id': 'w1',
      'mot': 'spam',
      'createdAt': '2026-06-01T10:00:00Z',
    };

    test('motsInterdits parse la liste', () async {
      when(() => api.get<List<dynamic>>('/admin/moderation/mots-interdits'))
          .thenAnswer((_) async => [motJson]);

      final result = await service.motsInterdits();

      expect(result.single.mot, 'spam');
    });

    test('ajouterMotInterdit poste le mot saisi', () async {
      when(() => api.post<Map<String, dynamic>>(
          '/admin/moderation/mots-interdits',
          data: any(named: 'data'))).thenAnswer((_) async => motJson);

      await service.ajouterMotInterdit('SPAM');

      final envoye = verify(() => api.post<Map<String, dynamic>>(
                  '/admin/moderation/mots-interdits',
                  data: captureAny(named: 'data')))
              .captured
              .single as Map<String, dynamic>;
      // La normalisation en minuscules est faite par le serveur, pas ici
      expect(envoye['mot'], 'SPAM');
    });

    test("supprimerMotInterdit appelle DELETE sur l'identifiant", () async {
      when(() => api.delete<void>('/admin/moderation/mots-interdits/w1'))
          .thenAnswer((_) async {});

      await service.supprimerMotInterdit('w1');

      verify(() => api.delete<void>('/admin/moderation/mots-interdits/w1'))
          .called(1);
    });
  });
  group('modération des annonces', () {
    const logementJson = {
      'id': 'l1',
      'ownerId': 'o1',
      'adresse': '1 rue de la Paix',
      'ville': 'Paris',
      'codePostal': '75001',
      'type': 'STUDIO',
      'surface': 25.0,
      'nbPieces': 1,
      'loyer': 700.0,
      'charges': 0,
      'statut': 'SUSPENDU',
      'isMeuble': true,
      'moderationNote': 'Photos trompeuses',
    };

    test('logements parse la page et le motif de suspension', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/logements',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [logementJson],
                'totalElements': 4,
                'hasNext': false,
              });

      final result = await service.logements();

      expect(result.total, 4);
      expect(result.logements.single.moderationNote, 'Photos trompeuses');
    });

    test("sans filtre, aucun statut n'est envoyé", () async {
      when(() => api.get<Map<String, dynamic>>('/admin/logements',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {'content': []});

      await service.logements();

      final envoye = verify(() => api.get<Map<String, dynamic>>(
                  '/admin/logements',
                  queryParameters: captureAny(named: 'queryParameters')))
              .captured
              .single as Map<String, dynamic>;
      expect(envoye.containsKey('statut'), isFalse);
    });

    test('suspendreLogement envoie le motif', () async {
      when(() => api.put<Map<String, dynamic>>(
          '/admin/logements/l1/suspendre',
          data: any(named: 'data'))).thenAnswer((_) async => logementJson);

      await service.suspendreLogement('l1', 'Photos trompeuses');

      final envoye = verify(() => api.put<Map<String, dynamic>>(
                  '/admin/logements/l1/suspendre',
                  data: captureAny(named: 'data')))
              .captured
              .single as Map<String, dynamic>;
      // Obligatoire côté serveur : il part au propriétaire
      expect(envoye['motif'], 'Photos trompeuses');
    });

    test('republierLogement appelle la bonne route', () async {
      when(() => api.put<Map<String, dynamic>>(
              '/admin/logements/l1/republier'))
          .thenAnswer((_) async => logementJson);

      await service.republierLogement('l1');

      verify(() => api.put<Map<String, dynamic>>(
          '/admin/logements/l1/republier')).called(1);
    });
  });
  group('annonces signalées (APP-121)', () {
    test('parse le contexte joint par le backend', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/moderation/logements',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [
                  {
                    'id': 'r1',
                    'logementId': 'l1',
                    'motif': 'Annonce frauduleuse',
                    'createdAt': '2026-06-01T10:00:00Z',
                    'logementLibelle': 'STUDIO · Paris',
                    'proprietaire': 'Bob B',
                    'signalePar': 'Alice A',
                  }
                ],
                'totalElements': 2,
                'hasNext': false,
              });

      final result = await service.annoncesSignalees();

      expect(result.total, 2);
      final r = result.signalements.single;
      expect(r.logementLibelle, 'STUDIO · Paris');
      expect(r.signalePar, 'Alice A');
      expect(r.annonceDisponible, isTrue);
    });

    test('tolère une annonce disparue', () async {
      when(() => api.get<Map<String, dynamic>>('/admin/moderation/logements',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'content': [
                  {
                    'id': 'r1',
                    'logementId': 'l1',
                    'motif': 'Motif',
                    'createdAt': '2026-06-01T10:00:00Z',
                    'logementLibelle': null,
                  }
                ],
              });

      final result = await service.annoncesSignalees();

      expect(result.signalements.single.annonceDisponible, isFalse);
    });
  });
}
