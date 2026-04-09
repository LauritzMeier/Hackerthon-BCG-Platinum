import '../config/app_config.dart';
import '../firebase/firestore_experience_service.dart';
import '../firebase/firebase_session_service.dart';
import '../firebase/firestore_chat_service.dart';
import '../models/experience_models.dart';
import 'api_client.dart';

class ExperienceRepository {
  ExperienceRepository({
    ApiClient? apiClient,
    FirestoreExperienceService? firestoreExperienceService,
    FirestoreChatService? firestoreChatService,
    FirebaseSessionService? firebaseSessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _firestoreExperienceService =
            firestoreExperienceService ?? FirestoreExperienceService(),
        _firestoreChatService = firestoreChatService ?? FirestoreChatService(),
        _firebaseSessionService =
            firebaseSessionService ?? FirebaseSessionService.instance;

  final ApiClient _apiClient;
  final FirestoreExperienceService _firestoreExperienceService;
  final FirestoreChatService _firestoreChatService;
  final FirebaseSessionService _firebaseSessionService;

  Future<List<PatientListItem>> fetchPatients() async {
    if (AppConfig.enableFirebase) {
      return _firestoreExperienceService.fetchPatients(limit: 50);
    }

    final response = await _apiClient.getMap('/patients?limit=50');
    final items = response['items'];
    if (items is! List) {
      return <PatientListItem>[];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(PatientListItem.fromJson)
        .toList(growable: false);
  }

  Future<ExperienceSnapshot> fetchExperience(String patientId) async {
    if (AppConfig.enableFirebase) {
      return _firestoreExperienceService.fetchExperience(patientId);
    }

    final response = await _apiClient.getMap('/patients/$patientId/experience');
    return ExperienceSnapshot.fromJson(response);
  }

  Future<CoachReply> sendCoachMessage(String patientId, String message) async {
    final response = await _apiClient.postJson(
      '/patients/$patientId/coach/reply',
      {'message': message},
    );
    return CoachReply.fromJson(response);
  }

  Future<String?> ensureFirebaseSession() {
    return _firebaseSessionService.ensureSignedIn();
  }

  Future<FirestoreChatWriteResult> persistChatMessage(
    String patientId,
    ChatMessage message,
  ) {
    return _firestoreChatService.persistMessage(
      patientId: patientId,
      message: message,
    );
  }

  Future<List<ChatMessage>> fetchChatMessages(String patientId) {
    return _firestoreChatService.fetchMessages(patientId);
  }

  bool get isFirebaseEnabled => AppConfig.enableFirebase;

  String? get currentFirebaseUserId => _firebaseSessionService.currentUserId;

  String? get firebaseSessionError => _firebaseSessionService.lastError;

  String get defaultPatientId => AppConfig.demoPatientId;

  void dispose() {
    _apiClient.dispose();
  }
}
