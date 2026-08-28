import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/post_text.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

enum _AttachmentKind { image, video }

class _PostAttachment {
  const _PostAttachment({required this.bytes, required this.kind});

  final Uint8List bytes;
  final _AttachmentKind kind;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<_PostAttachment> _attachments = [];
  bool _publishing = false;
  bool _acceptedTerms = false;

  static const _maxAttachments = 4;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  int get _wordCount => countWords(_content.text);

  void _onContentChanged(String value) {
    if (countWords(value) > PostLimits.maxWords) {
      final clamped = clampToWordLimit(value);
      _content.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    if (_attachments.length >= _maxAttachments) return;
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _attachments.add(_PostAttachment(bytes: bytes, kind: _AttachmentKind.image)));
    }
  }

  Future<void> _pickVideo() async {
    if (_attachments.length >= _maxAttachments) return;
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _attachments.add(_PostAttachment(bytes: bytes, kind: _AttachmentKind.video)));
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  Future<void> _publish() async {
    if (_publishing) return;
    final app = context.read<AppState>();
    final text = clampToWordLimit(_content.text.trim());

    if (!_acceptedTerms) return;
    if (text.isEmpty && _attachments.isEmpty) return;

    setState(() => _publishing = true);

    final post = MouthUpPost(
      id: 'pending',
      author: app.nickname,
      content: text.isEmpty ? 'Shared media' : text,
      createdAt: DateTime.now(),
    );

    final images = _attachments.where((a) => a.kind == _AttachmentKind.image).map((a) => a.bytes).toList();
    final videos = _attachments.where((a) => a.kind == _AttachmentKind.video).map((a) => a.bytes).toList();

    final blocked = await app.addPost(post, images: images, videos: videos);
    if (!mounted) return;
    setState(() => _publishing = false);

    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked.userMessage), backgroundColor: AppColors.danger.withValues(alpha: 0.9)),
      );
      return;
    }

    if (mounted) popOrGo(context, '/home');
  }

  bool get _canPublish => _acceptedTerms && (_content.text.trim().isNotEmpty || _attachments.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final atWordLimit = _wordCount >= PostLimits.maxWords;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGo(context, '/home');
      },
      child: ScreenWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => popOrGo(context, '/home'), icon: const Icon(Icons.close, color: AppColors.textMuted)),
                const Expanded(
                  child: Text('New Post', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                ),
                TextButton(onPressed: _canPublish && !_publishing ? _publish : null, child: const Text('Post', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max ${PostLimits.maxWords} words · photos & videos welcome. No pornographic content.',
                      style: TextStyle(color: atWordLimit ? AppColors.danger : AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _content,
                      onChanged: _onContentChanged,
                      maxLines: 6,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(hintText: 'What\'s on your mind? Use #hashtags'),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_wordCount / ${PostLimits.maxWords} words',
                        style: TextStyle(
                          color: atWordLimit ? AppColors.danger : AppColors.textDim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _mediaAttachmentSection(),
                  ],
                ),
              ),
            ),
            _termsAcceptance(),
            const SizedBox(height: 12),
            PrimaryButton(title: _publishing ? 'Posting...' : 'Publish post', onPressed: _canPublish && !_publishing ? _publish : null),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _termsAcceptance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            activeColor: AppColors.primary,
            checkColor: AppColors.onPrimary,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('I accept the ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => context.push('/profile/terms'),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mediaAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photos & videos', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_attachments.length}/$_maxAttachments', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...List.generate(_attachments.length, (i) {
                final item = _attachments[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.kind == _AttachmentKind.image
                            ? Image.memory(item.bytes, width: 96, height: 96, fit: BoxFit.cover)
                            : Container(
                                width: 96,
                                height: 96,
                                color: AppColors.bgElevated,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_outlined, color: AppColors.primary, size: 28),
                                    SizedBox(height: 4),
                                    Text('Video', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_attachments.length < _maxAttachments) ...[
                _addMediaButton(icon: Icons.add_a_photo_outlined, label: 'Photo', onTap: _pickImage),
                const SizedBox(width: 10),
                _addMediaButton(icon: Icons.videocam_outlined, label: 'Video', onTap: _pickVideo),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _addMediaButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
