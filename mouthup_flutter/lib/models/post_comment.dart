class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String author;
  final String text;
  final DateTime createdAt;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorName = author is Map
        ? author['username'] as String? ?? 'Anonymous'
        : author as String? ?? 'Anonymous';
    return PostComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: authorName,
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
