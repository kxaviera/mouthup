enum UserGender { male, female, other }

extension UserGenderX on UserGender {
  String get label => switch (this) {
        UserGender.male => 'Male',
        UserGender.female => 'Female',
        UserGender.other => 'Other',
      };
}
