import 'package:flutter/foundation.dart';

import '../../core/firebase/firestore_chat_service.dart';
import '../../core/models/experience_models.dart';
import '../../core/presentation/customer_facing_content.dart';
import '../../core/services/experience_repository.dart';

class DashboardController extends ChangeNotifier {
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

    final baseMessages = _withoutTransientWelcomeIntro(
      messages: chatMessages,
      experience: currentExperience,
    );
    chatMessages = <ChatMessage>[...baseMessages, ChatMessage.user(trimmed)];
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
      _applyCoachReply(reply);
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

  List<ChatMessage> _withoutTransientWelcomeIntro({
    required List<ChatMessage> messages,
    required ExperienceSnapshot experience,
  }) {
    final isWelcome = customerProfile?.isWelcomeJourney ?? false;
    if (!isWelcome || messages.isEmpty) {
      return messages;
    }

    final firstMessage = messages.first;
    final isIntroMessage =
        !firstMessage.isUser && firstMessage.text == experience.coach.intro;
    if (!isIntroMessage) {
      return messages;
    }

    return messages.skip(1).toList(growable: false);
  }

  void _applyCoachReply(CoachReply reply) {
    final currentExperience = experience;
    if (currentExperience == null) {
      return;
    }

    final nextPrimaryFocus = _resolvedPrimaryFocus(
      reply.primaryFocus,
      fallback: currentExperience.weeklyPlan.primaryFocus,
    );
    final nextPillars = _mergeUpdatedPillars(
      currentExperience.compass.pillars,
      reply.updatedPillars,
    );
    final nextPeerComparison = _mergePeerComparison(
      currentExperience.compass.peerComparison,
      nextPillars,
    );

    experience = ExperienceSnapshot(
      patientId: currentExperience.patientId,
      generatedAt: currentExperience.generatedAt,
      profileSummary: currentExperience.profileSummary,
      compass: CompassSnapshot(
        overallDirection: currentExperience.compass.overallDirection,
        chronologicalAge: currentExperience.compass.chronologicalAge,
        estimatedBiologicalAge:
            currentExperience.compass.estimatedBiologicalAge,
        primaryFocus: nextPrimaryFocus,
        pillars: nextPillars,
        peerComparison: nextPeerComparison,
        suggestedQuestions: currentExperience.compass.suggestedQuestions,
      ),
      weeklyPlan: WeeklyPlan(
        title: currentExperience.weeklyPlan.title,
        primaryFocus: nextPrimaryFocus,
        actions: currentExperience.weeklyPlan.actions,
        checkInPrompt: currentExperience.weeklyPlan.checkInPrompt,
      ),
      coach: currentExperience.coach,
      journeyStart: currentExperience.journeyStart,
      careContext: currentExperience.careContext,
      dataCoverage: currentExperience.dataCoverage,
      progressSummary: currentExperience.progressSummary,
      alerts: currentExperience.alerts,
      offers: currentExperience.offers,
    );
  }

  PrimaryFocus _resolvedPrimaryFocus(
    PrimaryFocus candidate, {
    required PrimaryFocus fallback,
  }) {
    if (candidate.pillarId.isEmpty || candidate.pillarName.isEmpty) {
      return fallback;
    }
    return candidate;
  }

  List<PillarSnapshot> _mergeUpdatedPillars(
    List<PillarSnapshot> currentPillars,
    List<PillarSnapshot> updatedPillars,
  ) {
    if (updatedPillars.isEmpty) {
      return currentPillars;
    }
    if (currentPillars.isEmpty) {
      return updatedPillars;
    }

    final updatedById = <String, PillarSnapshot>{
      for (final pillar in updatedPillars) pillar.id: pillar,
    };

    return currentPillars
        .map((pillar) => updatedById[pillar.id] ?? pillar)
        .toList(growable: false);
  }

  PeerComparisonSnapshot _mergePeerComparison(
    PeerComparisonSnapshot currentComparison,
    List<PillarSnapshot> pillars,
  ) {
    if (currentComparison.items.isEmpty || pillars.isEmpty) {
      return currentComparison;
    }

    final pillarById = <String, PillarSnapshot>{
      for (final pillar in pillars) pillar.id: pillar,
    };

    final nextItems = currentComparison.items.map((item) {
      final pillar = pillarById[item.pillarId];
      if (pillar == null) {
        return item;
      }

      return PeerComparisonItem(
        pillarId: item.pillarId,
        pillarName: pillar.name.isNotEmpty ? pillar.name : item.pillarName,
        patientScore: pillar.score,
        patientScoreLabel: pillar.scoreLabel,
        peerScore: item.peerScore,
        peerScoreLabel: item.peerScoreLabel,
        difference: pillar.score - item.peerScore,
        hasEnoughData: pillar.hasEnoughData,
        scoreConfidence: pillar.scoreConfidence,
      );
    }).toList(growable: false);

    if (nextItems.isEmpty) {
      return currentComparison;
    }

    final strongestRelative = nextItems.reduce(
      (best, item) => item.difference > best.difference ? item : best,
    );
    final biggestGap = nextItems.reduce(
      (worst, item) => item.difference < worst.difference ? item : worst,
    );

    return PeerComparisonSnapshot(
      headline: currentComparison.headline,
      cohortLabel: currentComparison.cohortLabel,
      sampleSize: currentComparison.sampleSize,
      strongestRelativePillarId: strongestRelative.pillarId,
      biggestGapPillarId: biggestGap.pillarId,
      items: nextItems,
    );
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

  List<String> get supportedDemoPatientIds => demoPatientIdsInOrder;

  String? patientIdForUsername(String username) {
    return patientIdForCustomerInput(username);
  }

  bool hasPatient(String patientId) {
    return patients.any((patient) => patient.patientId == patientId);
  }

  Future<bool> loginWithUsername(String username) async {
    final patientId = patientIdForUsername(username);
    if (patientId == null) {
      errorMessage =
          'Use Mila Neumann or Daniel Moreau to log in. Demo aliases still work too.';
      notifyListeners();
      return false;
    }

    return loginWithPatientId(patientId);
  }

  Future<bool> loginWithPatientId(String patientId) async {
    if (!hasPatient(patientId)) {
      errorMessage =
          '${customerDisplayNameForPatientId(patientId)} is not available in this build yet.';
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

  Future<void> refreshSupportBookings() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      return;
    }

    try {
      supportBookings = await _repository.fetchSupportBookings(patientId);
      errorMessage = null;
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
