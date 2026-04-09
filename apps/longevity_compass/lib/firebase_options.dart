import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase has not been configured for this app yet. '
      'Run ./scripts/setup_firebase.sh --project <firebase-project-id> '
      'to generate the real Firebase options and native config files.',
    );
  }
}
