import '../constants/listing_types.dart';
import '../constants/moods.dart';

enum SupportReactionType { hug, strength, same }

SupportReactionType? supportReactionFromApi(String? value) {
  switch (value?.toUpperCase()) {
    case 'HUG':
      return SupportReactionType.hug;
    case 'STRENGTH':
      return SupportReactionType.strength;
    case 'SAME':
      return SupportReactionType.same;
    default:
      return null;
  }
}

String supportReactionToApi(SupportReactionType type) {
  switch (type) {
    case SupportReactionType.hug:
      return 'HUG';
    case SupportReactionType.strength:
      return 'STRENGTH';
    case SupportReactionType.same:
      return 'SAME';
  }
}

class MouthUpPost {
  MouthUpPost({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.title,
    this.authorScreenName,
    this.authorIsVerified = false,
    this.userSaved = false,
    this.userLiked = false,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.mood,
    this.userSupportReaction,
    this.listingType,
    this.listingStatus,
    this.price,
    this.currency = 'INR',
    this.rentPeriod,
    this.swapFor,
    this.location,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.authorProfession,
    this.authorCity,
    this.authorAccountType,
    this.requestedProfession,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  final String id;
  final String? title;
  final String author;
  final String? authorScreenName;
  final bool authorIsVerified;
  final String content;
  final DateTime createdAt;
  final bool userSaved;
  final bool userLiked;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? mood;
  final SupportReactionType? userSupportReaction;
  final String? listingType;
  final String? listingStatus;
  final double? price;
  final String currency;
  final String? rentPeriod;
  final String? swapFor;
  final String? location;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final String? authorProfession;
  final String? authorCity;
  final String? authorAccountType;
  final String? requestedProfession;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  String get displayAuthor {
    final name = authorScreenName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return author;
  }

  ListingTypeOption? get listingTypeOption => listingTypeFromApi(listingType);

  bool get isListing => listingType != null;

  bool get isOpen => listingStatus?.toUpperCase() != 'CLOSED';

  MoodId? get moodId => moodIdFromApi(mood);

  List<String> get hashtags {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(content).map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }

  String? get priceLabel {
    if (price == null) return null;
    if (listingType?.toUpperCase() == 'GIVEAWAY') return 'Free';
    final period = rentPeriodFromApi(rentPeriod);
    final periodLabel = period == null
        ? ''
        : ' / ${rentPeriodOptions.firstWhere((o) => o.id == period).label.toLowerCase()}';
    return '₹${price!.toStringAsFixed(price! == price!.roundToDouble() ? 0 : 2)}$periodLabel';
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'Listing';
    if (trimmed.length <= 48) return trimmed;
    return '${trimmed.substring(0, 48)}…';
  }

  MouthUpPost copyWith({
    bool? userSaved,
    bool? userLiked,
    String? content,
    String? listingStatus,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? mood,
    SupportReactionType? userSupportReaction,
    bool clearSupportReaction = false,
    int? likeCount,
    int? viewCount,
    int? commentCount,
  }) {
    return MouthUpPost(
      id: id,
      title: title,
      author: author,
      authorScreenName: authorScreenName,
      authorIsVerified: authorIsVerified,
      content: content ?? this.content,
      createdAt: createdAt,
      userSaved: userSaved ?? this.userSaved,
      userLiked: userLiked ?? this.userLiked,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      mood: mood ?? this.mood,
      userSupportReaction: clearSupportReaction ? null : (userSupportReaction ?? this.userSupportReaction),
      listingType: listingType,
      listingStatus: listingStatus ?? this.listingStatus,
      price: price,
      currency: currency,
      rentPeriod: rentPeriod,
      swapFor: swapFor,
      location: location,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      authorProfession: authorProfession,
      authorCity: authorCity,
      authorAccountType: authorAccountType,
      requestedProfession: requestedProfession,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
    );
  }

  factory MouthUpPost.fromJson(Map<String, dynamic> json) => MouthUpPost(
        id: json['id'] as String,
        title: json['title'] as String?,
        author: json['author'] as String? ?? 'Unknown',
        authorScreenName: json['authorScreenName'] as String?,
        authorIsVerified: json['authorIsVerified'] as bool? ?? false,
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        userSaved: json['userSaved'] as bool? ?? false,
        userLiked: json['userLiked'] as bool? ?? false,
        imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
        videoUrls: List<String>.from(json['videoUrls'] as List? ?? const []),
        mood: json['mood'] as String?,
        userSupportReaction: supportReactionFromApi(json['userSupportReaction'] as String?),
        listingType: json['listingType'] as String?,
        listingStatus: json['listingStatus'] as String?,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        currency: json['currency'] as String? ?? 'INR',
        rentPeriod: json['rentPeriod'] as String?,
        swapFor: json['swapFor'] as String?,
        location: json['location'] as String?,
        viewCount: json['viewCount'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        authorProfession: json['authorProfession'] as String?,
        authorCity: json['authorCity'] as String?,
        authorAccountType: json['authorAccountType'] as String?,
        requestedProfession: json['requestedProfession'] as String?,
        latitude: json['latitude'] == null ? null : (json['latitude'] as num).toDouble(),
        longitude: json['longitude'] == null ? null : (json['longitude'] as num).toDouble(),
        distanceKm: json['distanceKm'] == null ? null : (json['distanceKm'] as num).toDouble(),
      );
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
