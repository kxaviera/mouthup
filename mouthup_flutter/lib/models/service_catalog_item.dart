class ServiceCatalogItem {
  ServiceCatalogItem({
    required this.id,
    required this.profession,
    required this.title,
    this.description,
    required this.pricingType,
    this.price,
    this.currency = 'INR',
    this.metadata = const {},
    this.city,
    this.active = true,
    this.providerUsername,
    this.providerScreenName,
    this.providerCity,
    this.providerProfession,
    this.providerVerified = false,
  });

  final String id;
  final String profession;
  final String title;
  final String? description;
  final String pricingType;
  final double? price;
  final String currency;
  final Map<String, dynamic> metadata;
  final String? city;
  final bool active;
  final String? providerUsername;
  final String? providerScreenName;
  final String? providerCity;
  final String? providerProfession;
  final bool providerVerified;

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'];
    return ServiceCatalogItem(
      id: json['id'] as String? ?? '',
      profession: json['profession'] as String? ?? 'OTHER',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      pricingType: json['pricingType'] as String? ?? 'ON_CHAT',
      price: json['price'] == null ? null : (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      metadata: meta is Map ? Map<String, dynamic>.from(meta) : const {},
      city: json['city'] as String?,
      active: json['active'] as bool? ?? true,
      providerUsername: json['providerUsername'] as String?,
      providerScreenName: json['providerScreenName'] as String?,
      providerCity: json['providerCity'] as String?,
      providerProfession: json['providerProfession'] as String?,
      providerVerified: json['providerVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'profession': profession,
        'title': title,
        if (description != null && description!.isNotEmpty) 'description': description,
        'pricingType': pricingType,
        if (price != null) 'price': price,
        'currency': currency,
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (city != null && city!.isNotEmpty) 'city': city,
      };
}
