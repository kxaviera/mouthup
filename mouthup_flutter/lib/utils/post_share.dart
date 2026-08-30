import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_brand.dart';
import '../config/api_config.dart';
import '../models/post.dart';
import 'post_share_image_stub.dart'
    if (dart.library.io) 'post_share_image_io.dart';

Future<void> sharePost(BuildContext context, MouthUpPost post) async {
  final link = ApiConfig.postShareUrl(post.id);
  final excerpt = _excerpt(post.content);
  final text = '@${post.author} on ${AppBrand.sharePrefix}\n\n$excerpt\n\n$link';
  final origin = _shareOrigin(context);
  final image = kIsWeb ? null : await _firstShareableImage(post.imageUrls);

  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: '${AppBrand.sharePrefix} listing',
      files: image == null ? null : [image],
      sharePositionOrigin: origin,
    ),
  );
}

String _excerpt(String content) {
  if (content.length <= 280) return content;
  return '${content.substring(0, 277)}...';
}

Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<XFile?> _firstShareableImage(List<String> urls) async {
  if (urls.isEmpty) return null;

  try {
    final response = await Dio().get<List<int>>(
      urls.first,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final ext = _imageExt(urls.first, response.headers.value('content-type'));
    final path = '${dir.path}/mouthup_share_${DateTime.now().millisecondsSinceEpoch}.$ext';
    return shareImageFromBytes(bytes, path, response.headers.value('content-type'));
  } catch (_) {
    return null;
  }
}

String _imageExt(String url, String? contentType) {
  if (contentType?.contains('png') == true) return 'png';
  if (contentType?.contains('webp') == true) return 'webp';
  if (contentType?.contains('gif') == true) return 'gif';
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (path.endsWith('.png')) return 'png';
  if (path.endsWith('.webp')) return 'webp';
  if (path.endsWith('.gif')) return 'gif';
  return 'jpg';
}
