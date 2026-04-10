import '../models/experience_models.dart';

class DemoPatientIdentity {
  const DemoPatientIdentity({
    required this.patientId,
    required this.displayName,
    required this.loginAlias,
    required this.subtitle,
    required this.personaText,
  });

  final String patientId;
  final String displayName;
  final String loginAlias;
  final String subtitle;
  final String personaText;
}

class OfferPracticalInfo {
  const OfferPracticalInfo({
    required this.title,
    required this.categoryLabel,
    required this.priceLabel,
    required this.locationLabel,
    required this.locationShortLabel,
    required this.clinicianLabel,
    required this.formatLabel,
  });

  final String title;
  final String categoryLabel;
  final String priceLabel;
  final String locationLabel;
  final String locationShortLabel;
  final String clinicianLabel;
  final String formatLabel;

  List<String> get detailLines => <String>[
        'Price: $priceLabel',
        'Location: $locationLabel',
        'Format: $formatLabel',
        'With: $clinicianLabel',
      ];
}

const Map<String, DemoPatientIdentity> _demoPatientsById =
    <String, DemoPatientIdentity>{
  'PT0000': DemoPatientIdentity(
    patientId: 'PT0000',
    displayName: 'Mila Neumann',
    loginAlias: 'patient0',
    subtitle: 'New customer journey',
    personaText:
        'Mila Neumann is a new customer in the onboarding stage. She has not connected any meaningful data sources yet and is still deciding what she wants help with first. The right journey for her is simple and confidence-building: connect one useful source, choose one clear goal, and only then decide whether a clinic visit or baseline test makes sense.',
  ),
  'PT0001': DemoPatientIdentity(
    patientId: 'PT0001',
    displayName: 'Daniel Moreau',
    loginAlias: 'patient1',
    subtitle: 'Active recovery journey',
    personaText:
        'Daniel Moreau is a 66-year-old man in France recovering from a recent heart attack, on top of type 2 diabetes and dyslipidemia. He already has a smartwatch connected, so the app can see movement, sleep, resting heart rate, and recovery trends, and it also has enough medical context to know that cardiac follow-up, glucose control, lipid management, and realistic nutrition support all matter right now. He is not a blank-slate wellness user; he needs safe recovery pacing, clearer cardiology next steps, and food support that fits both heart recovery and metabolic risk.',
  ),
};

const Map<String, OfferPracticalInfo> _offerPracticalInfoByCode =
    <String, OfferPracticalInfo>{
  'preventive_cardiometabolic_panel': OfferPracticalInfo(
    title: 'Heart & metabolism follow-up',
    categoryLabel: 'Specialist visit',
    priceLabel: 'EUR 240',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Dr. Claire Martin, preventive cardiology',
    formatLabel: '40 minute review visit',
  ),
  'cardiology_follow_up_visit': OfferPracticalInfo(
    title: 'Cardiology follow-up visit',
    categoryLabel: 'Cardiology visit',
    priceLabel: 'EUR 220',
    locationLabel:
        'Institut Cardiaque Rive Gauche, 42 Rue de Sevres, Paris 75007',
    locationShortLabel: '42 Rue de Sevres',
    clinicianLabel: 'Dr. Antoine Lefevre, cardiologist',
    formatLabel: '30 to 45 minute follow-up visit',
  ),
  'cardiac_rehab_intake': OfferPracticalInfo(
    title: 'Cardiac rehab starter visit',
    categoryLabel: 'Recovery program',
    priceLabel: 'EUR 180 intake',
    locationLabel: 'Centre Cardio Seine, 11 Rue du Bac, Paris 75007',
    locationShortLabel: '11 Rue du Bac',
    clinicianLabel: 'Julie Bernard, cardiac rehab therapist',
    formatLabel: 'Initial intake plus structured rehab plan',
  ),
  'advanced_lipid_lab_panel': OfferPracticalInfo(
    title: 'Heart risk lab check',
    categoryLabel: 'Lab test',
    priceLabel: 'EUR 140',
    locationLabel: 'Laboratoire Saint-Germain, 12 Rue Bonaparte, Paris 75006',
    locationShortLabel: '12 Rue Bonaparte',
    clinicianLabel: 'Reviewed by Dr. Lea Fournier',
    formatLabel: 'Single lab visit plus results review',
  ),
  'movement_program': OfferPracticalInfo(
    title: 'Recovery movement coaching',
    categoryLabel: 'Coaching plan',
    priceLabel: 'EUR 129 / month',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Marc Perrin, movement coach',
    formatLabel: 'Weekly coaching plan',
  ),
  'nutrition_coaching': OfferPracticalInfo(
    title: 'Cardiometabolic nutrition coaching',
    categoryLabel: 'Coaching plan',
    priceLabel: 'EUR 119 / month',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Sophie Laurent, nutrition coach',
    formatLabel: 'Weekly habit coaching',
  ),
  'cardiometabolic_nutrition_consult': OfferPracticalInfo(
    title: 'Cardiometabolic dietitian consult',
    categoryLabel: 'Dietitian visit',
    priceLabel: 'EUR 160',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Dr. Lea Fournier and Sophie Laurent',
    formatLabel: '45 minute nutrition consult',
  ),
  'heart_health_supplement_review': OfferPracticalInfo(
    title: 'Heart & lipid supplement review',
    categoryLabel: 'Add-on review',
    priceLabel: 'EUR 95',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Dr. Claire Martin',
    formatLabel: '20 minute review',
  ),
  'longevity_intake_visit': OfferPracticalInfo(
    title: 'Longevity starter visit',
    categoryLabel: 'Intake visit',
    priceLabel: 'EUR 260',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Dr. Camille Moreau, longevity physician',
    formatLabel: '45 minute intake visit',
  ),
  'baseline_lab_workup': OfferPracticalInfo(
    title: 'Baseline lab check',
    categoryLabel: 'Lab test',
    priceLabel: 'EUR 190',
    locationLabel: 'Laboratoire Saint-Germain, 12 Rue Bonaparte, Paris 75006',
    locationShortLabel: '12 Rue Bonaparte',
    clinicianLabel: 'Reviewed by Dr. Lea Fournier',
    formatLabel: 'Single lab draw plus result summary',
  ),
  'cardiovascular_screening_visit': OfferPracticalInfo(
    title: 'Heart health screening visit',
    categoryLabel: 'Screening visit',
    priceLabel: 'EUR 260',
    locationLabel:
        'Institut Cardiaque Rive Gauche, 42 Rue de Sevres, Paris 75007',
    locationShortLabel: '42 Rue de Sevres',
    clinicianLabel: 'Dr. Antoine Lefevre, cardiologist',
    formatLabel: '45 minute screening visit',
  ),
  'sleep_recovery_package': OfferPracticalInfo(
    title: 'Sleep & recovery check-in',
    categoryLabel: 'Sleep package',
    priceLabel: 'EUR 145',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Dr. Elise Morel, sleep physician',
    formatLabel: 'Review plus optional follow-up',
  ),
  'follow_up_prep': OfferPracticalInfo(
    title: 'Prepare for your next doctor visit',
    categoryLabel: 'Prep session',
    priceLabel: 'EUR 75',
    locationLabel: 'Maison de la Longevite, 18 Rue de Rennes, Paris 75006',
    locationShortLabel: '18 Rue de Rennes',
    clinicianLabel: 'Lucie Bernard, care coordinator',
    formatLabel: '20 minute prep session',
  ),
  'meal_tracking_reset': OfferPracticalInfo(
    title: '7-day meal tracking starter',
    categoryLabel: 'Starter habit',
    priceLabel: 'Included',
    locationLabel: 'In app',
    locationShortLabel: 'In app',
    clinicianLabel: 'Coach-guided setup',
    formatLabel: '7 day starter plan',
  ),
};

const Map<String, String> _offerEvidenceLabels = <String, String>{
  'medical record history': 'your medical history already on file',
  'current medications': 'your current medication list',
  'watch-based recovery and movement trends':
      'recent recovery and movement trends from your watch',
  'cardiac diagnosis and visit history':
      'heart-related diagnosis and visit history',
  'recent cardiac context': 'recent heart recovery context',
  'current medication and symptom context':
      'your medication list and recent symptoms',
  'cardiovascular risk markers already on file':
      'heart risk markers already on file',
  'medication context': 'your current medication context',
  'doctor visit history': 'your previous doctor visits',
  'steps': 'recent step count',
  'active minutes': 'recent active minutes',
  'resting heart rate and recovery trends':
      'resting heart rate and recovery trends',
  'survey-level nutrition habits': 'broad food habits from your questionnaire',
  'metabolic risk markers': 'metabolic markers already on file',
  'watch-based energy and activity context':
      'energy and activity context from your watch',
  'medication list': 'your medication list',
  'cardiovascular and metabolic risk context':
      'your heart and metabolism risk picture',
  'recent clinical recommendations': 'your recent care recommendations',
  'starting goals': 'the goals you said matter most',
  'any connected records or devices': 'the records and devices you connected',
  'starting profile information': 'your starting profile information',
  'baseline health goals': 'your baseline health goals',
};

const Map<String, String> _missingDataLabels = <String, String>{
  'A week of meal logging would make any nutrition follow-up more specific.':
      '7 days of simple meal logging would make this more personal.',
  'Symptom check-ins after exercise would make the pacing more precise.':
      'Short symptom check-ins after exercise would help pace this more safely.',
  'Meal-by-meal logs would make this meaningfully more tailored.':
      'Meal logging would make this much more personal.',
};

const Map<String, String> _extraAliases = <String, String>{
  'milaneumann': 'PT0000',
  'mila': 'PT0000',
  'danielmoreau': 'PT0001',
  'danielweber': 'PT0001',
  'daniel': 'PT0001',
};

List<String> get demoPatientIdsInOrder =>
    _demoPatientsById.keys.toList(growable: false);

String customerDisplayNameForPatientId(String? patientId) {
  return _demoPatientsById[patientId]?.displayName ?? (patientId ?? 'Customer');
}

String customerSubtitleForPatientId(String? patientId) {
  return _demoPatientsById[patientId]?.subtitle ?? 'Demo journey';
}

String customerPersonaTextForPatientId(String? patientId) {
  return _demoPatientsById[patientId]?.personaText ??
      'This customer does not have a persona description yet.';
}

String customerLoginAliasForPatientId(String? patientId) {
  return _demoPatientsById[patientId]?.loginAlias ?? '';
}

String customerMetaLabel({
  required String? patientId,
  required int? age,
  required String? country,
}) {
  final name = customerDisplayNameForPatientId(patientId);
  final parts = <String>[name];
  if (age != null) {
    parts.add('$age');
  }
  if (country != null && country.isNotEmpty) {
    parts.add(country);
  }
  return parts.join(' • ');
}

String? patientIdForCustomerInput(String input) {
  final normalized = input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  if (normalized == 'patient0' || normalized == 'pt0000') {
    return 'PT0000';
  }
  if (normalized == 'patient1' || normalized == 'pt0001') {
    return 'PT0001';
  }
  return _extraAliases[normalized];
}

OfferPracticalInfo practicalInfoForOffer(
  OfferOpportunity offer,
) {
  return practicalInfoForOfferCode(
    offer.offerCode,
    fallbackTitle: offer.offerLabel,
    fallbackCategory: offer.category,
    fallbackFormat: offer.deliveryModel.isNotEmpty
        ? offer.deliveryModel
        : offer.timeCommitment,
    offerType: offer.offerType,
  );
}

OfferPracticalInfo practicalInfoForOfferCode(
  String offerCode, {
  String fallbackTitle = '',
  String fallbackCategory = '',
  String fallbackFormat = '',
  String offerType = '',
}) {
  final mapped = _offerPracticalInfoByCode[offerCode];
  if (mapped != null) {
    return mapped;
  }

  return OfferPracticalInfo(
    title: fallbackTitle.isNotEmpty ? fallbackTitle : 'Support option',
    categoryLabel:
        fallbackCategory.isNotEmpty ? fallbackCategory : 'Clinic support',
    priceLabel: offerType == 'starter' ? 'Included' : 'Ask clinic',
    locationLabel:
        offerType == 'starter' ? 'In app' : 'Clinic team will confirm',
    locationShortLabel: offerType == 'starter' ? 'In app' : 'TBD',
    clinicianLabel: 'Clinic team',
    formatLabel: fallbackFormat.isNotEmpty ? fallbackFormat : 'To be confirmed',
  );
}

List<String> customerFriendlyOfferEvidence(List<String> items) {
  return items
      .map((item) => _offerEvidenceLabels[item] ?? item)
      .toList(growable: false);
}

List<String> customerFriendlyMissingData(List<String> items) {
  return items
      .map((item) => _missingDataLabels[item] ?? item)
      .toList(growable: false);
}
