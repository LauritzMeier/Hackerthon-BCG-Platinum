import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class FirebaseSessionService {
  FirebaseSessionService._();

  static final FirebaseSessionService instance = FirebaseSessionService._();

  String? _lastError;

  bool get isEnabled => AppConfig.enableFirebase;

  String? get currentUserId {
    if (!isEnabled) {
      return null;
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  String? get lastError => _lastError;

  Future<String?> ensureSignedIn() async {
    if (!isEnabled) {
      _lastError = null;
      return null;
    }

    final existingUser = FirebaseAuth.instance.currentUser;
    if (existingUser != null) {
      _lastError = null;
      return existingUser.uid;
    }

    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      _lastError = null;
      return credential.user?.uid;
    } on FirebaseAuthException catch (error, stackTrace) {
      _lastError = error.message ?? error.code;
      debugPrint(
          'Firebase anonymous auth failed: ${error.code} ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint('Firebase anonymous auth failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
