class MouthUpPost {
  MouthUpPost({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.userSaved = false,
    this.imageUrls = const [],
    this.videoUrls = const [],
  });

  final String id;
  final String author;
  final String content;
  final DateTime createdAt;
  final bool userSaved;
  final List<String> imageUrls;
  final List<String> videoUrls;

  List<String> get hashtags {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(content).map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }

  MouthUpPost copyWith({bool? userSaved, String? content, List<String>? imageUrls, List<String>? videoUrls}) {
    return MouthUpPost(
      id: id,
      author: author,
      content: content ?? this.content,
      createdAt: createdAt,
      userSaved: userSaved ?? this.userSaved,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
    );
  }

  factory MouthUpPost.fromJson(Map<String, dynamic> json) => MouthUpPost(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Anonymous',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        userSaved: json['userSaved'] as bool? ?? false,
        imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
        videoUrls: List<String>.from(json['videoUrls'] as List? ?? const []),
      );
}

List<MouthUpPost> mockPosts() {
  return [
    MouthUpPost(
      id: '1',
      author: 'NightWalker',
      content: 'Feeling really low after work today... anyone else? #work #mentalhealth',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    MouthUpPost(
      id: '2',
      author: 'StyleQueen',
      content: 'Party tonight! 🎉 Which look should I go with? #party #fashion',
      createdAt: DateTime.now().subtract(const Duration(minutes: 34)),
      imageUrls: const [
        'https://picsum.photos/seed/outfit1/400/500',
        'https://picsum.photos/seed/outfit2/400/500',
      ],
    ),
    MouthUpPost(
      id: '3',
      author: 'CalmRiver',
      content: 'Should I take the new job offer? 30% raise but I have to relocate... #career #life',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    MouthUpPost(
      id: '4',
      author: 'CoolBreeze47',
      content: 'Big exam tomorrow and I cannot sleep 😰 #exams #anxiety',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MouthUpPost(
      id: '5',
      author: 'StarGazer22',
      content: 'Hot take: local elections matter more than national ones. #politics #hotake',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MouthUpPost(
      id: '6',
      author: 'LazyCat',
      content: 'Slow Sunday... nothing interesting happening #bored #sunday',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
