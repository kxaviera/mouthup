/// YouTube URL helpers for feed video cards.
String? youtubeVideoId(String url) {
  final patterns = [
    RegExp(r'youtube\.com/watch\?v=([\w-]{11})', caseSensitive: false),
    RegExp(r'youtu\.be/([\w-]{11})', caseSensitive: false),
    RegExp(r'youtube\.com/embed/([\w-]{11})', caseSensitive: false),
    RegExp(r'img\.youtube\.com/vi/([\w-]{11})/', caseSensitive: false),
  ];
  for (final re in patterns) {
    final m = re.firstMatch(url);
    if (m != null) return m.group(1);
  }
  return null;
}

String youtubeThumbnail(String videoId) => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

String youtubeWatchUrl(String videoId) => 'https://www.youtube.com/watch?v=$videoId';

bool isYoutubeUrl(String url) => youtubeVideoId(url) != null;

bool isYoutubeThumbnailUrl(String url) => url.contains('img.youtube.com/vi/');
