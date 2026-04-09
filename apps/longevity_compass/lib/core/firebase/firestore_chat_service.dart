import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/experience_models.dart';
import 'firebase_session_service.dart';

class FirestoreChatWriteResult {
  const FirestoreChatWriteResult({
    required this.didWrite,
    required this.collectionPath,
    this.userId,
    this.errorMessage,
  });

  final bool didWrite;
  final String collectionPath;
  final String? userId;
  final String? errorMessage;

  String get statusMessage {
    if (!AppConfig.enableFirebase) {
      return 'Firebase sync is disabled for this build.';
    }
    if (didWrite && userId != null) {
      return 'Firestore sync active as anonymous user ${userId!.substring(0, 8)}.';
    }
    return errorMessage ?? 'Firestore sync is unavailable right now.';
  }
}

class FirestoreChatService {
  FirestoreChatService({
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

  Future<List<ChatMessage>> fetchMessages(String patientId) async {
    if (!isEnabled) {
      return <ChatMessage>[];
    }

    try {
      final snapshot = await _firestore!
          .collection('coach_conversations')
          .doc(patientId)
          .collection('messages')
          .orderBy('created_at')
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return ChatMessage(
              role: data['role']?.toString() ?? 'assistant',
              text: data['text']?.toString() ?? '',
            );
          })
          .where((message) => message.text.isNotEmpty)
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('Firestore chat read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <ChatMessage>[];
    }
  }

  Future<FirestoreChatWriteResult> persistMessage({
    required String patientId,
    required ChatMessage message,
  }) async {
    final collectionPath = _messagesPath(patientId);
    if (!isEnabled) {
      return FirestoreChatWriteResult(
        didWrite: false,
        collectionPath: collectionPath,
      );
    }

    final userId = await _sessionService.ensureSignedIn();
    if (userId == null) {
      return FirestoreChatWriteResult(
        didWrite: false,
        collectionPath: collectionPath,
        errorMessage: _sessionService.lastError ??
            'Anonymous Firebase auth did not succeed.',
      );
    }

    try {
      final conversationRef =
          _firestore!.collection('coach_conversations').doc(patientId);
      await conversationRef.set({
        'patient_id': patientId,
        'last_message_preview': message.text,
        'last_role': message.role,
        'last_updated_at': FieldValue.serverTimestamp(),
        'last_auth_uid': userId,
        'source': 'longevity_compass_app',
      }, SetOptions(merge: true));

      await conversationRef.collection('messages').add({
        'patient_id': patientId,
        'auth_uid': userId,
        'role': message.role,
        'text': message.text,
        'created_at': FieldValue.serverTimestamp(),
        'source': 'longevity_compass_app',
      });

      return FirestoreChatWriteResult(
        didWrite: true,
        collectionPath: collectionPath,
        userId: userId,
      );
    } catch (error, stackTrace) {
      debugPrint('Firestore chat write failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return FirestoreChatWriteResult(
        didWrite: false,
        collectionPath: collectionPath,
        userId: userId,
        errorMessage: error.toString(),
      );
    }
  }

  String _messagesPath(String patientId) =>
      'coach_conversations/$patientId/messages';
}
