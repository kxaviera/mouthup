import '../constants/demo_account.dart';
import '../models/post.dart';
import '../models/profile_review.dart';
import '../models/social_profile.dart';

List<MouthUpPost> uiPreviewPosts() {
  final now = DateTime.now();
  return [
    MouthUpPost(
      id: 'preview-1',
      title: 'iPhone 13 Pro — 128GB',
      author: 'NightWalker42',
      content: 'Excellent condition, battery 89%. Includes box and charger. #sale #electronics',
      createdAt: now.subtract(const Duration(minutes: 18)),
      listingType: 'SALE',
      listingStatus: 'OPEN',
      price: 42000,
      location: 'Andheri West, Mumbai',
      authorAccountType: 'SELLER',
      authorCity: 'Mumbai',
      viewCount: 124,
      likeCount: 8,
      commentCount: 3,
      imageUrls: const ['https://picsum.photos/seed/iphone13/800/600'],
    ),
    MouthUpPost(
      id: 'preview-2',
      title: '2BHK flat for rent',
      author: 'HomeFinder99',
      content: 'Fully furnished, near metro. Family preferred. #rent #mumbai',
      createdAt: now.subtract(const Duration(hours: 2)),
      listingType: 'RENT',
      listingStatus: 'OPEN',
      price: 28000,
      rentPeriod: 'MONTH',
      location: 'Powai, Mumbai',
      authorAccountType: 'BOTH',
      authorCity: 'Mumbai',
      viewCount: 89,
      likeCount: 5,
      commentCount: 7,
      imageUrls: const ['https://picsum.photos/seed/flat2bhk/800/600'],
    ),
    MouthUpPost(
      id: 'preview-3',
      title: 'AC repair & service',
      author: 'CoolFixPro',
      content: 'Split AC installation, gas refill, general service. Same-day visits. #service #ac',
      createdAt: now.subtract(const Duration(hours: 5)),
      listingType: 'SERVICE',
      listingStatus: 'OPEN',
      price: 499,
      location: 'Bandra, Mumbai',
      authorAccountType: 'SERVICE_PROVIDER',
      authorProfession: 'AC_REPAIR',
      authorCity: 'Mumbai',
      viewCount: 56,
      likeCount: 12,
      commentCount: 4,
      imageUrls: const ['https://picsum.photos/seed/acrepair/800/600'],
    ),
    MouthUpPost(
      id: 'preview-4',
      title: 'Office chair — swap for study table',
      author: DemoAccount.username,
      content: 'Ergonomic chair, good condition. Want a sturdy study table instead. #swap',
      createdAt: now.subtract(const Duration(hours: 8)),
      listingType: 'SWAP',
      listingStatus: 'OPEN',
      swapFor: 'Study table (wooden preferred)',
      location: 'Malad, Mumbai',
      authorAccountType: 'BOTH',
      authorCity: 'Mumbai',
      viewCount: 34,
      likeCount: 2,
      commentCount: 1,
      imageUrls: const ['https://picsum.photos/seed/officechair/800/600'],
    ),
    MouthUpPost(
      id: 'preview-5',
      title: 'Kids books bundle (free)',
      author: 'BookLover21',
      content: '20 story books ages 5–10. Pick up only. #giveaway #books',
      createdAt: now.subtract(const Duration(days: 1)),
      listingType: 'GIVEAWAY',
      listingStatus: 'OPEN',
      location: 'Thane',
      authorAccountType: 'SELLER',
      authorCity: 'Thane',
      viewCount: 201,
      likeCount: 24,
      commentCount: 11,
      imageUrls: const ['https://picsum.photos/seed/kidsbooks/800/600'],
    ),
    MouthUpPost(
      id: 'preview-6',
      title: 'Need plumber — kitchen leak',
      author: 'QuickHelp',
      content: 'Urgent leak under sink. Available today/tomorrow. #service_request',
      createdAt: now.subtract(const Duration(hours: 3)),
      listingType: 'SERVICE_REQUEST',
      listingStatus: 'OPEN',
      location: 'Goregaon, Mumbai',
      authorAccountType: 'BUYER',
      authorCity: 'Mumbai',
      viewCount: 41,
      likeCount: 3,
      commentCount: 6,
    ),
    MouthUpPost(
      id: 'preview-7',
      title: 'MacBook Air M1 — lightly used',
      author: 'TechDealsMumbai',
      content: '256GB, perfect for students. Original bill included. #sale #laptop',
      createdAt: now.subtract(const Duration(hours: 6)),
      listingType: 'SALE',
      listingStatus: 'OPEN',
      price: 52000,
      location: 'Colaba, Mumbai',
      authorAccountType: 'SELLER',
      authorCity: 'Mumbai',
      viewCount: 178,
      likeCount: 19,
      commentCount: 8,
      imageUrls: const ['https://picsum.photos/seed/macbookm1/800/600'],
    ),
    MouthUpPost(
      id: 'preview-8',
      title: 'Home chef — party catering',
      author: 'ChefPriya',
      content: 'North Indian & continental. 20–100 guests. Tasting available. #service #food',
      createdAt: now.subtract(const Duration(hours: 10)),
      listingType: 'SERVICE',
      listingStatus: 'OPEN',
      price: 1500,
      location: 'Juhu, Mumbai',
      authorAccountType: 'SERVICE_PROVIDER',
      authorProfession: 'CHEF',
      authorCity: 'Mumbai',
      viewCount: 92,
      likeCount: 31,
      commentCount: 5,
      imageUrls: const ['https://picsum.photos/seed/catering/800/600'],
    ),
  ];
}

List<ProfileReview> _reviewsFor(String username) {
  final now = DateTime.now();
  switch (username) {
    case 'CoolFixPro':
      return [
        ProfileReview(
          id: 'r1',
          author: 'MumbaiHome22',
          rating: 5,
          text: 'Fixed my AC same day. Professional and fair pricing.',
          createdAt: now.subtract(const Duration(days: 3)),
          authorAvatarUrl: avatarUrlForUser('MumbaiHome22'),
          postId: 'preview-3',
          postTitle: 'AC repair & service',
        ),
        ProfileReview(
          id: 'r2',
          author: 'RentEasy',
          rating: 5,
          text: 'Reliable service provider — already booked twice.',
          createdAt: now.subtract(const Duration(days: 12)),
          authorAvatarUrl: avatarUrlForUser('RentEasy'),
          postId: 'preview-3',
          postTitle: 'AC repair & service',
        ),
      ];
    case DemoAccount.username:
      return [
        ProfileReview(
          id: 'r3',
          author: 'SwapKing',
          rating: 4,
          text: 'Smooth swap deal. Item exactly as described.',
          createdAt: now.subtract(const Duration(days: 5)),
          authorAvatarUrl: avatarUrlForUser('SwapKing'),
          postId: 'preview-4',
          postTitle: 'Office chair — swap for study table',
        ),
      ];
    case 'ChefPriya':
      return [
        ProfileReview(
          id: 'r4',
          author: 'PartyHost99',
          rating: 5,
          text: 'Amazing food for our house party. Highly recommend!',
          createdAt: now.subtract(const Duration(days: 2)),
          authorAvatarUrl: avatarUrlForUser('PartyHost99'),
          postId: 'preview-8',
          postTitle: 'Home chef — party catering',
        ),
        ProfileReview(
          id: 'r5',
          author: 'WeddingPlanner',
          rating: 5,
          text: 'On time, great presentation, guests loved it.',
          createdAt: now.subtract(const Duration(days: 8)),
          authorAvatarUrl: avatarUrlForUser('WeddingPlanner'),
          postId: 'preview-8',
          postTitle: 'Home chef — party catering',
        ),
      ];
    default:
      return [];
  }
}

Map<String, SocialProfile> uiPreviewProfiles() {
  final profiles = <String, SocialProfile>{
    DemoAccount.username: SocialProfile(
      username: DemoAccount.username,
      screenName: 'Cool Breeze',
      avatarUrl: avatarUrlForUser(DemoAccount.username),
      bio: 'Buy & sell locally in Mumbai. Open to swaps and good deals 🤝',
      city: 'Mumbai',
      accountType: 'BOTH',
      verified: true,
      followerCount: 128,
      followingCount: 54,
      profileLikes: 45,
      profileDislikes: 2,
      reviews: _reviewsFor(DemoAccount.username),
    ),
    'CoolFixPro': SocialProfile(
      username: 'CoolFixPro',
      avatarUrl: avatarUrlForUser('CoolFixPro'),
      bio: 'Certified AC technician · Same-day service across Mumbai',
      city: 'Mumbai',
      accountType: 'SERVICE_PROVIDER',
      profession: 'AC_REPAIR',
      verified: true,
      followerCount: 342,
      followingCount: 89,
      profileLikes: 89,
      profileDislikes: 3,
      reviews: _reviewsFor('CoolFixPro'),
      mutualCount: 3,
    ),
    'ChefPriya': SocialProfile(
      username: 'ChefPriya',
      avatarUrl: avatarUrlForUser('ChefPriya'),
      bio: 'Home chef · Parties, events & weekly meal prep',
      city: 'Mumbai',
      accountType: 'SERVICE_PROVIDER',
      profession: 'CHEF',
      verified: true,
      followerCount: 891,
      followingCount: 210,
      profileLikes: 156,
      profileDislikes: 4,
      reviews: _reviewsFor('ChefPriya'),
      mutualCount: 5,
    ),
    'NightWalker42': SocialProfile(
      username: 'NightWalker42',
      avatarUrl: avatarUrlForUser('NightWalker42'),
      bio: 'Gadgets & electronics · Andheri',
      city: 'Mumbai',
      accountType: 'SELLER',
      followerCount: 67,
      followingCount: 42,
      mutualCount: 1,
    ),
    'HomeFinder99': SocialProfile(
      username: 'HomeFinder99',
      avatarUrl: avatarUrlForUser('HomeFinder99'),
      bio: 'Real estate listings · Rent & sale in Powai area',
      city: 'Mumbai',
      accountType: 'BOTH',
      verified: true,
      followerCount: 1204,
      followingCount: 156,
      mutualCount: 2,
    ),
    'TechDealsMumbai': SocialProfile(
      username: 'TechDealsMumbai',
      avatarUrl: avatarUrlForUser('TechDealsMumbai'),
      bio: 'Refurbished laptops & phones · Colaba pickup',
      city: 'Mumbai',
      accountType: 'SELLER',
      followerCount: 445,
      followingCount: 98,
      mutualCount: 4,
    ),
    'BookLover21': SocialProfile(
      username: 'BookLover21',
      avatarUrl: avatarUrlForUser('BookLover21'),
      bio: 'Sharing books & hosting giveaways 📚',
      city: 'Thane',
      accountType: 'SELLER',
      followerCount: 89,
      followingCount: 120,
    ),
    'QuickHelp': SocialProfile(
      username: 'QuickHelp',
      avatarUrl: avatarUrlForUser('QuickHelp'),
      bio: 'Looking for reliable local services',
      city: 'Mumbai',
      accountType: 'BUYER',
      followerCount: 23,
      followingCount: 67,
    ),
  };

  for (final post in uiPreviewPosts()) {
    profiles.putIfAbsent(
      post.author,
      () => SocialProfile(
        username: post.author,
        avatarUrl: avatarUrlForUser(post.author),
        city: post.authorCity,
        accountType: post.authorAccountType,
        profession: post.authorProfession,
        reviews: _reviewsFor(post.author),
      ),
    );
  }
  return profiles;
}

List<SocialProfile> uiPreviewSuggestions() {
  return [
    uiPreviewProfiles()['CoolFixPro']!,
    uiPreviewProfiles()['ChefPriya']!,
    uiPreviewProfiles()['TechDealsMumbai']!,
    uiPreviewProfiles()['HomeFinder99']!,
  ];
}

List<String> uiPreviewFollowing() => ['CoolFixPro', 'ChefPriya', 'HomeFinder99', 'NightWalker42'];

List<String> uiPreviewFollowers() => ['SwapKing', 'MumbaiHome22', 'RentEasy', 'PartyHost99', 'QuickHelp', 'TechDealsMumbai', 'BookLover21'];
