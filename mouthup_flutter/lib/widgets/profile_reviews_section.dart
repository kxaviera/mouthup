import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/profile_review.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class ProfileReviewsSection extends StatelessWidget {
  const ProfileReviewsSection({super.key, required this.reviews});

  final List<ProfileReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No reviews yet — reviews come from inbox deals', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ),
      );
    }

    final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRow(rating: avg.round()),
                  Text('${reviews.length} review${reviews.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        ...reviews.map((r) => _ReviewTile(review: r)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProfileReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: review.author, imageUrl: review.authorAvatarUrl, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                      _StarRow(rating: review.rating, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            if (review.postTitle != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: review.postId != null ? () => context.push('/post/${review.postId}') : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.postTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (review.postId != null)
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textDim),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(review.text, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 14});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < rating ? const Color(0xFFFFC107) : AppColors.textDim,
        );
      }),
    );
  }
}
