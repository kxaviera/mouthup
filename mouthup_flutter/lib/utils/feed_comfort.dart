import '../constants/moods.dart';
import '../models/post.dart';

/// Hashtags that signal uplifting bot / comfort-feed content.
const positiveHashtags = {
  'goodvibes',
  'sports',
  'gaming',
  'food',
  'travel',
  'music',
  'entertainment',
  'bollywood',
  'hollywood',
  'fashion',
  'wellness',
  'inspiration',
  'fun',
  'highlights',
  'recipes',
  'tourism',
  'style',
  'movies',
  'viral',
  'discovery',
  'innovation',
  'tech',
  'health',
  'education',
};

const shieldHashtagMap = {
  'politics': {'politics', 'government', 'election', 'hotake'},
  'news': {'news', 'breaking', 'world'},
  'crime': {'crime', 'law'},
  'negative_moods': <String>{},
};

bool triggersComfortMode(MoodId? mood) {
  if (mood == null) return false;
  return mood == MoodId.low || mood == MoodId.anxious || mood == MoodId.angry;
}

bool isPositivePost(MouthUpPost post) {
  final mood = post.moodId;
  if (mood == MoodId.good || mood == MoodId.excited) return true;
  if (mood == MoodId.low || mood == MoodId.anxious || mood == MoodId.angry) return false;
  if (post.hashtags.any(positiveHashtags.contains)) return true;
  if (post.imageUrls.isNotEmpty || post.videoUrls.isNotEmpty) return true;
  return false;
}

bool isBlockedByShields(MouthUpPost post, Set<String> shields) {
  if (shields.contains('negative_moods')) {
    final mood = post.moodId;
    if (mood == MoodId.low || mood == MoodId.anxious || mood == MoodId.angry) {
      return true;
    }
  }
  for (final shield in shields) {
    if (shield == 'negative_moods') continue;
    final tags = shieldHashtagMap[shield];
    if (tags != null && post.hashtags.any(tags.contains)) return true;
  }
  return false;
}

List<MouthUpPost> applyFeedFilters({
  required List<MouthUpPost> posts,
  required bool comfortMode,
  required Set<String> topicShields,
  String? viewerUsername,
}) {
  final filtered = posts.where((post) {
    if (viewerUsername != null && post.author == viewerUsername) return true;
    if (isBlockedByShields(post, topicShields)) return false;
    if (comfortMode && !isPositivePost(post)) return false;
    return true;
  }).toList();

  filtered.sort((a, b) {
    if (comfortMode) {
      final ap = isPositivePost(a) ? 0 : 1;
      final bp = isPositivePost(b) ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return filtered;
}
