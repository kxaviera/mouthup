enum ModerationCategory {
  none,
  sexual,
}

class ModerationResult {
  const ModerationResult({
    required this.allowed,
    this.category = ModerationCategory.none,
    this.userMessage = '',
  });

  const ModerationResult.allowed() : this(allowed: true);

  final bool allowed;
  final ModerationCategory category;
  final String userMessage;

  static ModerationResult blocked(String userMessage) {
    return ModerationResult(allowed: false, category: ModerationCategory.sexual, userMessage: userMessage);
  }
}

/// Blocks pornographic / sexual content only. Everything else is allowed.
class ContentModerator {
  static Future<ModerationResult> check(String raw) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _localCheck(raw);
  }

  static ModerationResult _localCheck(String raw) {
    final text = raw.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return const ModerationResult.allowed();

    for (final pattern in _sexualPatterns) {
      if (pattern.hasMatch(text)) {
        return ModerationResult.blocked('Pornographic or sexual content is not allowed.');
      }
    }
    return const ModerationResult.allowed();
  }
}

final _sexualPatterns = [
  RegExp(r'\b(porn|porno|pornography|xxx|nsfw|hentai|nude pic|nudes|send nudes|dick pic|sex tape)\b'),
  RegExp(r'\b(naked photo|naked pic|onlyfans leak|explicit video)\b'),
  RegExp(r'\b(child porn|cp link|underage sex)\b'),
];
