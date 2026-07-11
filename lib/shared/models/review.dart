import 'enums.dart';

/// Miroir du ReviewResponse backend.
class Review {
  final String id;
  final String authorId;
  final ReviewTargetType targetType;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.authorId,
    required this.targetType,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      targetType: ReviewTargetType.fromJson(json['targetType'] as String),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
