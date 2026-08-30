class ServiceFormField {
  const ServiceFormField({
    required this.key,
    required this.label,
    this.hint,
    this.multiline = false,
  });

  final String key;
  final String label;
  final String? hint;
  final bool multiline;
}

const serviceFormTemplates = <String, List<ServiceFormField>>{
  'PLUMBER': [
    ServiceFormField(key: 'serviceType', label: 'Service type', hint: 'Leak repair, pipe fitting…'),
    ServiceFormField(key: 'experience', label: 'Experience', hint: 'e.g. 5 years'),
    ServiceFormField(key: 'availability', label: 'Availability', hint: 'Same day, weekends…'),
  ],
  'ELECTRICIAN': [
    ServiceFormField(key: 'serviceType', label: 'Service type', hint: 'Wiring, switchboard…'),
    ServiceFormField(key: 'experience', label: 'Experience'),
    ServiceFormField(key: 'availability', label: 'Availability'),
  ],
  'CHEF': [
    ServiceFormField(key: 'cuisine', label: 'Cuisine', hint: 'North Indian, Continental…'),
    ServiceFormField(key: 'occasion', label: 'Occasion', hint: 'Home party, daily meals…'),
    ServiceFormField(key: 'serves', label: 'Serves up to', hint: 'e.g. 20 people'),
  ],
  'MAID': [
    ServiceFormField(key: 'tasks', label: 'Tasks', hint: 'Cleaning, utensils, laundry…'),
    ServiceFormField(key: 'schedule', label: 'Schedule', hint: 'Daily, alternate days…'),
    ServiceFormField(key: 'liveIn', label: 'Live-in?', hint: 'Yes / No'),
  ],
  'NURSE': [
    ServiceFormField(key: 'careType', label: 'Care type', hint: 'Home nurse, injection…'),
    ServiceFormField(key: 'qualification', label: 'Qualification'),
    ServiceFormField(key: 'shift', label: 'Shift', hint: 'Day / Night / 12 hr'),
  ],
  'AC_REPAIR': [
    ServiceFormField(key: 'brands', label: 'Brands handled'),
    ServiceFormField(key: 'serviceType', label: 'Service type', hint: 'Install, gas refill…'),
    ServiceFormField(key: 'warranty', label: 'Warranty offered'),
  ],
  'CLEANER': [
    ServiceFormField(key: 'propertyType', label: 'Property type', hint: 'Flat, office…'),
    ServiceFormField(key: 'frequency', label: 'Frequency'),
    ServiceFormField(key: 'supplies', label: 'Supplies included?', hint: 'Yes / No'),
  ],
  'TUTOR': [
    ServiceFormField(key: 'subjects', label: 'Subjects'),
    ServiceFormField(key: 'grades', label: 'Grades / levels'),
    ServiceFormField(key: 'mode', label: 'Mode', hint: 'Home / Online'),
  ],
  'BEAUTICIAN': [
    ServiceFormField(key: 'services', label: 'Services', hint: 'Facial, bridal…'),
    ServiceFormField(key: 'location', label: 'Location', hint: 'Salon / Home visit'),
  ],
  'OTHER': [
    ServiceFormField(key: 'details', label: 'Details', hint: 'What you offer', multiline: true),
  ],
};

List<ServiceFormField> formFieldsForProfession(String profession) {
  return serviceFormTemplates[profession.toUpperCase()] ??
      serviceFormTemplates['OTHER']!;
}
