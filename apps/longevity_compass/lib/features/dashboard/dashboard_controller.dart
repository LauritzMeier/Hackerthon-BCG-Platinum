import 'package:flutter/foundation.dart';

import '../../core/firebase/firestore_chat_service.dart';
import '../../core/models/experience_models.dart';
import '../../core/services/experience_repository.dart';

class DashboardController extends ChangeNotifier {
  static const Map<String, String> _loginAliases = <String, String>{
    'patient0': 'PT0000',
    'patient1': 'PT0001',
    'pt0000': 'PT0000',
    'pt0001': 'PT0001',
  };

  DashboardController({
    required ExperienceRepository repository,
  }) : _repository = repository;

  final ExperienceRepository _repository;

  bool hasBootstrapped = false;
  bool isLoading = false;
  bool isSendingMessage = false;
  String? errorMessage;
  List<PatientListItem> patients = <PatientListItem>[];
  ExperienceSnapshot? experience;
  CustomerProfile? customerProfile;
  List<SupportBooking> supportBookings = <SupportBooking>[];
  List<ChatMessage> chatMessages = <ChatMessage>[];
  String? selectedPatientId;
  String? firebaseUserId;
  String? firestoreStatusMessage;
  int _loginSequence = 0;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _initializeFirebaseSession();
      patients = await _repository.fetchPatients();
      hasBootstrapped = true;
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
    await _activatePatient(patientId);
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
        customerProfile: customerProfile,
        supportBookings: supportBookings,
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
        usesLiveAgent
            ? 'I saved your note, but I could not reach the live coach just now. Please try again.'
            : 'I saved your note, but I could not shape a useful reply from your current context just now.',
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

  bool get usesLiveAgent => _repository.shouldUseLiveAgentFor(customerProfile);

  bool get isLoggedIn => selectedPatientId != null && experience != null;

  bool get isWelcomeJourney => customerProfile?.isWelcomeJourney ?? false;

  bool get hasStartedOnboarding =>
      (customerProfile?.connectedSourceCount ?? 0) > 0 ||
      supportBookings.isNotEmpty;

  bool get shouldShowWelcomeGuide =>
      isWelcomeJourney &&
      !hasStartedOnboarding &&
      (customerProfile?.disconnectedSources.isNotEmpty ?? false);

  int get loginSequence => _loginSequence;

  List<String> get supportedLoginUsernames =>
      _loginAliases.keys.where((value) => value.startsWith('patient')).toList();

  String get selectedUsername =>
      usernameForPatientId(selectedPatientId) ?? 'patient1';

  String? usernameForPatientId(String? patientId) {
    if (patientId == null) {
      return null;
    }
    for (final entry in _loginAliases.entries) {
      if (entry.value == patientId && entry.key.startsWith('patient')) {
        return entry.key;
      }
    }
    return null;
  }

  String? patientIdForUsername(String username) {
    final normalized = username.toLowerCase().replaceAll(
          RegExp(r'[\s_-]+'),
          '',
        );
    return _loginAliases[normalized];
  }

  bool hasPatient(String patientId) {
    return patients.any((patient) => patient.patientId == patientId);
  }

  Future<bool> loginWithUsername(String username) async {
    final normalized = username.toLowerCase().replaceAll(
          RegExp(r'[\s_-]+'),
          '',
        );
    final patientId = patientIdForUsername(username);
    if (patientId == null) {
      errorMessage = 'Use `patient0` or `patient1` to log in.';
      notifyListeners();
      return false;
    }

    if (!hasPatient(patientId)) {
      errorMessage =
          '`${usernameForPatientId(patientId) ?? normalized}` is not available in this build yet.';
      notifyListeners();
      return false;
    }

    return _activatePatient(patientId);
  }

  void logout() {
    selectedPatientId = null;
    experience = null;
    customerProfile = null;
    supportBookings = <SupportBooking>[];
    chatMessages = <ChatMessage>[];
    errorMessage = null;
    notifyListeners();
  }

  String get firestoreMessagesPath {
    final patientId = selectedPatientId ?? '<patient-id>';
    return 'coach_conversations/$patientId/messages';
  }

  SupportBooking? bookingForOffer(String offerCode) {
    for (final booking in supportBookings) {
      if (booking.offerCode == offerCode && booking.isBooked) {
        return booking;
      }
    }
    return null;
  }

  Future<SupportBooking?> bookSupportOffer({
    required OfferOpportunity offer,
    required DateTime scheduledFor,
    required String scheduledLabel,
  }) async {
    final patientId = selectedPatientId;
    final existing = bookingForOffer(offer.offerCode);
    if (patientId == null) {
      return null;
    }
    if (existing != null) {
      return existing;
    }

    try {
      final booking = await _repository.createSupportBooking(
        patientId: patientId,
        offer: offer,
        scheduledFor: scheduledFor,
        scheduledLabel: scheduledLabel,
      );
      supportBookings = <SupportBooking>[
        ...supportBookings,
        booking,
      ]..sort((a, b) {
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
      return booking;
    } catch (error) {
      errorMessage = error.toString();
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateDataSourceConnection({
    required String sourceId,
    required bool connected,
    String? provider,
  }) async {
    final currentProfile = customerProfile;
    if (currentProfile == null) {
      return;
    }

    try {
      customerProfile = await _repository.updateDataSourceConnection(
        profile: currentProfile,
        sourceId: sourceId,
        connected: connected,
        provider: provider,
      );
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
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

  Future<bool> _activatePatient(String patientId) async {
    if (selectedPatientId == patientId && experience != null) {
      return true;
    }

    isLoading = true;
    errorMessage = null;
    selectedPatientId = patientId;
    _loginSequence += 1;
    notifyListeners();

    try {
      await _loadCurrentExperience();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      experience = null;
      customerProfile = null;
      supportBookings = <SupportBooking>[];
      chatMessages = <ChatMessage>[];
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentExperience() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      return;
    }

    experience = await _repository.fetchExperience(patientId);
    customerProfile = await _repository.fetchCustomerProfile(
      patientId,
      experience: experience,
    );
    supportBookings = await _repository.fetchSupportBookings(patientId);
    chatMessages = (customerProfile?.isWelcomeJourney ?? false)
        ? <ChatMessage>[
            ChatMessage.assistant(experience!.coach.intro),
          ]
        : <ChatMessage>[];
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
