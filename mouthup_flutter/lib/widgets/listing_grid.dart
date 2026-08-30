import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class ListingGrid extends StatelessWidget {
  const ListingGrid({super.key, required this.posts});

  final List<MouthUpPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No listings yet', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final post = posts[i];
        final image = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;

        return GestureDetector(
          onTap: () => context.push('/post/${post.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(post))
              else
                _placeholder(post),
              if (post.priceLabel != null)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.priceLabel!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (post.imageUrls.length > 1)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.collections, color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(MouthUpPost post) {
    return Container(
      color: AppColors.bgElevated,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        post.title ?? post.content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}
