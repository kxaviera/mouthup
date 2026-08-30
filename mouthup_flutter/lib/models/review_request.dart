class ReviewRequest {
  const ReviewRequest({
    required this.id,
    required this.requester,
    required this.reviewer,
    required this.postId,
    required this.createdAt,
    this.completed = false,
  });

  final String id;
  /// Profile that wants to be reviewed.
  final String requester;
  /// User who should write the review.
  final String reviewer;
  final String postId;
  final DateTime createdAt;
  final bool completed;

  ReviewRequest copyWith({bool? completed}) => ReviewRequest(
        id: id,
        requester: requester,
        reviewer: reviewer,
        postId: postId,
        createdAt: createdAt,
        completed: completed ?? this.completed,
      );
}
