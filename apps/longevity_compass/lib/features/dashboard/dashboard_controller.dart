import 'package:flutter/foundation.dart';

import '../../core/firebase/firestore_chat_service.dart';
import '../../core/models/experience_models.dart';
import '../../core/services/experience_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required ExperienceRepository repository,
  }) : _repository = repository;

  final ExperienceRepository _repository;

  bool isLoading = false;
  bool isSendingMessage = false;
  String? errorMessage;
  List<PatientListItem> patients = <PatientListItem>[];
  ExperienceSnapshot? experience;
  List<ChatMessage> chatMessages = <ChatMessage>[];
  String? selectedPatientId;
  String? firebaseUserId;
  String? firestoreStatusMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _initializeFirebaseSession();
      patients = await _repository.fetchPatients();
      selectedPatientId = _resolveInitialPatientId();
      await _loadCurrentExperience();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (selectedPatientId == null) {
      await load();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _loadCurrentExperience();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPatient(String patientId) async {
    if (selectedPatientId == patientId) {
      return;
    }

    selectedPatientId = patientId;
    await refresh();
  }

  Future<void> sendCoachMessage(String message) async {
    final patientId = selectedPatientId;
    final trimmed = message.trim();
    final currentExperience = experience;
    if (patientId == null || trimmed.isEmpty || currentExperience == null) {
      return;
    }

    chatMessages = <ChatMessage>[
      ...chatMessages,
      ChatMessage.user(trimmed),
    ];
    isSendingMessage = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userWriteResult = await _repository.persistChatMessage(
        patientId,
        ChatMessage.user(trimmed),
      );
      _updateFirestoreStatus(userWriteResult);

      final reply = await _repository.sendCoachMessage(
        patientId,
        trimmed,
        experience: currentExperience,
      );
      final assistantMessage = ChatMessage.assistant(reply.reply);
      chatMessages = <ChatMessage>[...chatMessages, assistantMessage];

      final assistantWriteResult = await _repository.persistChatMessage(
        patientId,
        assistantMessage,
      );
      _updateFirestoreStatus(assistantWriteResult);
    } catch (error) {
      errorMessage = error.toString();
      final fallbackMessage = ChatMessage.assistant(
        'I saved your note, but I could not shape a useful reply from your current context just now.',
      );
      chatMessages = <ChatMessage>[...chatMessages, fallbackMessage];

      final fallbackWriteResult = await _repository.persistChatMessage(
        patientId,
        fallbackMessage,
      );
      _updateFirestoreStatus(fallbackWriteResult);
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }

  bool get isFirebaseEnabled => _repository.isFirebaseEnabled;

  String get firestoreMessagesPath {
    final patientId = selectedPatientId ?? '<patient-id>';
    return 'coach_conversations/$patientId/messages';
  }

  Future<void> _initializeFirebaseSession() async {
    if (!_repository.isFirebaseEnabled) {
      firebaseUserId = null;
      firestoreStatusMessage = 'Firebase sync is disabled for this build.';
      return;
    }

    firebaseUserId = await _repository.ensureFirebaseSession();
    firestoreStatusMessage = firebaseUserId == null
        ? (_repository.firebaseSessionError ??
            'Firebase auth is configured, but anonymous sign-in did not succeed yet.')
        : 'Firestore sync active as anonymous user ${firebaseUserId!.substring(0, 8)}.';
  }

  void _updateFirestoreStatus(FirestoreChatWriteResult result) {
    firebaseUserId =
        result.userId ?? firebaseUserId ?? _repository.currentFirebaseUserId;
    firestoreStatusMessage = result.statusMessage;
  }

  String _resolveInitialPatientId() {
    if (patients
        .any((patient) => patient.patientId == _repository.defaultPatientId)) {
      return _repository.defaultPatientId;
    }
    if (patients.isNotEmpty) {
      return patients.first.patientId;
    }
    return _repository.defaultPatientId;
  }

  Future<void> _loadCurrentExperience() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      return;
    }

    experience = await _repository.fetchExperience(patientId);
    final storedMessages = await _repository.fetchChatMessages(patientId);
    chatMessages = storedMessages.isNotEmpty
        ? storedMessages
        : <ChatMessage>[
            ChatMessage.assistant(experience!.coach.intro),
          ];
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
