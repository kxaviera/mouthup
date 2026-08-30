enum AccountTypeId { buyer, seller, both, serviceProvider }

class AccountTypeOption {
  const AccountTypeOption({
    required this.id,
    required this.apiValue,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final AccountTypeId id;
  final String apiValue;
  final String label;
  final String subtitle;
  final String icon;
}

const accountTypeOptions = [
  AccountTypeOption(
    id: AccountTypeId.buyer,
    apiValue: 'BUYER',
    label: 'Buyer',
    subtitle: 'Browse and buy locally',
    icon: '🛒',
  ),
  AccountTypeOption(
    id: AccountTypeId.seller,
    apiValue: 'SELLER',
    label: 'Seller',
    subtitle: 'List items for sale or rent',
    icon: '📦',
  ),
  AccountTypeOption(
    id: AccountTypeId.both,
    apiValue: 'BOTH',
    label: 'Both',
    subtitle: 'Buy and sell in your area',
    icon: '🤝',
  ),
  AccountTypeOption(
    id: AccountTypeId.serviceProvider,
    apiValue: 'SERVICE_PROVIDER',
    label: 'Service provider',
    subtitle: 'Offer your skills locally',
    icon: '🛠️',
  ),
];

AccountTypeOption? accountTypeFromApi(String? value) {
  if (value == null) return null;
  for (final opt in accountTypeOptions) {
    if (opt.apiValue == value.toUpperCase()) return opt;
  }
  return null;
}
