import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/review_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ReviewService service;

  const reviewJson = {
    'id': 'r1',
    'authorId': 'u1',
    'targetType': 'USER',
    'rating': 5,
    'comment': 'Super échange',
    'createdAt': '2026-07-18T10:00:00Z',
  };

  setUp(() {
    api = MockApiClient();
    service = ReviewService(apiClient: api);
  });

  test('createReview envoie le bon corps et parse la réponse', () async {
    when(() => api.post<Map<String, dynamic>>('/reviews',
        data: any(named: 'data'))).thenAnswer((_) async => reviewJson);

    final review = await service.createReview(
      accordId: 'a1',
      targetType: ReviewTargetType.USER,
      targetUserId: 'u2',
      rating: 5,
      comment: 'Super échange',
    );

    expect(review.rating, 5);
    final sent = verify(() => api.post<Map<String, dynamic>>('/reviews',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(sent['accordId'], 'a1');
    expect(sent['targetType'], 'USER');
    expect(sent['targetUserId'], 'u2');
    expect(sent['rating'], 5);
  });

  test('getReviewsForUser extrait content', () async {
    when(() => api.get<Map<String, dynamic>>('/reviews/user/u2'))
        .thenAnswer((_) async => {
              'content': [reviewJson]
            });

    final result = await service.getReviewsForUser('u2');

    expect(result, hasLength(1));
    expect(result.first.targetType, ReviewTargetType.USER);
  });
}
