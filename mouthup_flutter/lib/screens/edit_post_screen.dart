import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/post_text.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key, required this.postId});

  final String postId;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _content;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final post = context.read<AppState>().getPost(widget.postId);
    _content = TextEditingController(text: post?.content ?? '');
  }

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

  Future<void> _save() async {
    if (_saving) return;
    final text = clampToWordLimit(_content.text.trim());
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final blocked = await context.read<AppState>().updatePost(widget.postId, text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked.userMessage), backgroundColor: AppColors.danger.withValues(alpha: 0.9)),
      );
      return;
    }
    popOrGo(context, '/post/${widget.postId}');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.isPostAuthor(widget.postId)) {
      return ScreenWrapper(
        child: Center(child: TextButton(onPressed: () => popOrGo(context, '/home'), child: const Text('Back'))),
      );
    }

    final atWordLimit = _wordCount >= PostLimits.maxWords;

    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => popOrGo(context, '/post/${widget.postId}'), icon: const Icon(Icons.close, color: AppColors.textMuted)),
              const Expanded(
                child: Text('Edit post', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
              TextButton(onPressed: _saving ? null : _save, child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _content,
              onChanged: _onContentChanged,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Edit your post...',
                border: InputBorder.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_wordCount / ${PostLimits.maxWords} words',
              style: TextStyle(color: atWordLimit ? AppColors.danger : AppColors.textDim, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(title: _saving ? 'Saving...' : 'Save changes', onPressed: _saving ? null : _save),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
