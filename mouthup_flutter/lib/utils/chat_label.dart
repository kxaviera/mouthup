import '../models/post.dart';
import 'profile_labels.dart';

/// Short chat button label for post cards.
String chatShortLabelForPost(MouthUpPost post) => 'Chat';

/// Contextual tip shown when messaging from a listing post.
String? dmTipForPost(MouthUpPost? post) {
  if (post == null || !post.isListing) return null;

  if (post.listingType == 'SERVICE') {
    final profession = professionLabel(post.authorProfession);
    if (profession != null) {
      return 'Tip: Describe your issue, ask about availability, and confirm the price before booking a $profession.';
    }
    return 'Tip: Explain what you need, ask about timing, and agree on the service charge upfront.';
  }

  switch (post.listingType) {
    case 'SALE':
      return 'Tip: Ask about item condition, if the price is negotiable, and a safe meet-up spot.';
    case 'RENT':
      return 'Tip: Confirm rent period, deposit, furnishing, and when you can visit the property.';
    case 'SWAP':
      return 'Tip: Share photos of your item and be clear about what you want in exchange.';
    case 'GIVEAWAY':
      return 'Tip: Mention when you can pick up and confirm the item is still available.';
    case 'SERVICE_REQUEST':
      return 'Tip: Give full details of the job, your location, and how soon you need help.';
    default:
      return 'Tip: Be clear, polite, and agree on details before meeting in person.';
  }
}
