import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../../firebase_options.dart';
import 'firebase_session_service.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    if (!AppConfig.enableFirebase) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseSessionService.instance.ensureSignedIn();
    await FirebaseAnalytics.instance.logAppOpen();

    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }
}
