class ProfessionOption {
  const ProfessionOption({
    required this.apiValue,
    required this.label,
    required this.emoji,
  });

  final String apiValue;
  final String label;
  final String emoji;
}

const professionOptions = [
  ProfessionOption(apiValue: 'PLUMBER', label: 'Plumber', emoji: '🔧'),
  ProfessionOption(apiValue: 'ELECTRICIAN', label: 'Electrician', emoji: '⚡'),
  ProfessionOption(apiValue: 'CHEF', label: 'Chef / Cook', emoji: '👨‍🍳'),
  ProfessionOption(apiValue: 'PAINTER', label: 'Painter', emoji: '🎨'),
  ProfessionOption(apiValue: 'CARPENTER', label: 'Carpenter', emoji: '🪚'),
  ProfessionOption(apiValue: 'AC_REPAIR', label: 'AC repair', emoji: '❄️'),
  ProfessionOption(apiValue: 'CLEANER', label: 'Cleaner', emoji: '🧹'),
  ProfessionOption(apiValue: 'DRIVER', label: 'Driver', emoji: '🚗'),
  ProfessionOption(apiValue: 'TUTOR', label: 'Tutor', emoji: '📚'),
  ProfessionOption(apiValue: 'MECHANIC', label: 'Mechanic', emoji: '🔩'),
  ProfessionOption(apiValue: 'GARDENER', label: 'Gardener', emoji: '🌿'),
  ProfessionOption(apiValue: 'BEAUTICIAN', label: 'Beautician', emoji: '💇'),
  ProfessionOption(apiValue: 'PHOTOGRAPHER', label: 'Photographer', emoji: '📷'),
  ProfessionOption(apiValue: 'OTHER', label: 'Other', emoji: '✨'),
];

ProfessionOption? professionFromApi(String? value) {
  if (value == null) return null;
  for (final opt in professionOptions) {
    if (opt.apiValue == value.toUpperCase()) return opt;
  }
  return null;
}
