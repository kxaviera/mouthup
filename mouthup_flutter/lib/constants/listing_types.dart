enum ListingTypeId {
  sale,
  rent,
  swap,
  giveaway,
  service,
  serviceRequest,
}

class ListingTypeOption {
  const ListingTypeOption({
    required this.id,
    required this.apiValue,
    required this.label,
    required this.emoji,
  });

  final ListingTypeId id;
  final String apiValue;
  final String label;
  final String emoji;
}

const listingTypeOptions = [
  ListingTypeOption(id: ListingTypeId.sale, apiValue: 'SALE', label: 'For sale', emoji: '🏷️'),
  ListingTypeOption(id: ListingTypeId.rent, apiValue: 'RENT', label: 'For rent', emoji: '🔑'),
  ListingTypeOption(id: ListingTypeId.swap, apiValue: 'SWAP', label: 'Swap', emoji: '🔄'),
  ListingTypeOption(id: ListingTypeId.giveaway, apiValue: 'GIVEAWAY', label: 'Giveaway', emoji: '🎁'),
  ListingTypeOption(id: ListingTypeId.service, apiValue: 'SERVICE', label: 'Service offer', emoji: '🛠️'),
  ListingTypeOption(id: ListingTypeId.serviceRequest, apiValue: 'SERVICE_REQUEST', label: 'Need service', emoji: '📋'),
];

/// Marketplace listing types (no service provider types until launch).
List<ListingTypeOption> get marketplaceListingTypes => listingTypeOptions
    .where((t) => t.id != ListingTypeId.service && t.id != ListingTypeId.serviceRequest)
    .toList();

ListingTypeOption? listingTypeFromApi(String? value) {
  if (value == null) return null;
  for (final opt in listingTypeOptions) {
    if (opt.apiValue == value.toUpperCase()) return opt;
  }
  return null;
}

enum RentPeriodId { day, week, month }

const rentPeriodOptions = [
  (id: RentPeriodId.day, apiValue: 'DAY', label: 'Per day'),
  (id: RentPeriodId.week, apiValue: 'WEEK', label: 'Per week'),
  (id: RentPeriodId.month, apiValue: 'MONTH', label: 'Per month'),
];

String? rentPeriodToApi(RentPeriodId? id) {
  if (id == null) return null;
  return rentPeriodOptions.firstWhere((o) => o.id == id).apiValue;
}

RentPeriodId? rentPeriodFromApi(String? value) {
  if (value == null) return null;
  for (final opt in rentPeriodOptions) {
    if (opt.apiValue == value.toUpperCase()) return opt.id;
  }
  return null;
}
