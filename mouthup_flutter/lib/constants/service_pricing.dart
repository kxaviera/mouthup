class ServicePricingOption {
  const ServicePricingOption({
    required this.apiValue,
    required this.label,
    required this.needsPrice,
  });

  final String apiValue;
  final String label;
  final bool needsPrice;
}

const servicePricingOptions = [
  ServicePricingOption(apiValue: 'FIXED', label: 'Fixed price', needsPrice: true),
  ServicePricingOption(apiValue: 'FROM', label: 'Starting from', needsPrice: true),
  ServicePricingOption(apiValue: 'HOURLY', label: 'Per hour', needsPrice: true),
  ServicePricingOption(apiValue: 'DAILY', label: 'Per day', needsPrice: true),
  ServicePricingOption(apiValue: 'WEEKLY', label: 'Per week', needsPrice: true),
  ServicePricingOption(apiValue: 'MONTHLY', label: 'Per month', needsPrice: true),
  ServicePricingOption(apiValue: 'ON_CHAT', label: 'Price on chat', needsPrice: false),
];

ServicePricingOption? pricingFromApi(String? value) {
  if (value == null) return null;
  for (final opt in servicePricingOptions) {
    if (opt.apiValue == value.toUpperCase()) return opt;
  }
  return null;
}

String formatServicePrice({
  required String pricingType,
  double? price,
  String currency = 'INR',
}) {
  final opt = pricingFromApi(pricingType);
  if (opt == null || opt.apiValue == 'ON_CHAT') return 'Price on chat';
  if (price == null) return 'Contact for price';

  final symbol = currency == 'INR' ? '₹' : '$currency ';
  final amount = price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);

  return switch (opt.apiValue) {
    'FROM' => 'From $symbol$amount',
    'HOURLY' => '$symbol$amount / hr',
    'DAILY' => '$symbol$amount / day',
    'WEEKLY' => '$symbol$amount / week',
    'MONTHLY' => '$symbol$amount / mo',
    _ => '$symbol$amount',
  };
}
