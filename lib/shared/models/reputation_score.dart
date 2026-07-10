/// Miroir du ReputationScoreResponse backend.
class ReputationScore {
  final String userId;
  final double avgRating;
  final int totalReviews;
  final double logementScore;
  final int nbAccords;

  /// Badge calculé côté backend : Nouveau, Fiable, Expert, Ambassadeur
  final String badge;

  const ReputationScore({
    required this.userId,
    required this.avgRating,
    required this.totalReviews,
    required this.logementScore,
    required this.nbAccords,
    required this.badge,
  });

  factory ReputationScore.fromJson(Map<String, dynamic> json) {
    return ReputationScore(
      userId: json['userId'] as String,
      avgRating: (json['avgRating'] as num? ?? 0).toDouble(),
      totalReviews: (json['totalReviews'] as num? ?? 0).toInt(),
      logementScore: (json['logementScore'] as num? ?? 0).toDouble(),
      nbAccords: (json['nbAccords'] as num? ?? 0).toInt(),
      badge: json['badge'] as String? ?? 'Nouveau',
    );
  }
}
