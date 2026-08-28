/// Post text limits and word helpers.
abstract final class PostLimits {
  static const maxWords = 250;
  static const feedPreviewWords = 50;
}

int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

String truncateToWords(String text, int maxWords) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length <= maxWords) return trimmed;
  return words.take(maxWords).join(' ');
}

bool exceedsWordLimit(String text, [int maxWords = PostLimits.maxWords]) {
  return countWords(text) > maxWords;
}

String clampToWordLimit(String text, [int maxWords = PostLimits.maxWords]) {
  return truncateToWords(text, maxWords);
}

bool shouldShowReadMore(String text, [int previewWords = PostLimits.feedPreviewWords]) {
  return countWords(text) > previewWords;
}
