import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/enums.dart';
import '../shared/models/review.dart';

/// Service des avis.
class ReviewService {
  final ApiClient _api;

  ReviewService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// POST /reviews — dépose un avis sur un utilisateur OU un logement,
  /// rattaché à un accord terminé.
  Future<Review> createReview({
    required String accordId,
    required ReviewTargetType targetType,
    String? targetUserId,
    String? targetLogementId,
    required int rating,
    String? comment,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/reviews',
      data: {
        'accordId': accordId,
        'targetType': targetType.toJson(),
        'targetUserId': targetUserId,
        'targetLogementId': targetLogementId,
        'rating': rating,
        'comment': comment,
      },
    );
    return Review.fromJson(data);
  }

  /// GET /reviews/user/{userId} — avis reçus par un utilisateur
  /// (Page Spring, on extrait content). Servira aussi à l'écran profil.
  Future<List<Review>> getReviewsForUser(String userId) async {
    final data =
        await _api.get<Map<String, dynamic>>('/reviews/user/$userId');
    return (data['content'] as List? ?? [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
