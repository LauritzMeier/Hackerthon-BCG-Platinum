import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/experience_models.dart';
import 'firebase_session_service.dart';

class FirestoreSupportBookingService {
  FirestoreSupportBookingService({
    FirebaseSessionService? sessionService,
    FirebaseFirestore? firestore,
  })  : _sessionService = sessionService ?? FirebaseSessionService.instance,
        _firestore = AppConfig.enableFirebase
            ? (firestore ??
                FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: AppConfig.firestoreDatabaseId,
                ))
            : null;

  final FirebaseSessionService _sessionService;
  final FirebaseFirestore? _firestore;

  bool get isEnabled => AppConfig.enableFirebase;

  Future<List<SupportBooking>> fetchBookings(String patientId) async {
    if (!isEnabled) {
      return <SupportBooking>[];
    }

    try {
      final snapshot = await _firestore!
          .collection('support_bookings')
          .where('patient_id', isEqualTo: patientId)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = _normalizeMap(doc.data());
        data.putIfAbsent('booking_id', () => doc.id);
        return SupportBooking.fromJson(data);
      }).toList(growable: false);

      bookings.sort((a, b) {
        final aDate = a.scheduledFor;
        final bDate = b.scheduledFor;
        if (aDate == null && bDate == null) {
          return a.offerLabel.compareTo(b.offerLabel);
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });
      return bookings;
    } catch (error, stackTrace) {
      debugPrint('Firestore support bookings read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <SupportBooking>[];
    }
  }

  Future<SupportBooking> createBooking({
    required String patientId,
    required OfferOpportunity offer,
    required DateTime scheduledFor,
    required String scheduledLabel,
  }) async {
    if (!isEnabled) {
      throw StateError('Firebase support booking is disabled for this build.');
    }

    final userId = await _sessionService.ensureSignedIn();
    if (userId == null) {
      throw StateError(
        _sessionService.lastError ??
            'Anonymous Firebase auth did not succeed for support booking.',
      );
    }

    final payload = <String, dynamic>{
      'patient_id': patientId,
      'offer_code': offer.offerCode,
      'offer_label': offer.offerLabel,
      'offer_type': offer.offerType,
      'delivery_model': offer.deliveryModel,
      'status': 'booked',
      'scheduled_for': Timestamp.fromDate(scheduledFor.toUtc()),
      'scheduled_label': scheduledLabel,
      'auth_uid': userId,
      'source': 'longevity_compass_app',
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef =
        await _firestore!.collection('support_bookings').add(payload);
    final saved = await docRef.get();
    final data = _normalizeMap(saved.data() ?? payload);
    data.putIfAbsent('booking_id', () => docRef.id);
    return SupportBooking.fromJson(data);
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
