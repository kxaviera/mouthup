import '../constants/account_types.dart';
import '../constants/professions.dart';

String accountTypeLabel(String? apiValue) {
  return accountTypeFromApi(apiValue)?.label ?? 'Member';
}

String? professionLabel(String? apiValue) {
  return professionFromApi(apiValue)?.label;
}

String profileSubtitle({
  String? accountType,
  String? profession,
  String? city,
}) {
  final parts = <String>[];
  final type = accountTypeFromApi(accountType);
  if (type?.id == AccountTypeId.serviceProvider && profession != null) {
    final p = professionLabel(profession);
    if (p != null) parts.add(p);
  } else if (type != null) {
    parts.add(type.label);
  }
  if (city != null && city.isNotEmpty) parts.add(city);
  return parts.isEmpty ? 'Local marketplace member' : parts.join(' · ');
}
