import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/experience_models.dart';

class FirestoreExperienceService {
  static const Set<String> _hiddenPatientIds = {'PTWELCOME'};

  FirestoreExperienceService({FirebaseFirestore? firestore})
      : _firestore = AppConfig.enableFirebase
            ? (firestore ??
                FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: AppConfig.firestoreDatabaseId,
                ))
            : null;

  final FirebaseFirestore? _firestore;

  bool get isEnabled => AppConfig.enableFirebase;

  Future<List<PatientListItem>> fetchPatients({int limit = 50}) async {
    if (!isEnabled) {
      return <PatientListItem>[];
    }

    final summaries = await _firestore!
        .collection('patient_summaries')
        .orderBy('patient_id')
        .limit(limit)
        .get();

    if (summaries.docs.isNotEmpty) {
      return summaries.docs
          .map((doc) {
            final data = _normalizeMap(doc.data());
            data.putIfAbsent('patient_id', () => doc.id);
            return PatientListItem.fromJson(data);
          })
          .where((patient) => !_hiddenPatientIds.contains(patient.patientId))
          .toList(growable: false);
    }

    final experiences = await _firestore
        .collection('patient_experiences')
        .orderBy('patient_id')
        .limit(limit)
        .get();

    if (experiences.docs.isEmpty) {
      throw StateError(
        'No Firestore patient data found. Seed `patient_summaries` or '
        '`patient_experiences` first.',
      );
    }

    return experiences.docs
        .map(
          (doc) =>
              _patientListItemFromExperience(doc.id, _normalizeMap(doc.data())),
        )
        .where((patient) => !_hiddenPatientIds.contains(patient.patientId))
        .toList(growable: false);
  }

  Future<ExperienceSnapshot> fetchExperience(String patientId) async {
    if (!isEnabled) {
      throw StateError(
          'Firestore experience access is disabled for this build.');
    }

    final document = await _firestore!
        .collection('patient_experiences')
        .doc(patientId)
        .get();
    if (!document.exists) {
      throw StateError(
        'No Firestore experience found at `patient_experiences/$patientId`.',
      );
    }

    final data = _normalizeMap(document.data()!);
    data.putIfAbsent('patient_id', () => patientId);
    return ExperienceSnapshot.fromJson(data);
  }

  PatientListItem _patientListItemFromExperience(
    String patientId,
    Map<String, dynamic> data,
  ) {
    final profile = _mapValue(data['profile_summary']);
    final compass = _mapValue(data['compass']);
    final primaryFocus = _mapValue(compass['primary_focus']);

    return PatientListItem.fromJson({
      'patient_id': data['patient_id'] ?? patientId,
      'age': profile['age'],
      'sex': profile['sex'],
      'country': profile['country'],
      'primary_focus_area': primaryFocus['pillar_name'],
      'estimated_biological_age': profile['estimated_biological_age'],
    });
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> value) {
    return value.map(
      (key, fieldValue) => MapEntry(key, _normalizeValue(fieldValue)),
    );
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return _normalizeMap(value);
    }
    if (value is Map) {
      return value.map(
        (key, fieldValue) =>
            MapEntry(key.toString(), _normalizeValue(fieldValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, fieldValue) => MapEntry(key.toString(), fieldValue),
      );
    }
    debugPrint('Expected Firestore map but received $value');
    return <String, dynamic>{};
  }
}
