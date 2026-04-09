import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/experience_models.dart';

class FirestoreCustomerProfileService {
  FirestoreCustomerProfileService({FirebaseFirestore? firestore})
      : _firestore = AppConfig.enableFirebase
            ? (firestore ??
                FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: AppConfig.firestoreDatabaseId,
                ))
            : null;

  final FirebaseFirestore? _firestore;

  bool get isEnabled => AppConfig.enableFirebase;

  Future<CustomerProfile?> fetchProfile(String patientId) async {
    if (!isEnabled) {
      return null;
    }

    try {
      final document = await _firestore!
          .collection('customer_profiles')
          .doc(patientId)
          .get();
      if (!document.exists) {
        return null;
      }

      final data = _normalizeMap(document.data()!);
      data.putIfAbsent('patient_id', () => patientId);
      return CustomerProfile.fromJson(data);
    } catch (error, stackTrace) {
      debugPrint('Firestore customer profile read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<CustomerProfile> saveProfile(CustomerProfile profile) async {
    if (!isEnabled) {
      return profile;
    }

    final payload = <String, dynamic>{
      'patient_id': profile.patientId,
      'display_name': profile.displayName,
      'journey_stage': profile.journeyStage,
      'journey_title': profile.journeyTitle,
      'journey_summary': profile.journeySummary,
      'possibilities': profile.possibilities,
      'data_sources': profile.dataSources.map((item) => item.toJson()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore!
        .collection('customer_profiles')
        .doc(profile.patientId)
        .set(payload, SetOptions(merge: true));

    final refreshed = await fetchProfile(profile.patientId);
    return refreshed ?? profile;
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
}
