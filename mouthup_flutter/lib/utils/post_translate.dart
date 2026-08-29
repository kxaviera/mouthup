import 'package:url_launcher/url_launcher.dart';

/// Opens Google Translate with auto-detect → English for post body text.
Future<bool> openPostTranslation(String content) async {
  final text = _textForTranslation(content);
  if (text.isEmpty) return false;

  final uri = Uri.parse(
    'https://translate.google.com/?sl=auto&tl=en&op=translate&text=${Uri.encodeComponent(text)}',
  );
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _textForTranslation(String content) {
  final lines = content.split('\n');
  final body = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.split(' ').every((w) => w.startsWith('#'))) continue;
    body.add(trimmed);
  }
  return body.join('\n').trim();
}
