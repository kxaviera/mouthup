import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

final _hashtagRegex = RegExp(r'#(\w+)');

List<String> extractHashtags(String text) {
  return _hashtagRegex.allMatches(text).map((m) => m.group(1)!.toLowerCase()).toSet().toList();
}

Map<String, int> hashtagCounts(Iterable<String> contents) {
  final counts = <String, int>{};
  for (final content in contents) {
    for (final tag in extractHashtags(content)) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
}

List<String> topTrendingHashtags(Iterable<String> contents, {int limit = 10}) {
  final counts = hashtagCounts(contents);
  final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(limit).map((e) => '#${e.key}').toList();
}

bool postMatchesHashtag(String content, String? hashtag) {
  if (hashtag == null || hashtag.isEmpty) return true;
  final tag = hashtag.startsWith('#') ? hashtag.substring(1).toLowerCase() : hashtag.toLowerCase();
  return extractHashtags(content).contains(tag);
}

Widget buildHashtagText(
  String text, {
  void Function(String hashtag)? onHashtagTap,
  TextStyle? style,
}) {
  final base = style ?? const TextStyle(color: AppColors.text, fontSize: 15, height: 1.45);
  final spans = <InlineSpan>[];
  var start = 0;

  for (final match in _hashtagRegex.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start), style: base));
    }
    final tag = match.group(0)!;
    spans.add(
      TextSpan(
        text: tag,
        style: base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        recognizer: onHashtagTap != null
            ? (TapGestureRecognizer()..onTap = () => onHashtagTap(tag))
            : null,
      ),
    );
    start = match.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: base));
  }

  if (spans.isEmpty) {
    return Text(text, style: base);
  }

  return RichText(text: TextSpan(children: spans));
}
