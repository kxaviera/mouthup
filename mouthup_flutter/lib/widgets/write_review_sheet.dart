import 'package:flutter/material.dart';
import '../models/review_request.dart';
import '../theme/app_theme.dart';

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.profileUsername,
    required this.postTitle,
    required this.onSubmit,
  });

  final String profileUsername;
  final String postTitle;
  final Future<String?> Function(int rating, String text) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String profileUsername,
    required String postTitle,
    required Future<String?> Function(int rating, String text) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: WriteReviewSheet(
          profileUsername: profileUsername,
          postTitle: postTitle,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  int _rating = 0;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final error = await widget.onSubmit(_rating, _controller.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review posted on ${widget.profileUsername}\'s profile')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Leave a review', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'For ${widget.profileUsername} · ${widget.postTitle}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? const Color(0xFFFFC107) : AppColors.textDim,
                    size: 32,
                  ),
                );
              }),
            ),
            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'How was the deal? Be honest and helpful.',
                hintStyle: const TextStyle(color: AppColors.textDim),
                filled: true,
                fillColor: AppColors.bgElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Text('Post review', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewRequestCard extends StatelessWidget {
  const ReviewRequestCard({
    super.key,
    required this.request,
    required this.postTitle,
    required this.canRespond,
    required this.alreadyReviewed,
    this.onLeaveReview,
  });

  final ReviewRequest request;
  final String postTitle;
  final bool canRespond;
  final bool alreadyReviewed;
  final VoidCallback? onLeaveReview;

  @override
  Widget build(BuildContext context) {
    final title = canRespond
        ? '${request.requester} requested your review'
        : 'You requested a review from ${request.reviewer}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                request.completed ? Icons.check_circle_outline : Icons.rate_review_outlined,
                size: 18,
                color: request.completed ? const Color(0xFF7DCE7D) : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      postTitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canRespond && !request.completed && !alreadyReviewed && onLeaveReview != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLeaveReview,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Leave review', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ] else if (request.completed || alreadyReviewed) ...[
            const SizedBox(height: 8),
            Text(
              alreadyReviewed || request.completed ? 'Review submitted' : 'Waiting for review',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ] else if (!canRespond && !request.completed) ...[
            const SizedBox(height: 8),
            const Text('Waiting for their review', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
