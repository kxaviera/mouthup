import 'dart:io';

import 'package:share_plus/share_plus.dart';

Future<XFile?> shareImageFromBytes(List<int> bytes, String path, String? mimeType) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
  return XFile(path, mimeType: mimeType);
}
