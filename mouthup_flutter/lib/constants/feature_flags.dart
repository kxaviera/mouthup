import 'account_types.dart';
import 'listing_types.dart';

/// Flip to `true` when launching the service-provider marketplace.
const servicesMarketplaceEnabled = false;

/// Account types shown during onboarding (service provider hidden until launch).
List<AccountTypeOption> get visibleAccountTypeOptions {
  if (!servicesMarketplaceEnabled) {
    return const [
      AccountTypeOption(
        id: AccountTypeId.both,
        apiValue: 'BOTH',
        label: 'Marketplace member',
        subtitle: 'Browse, list, buy & sell locally',
        icon: '🤝',
      ),
    ];
  }
  return accountTypeOptions.where((o) => o.id != AccountTypeId.serviceProvider).toList();
}

/// Marketplace listing types only (no service provider posts).
List<ListingTypeOption> get activeListingTypes => marketplaceListingTypes;
