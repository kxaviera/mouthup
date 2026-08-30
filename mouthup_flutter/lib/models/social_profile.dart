import 'profile_review.dart';

class SocialProfile {
  const SocialProfile({
    required this.username,
    this.screenName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.accountType,
    this.profession,
    this.verified = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.reviews = const [],
    this.mutualCount = 0,
    this.profileLikes = 0,
    this.profileDislikes = 0,
  });

  final String username;
  final String? screenName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? accountType;
  final String? profession;
  final bool verified;
  final int followerCount;
  final int followingCount;
  final List<ProfileReview> reviews;
  final int mutualCount;
  final int profileLikes;
  final int profileDislikes;

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  int get reviewCount => reviews.length;
}

String avatarUrlForUser(String username) => 'https://picsum.photos/seed/${Uri.encodeComponent(username)}/200/200';
