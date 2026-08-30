class ProfileReview {
  const ProfileReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.authorAvatarUrl,
    this.postId,
    this.postTitle,
  });

  final String id;
  final String author;
  final int rating;
  final String text;
  final DateTime createdAt;
  final String? authorAvatarUrl;
  final String? postId;
  final String? postTitle;
}
