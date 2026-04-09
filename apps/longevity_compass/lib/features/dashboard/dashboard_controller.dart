import 'package:flutter/foundation.dart';

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

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
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
    if (patientId == null || trimmed.isEmpty) {
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
      final reply = await _repository.sendCoachMessage(patientId, trimmed);
      chatMessages = <ChatMessage>[
        ...chatMessages,
        ChatMessage.assistant(reply.reply),
      ];
    } catch (error) {
      errorMessage = error.toString();
      chatMessages = <ChatMessage>[
        ...chatMessages,
        ChatMessage.assistant(
          'I could not reach the coach service just now, but your weekly plan is still available.',
        ),
      ];
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }

  String _resolveInitialPatientId() {
    if (patients.any((patient) => patient.patientId == _repository.defaultPatientId)) {
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
    chatMessages = <ChatMessage>[
      ChatMessage.assistant(experience!.coach.intro),
    ];
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
