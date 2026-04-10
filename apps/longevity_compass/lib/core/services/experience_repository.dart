import '../config/app_config.dart';
import '../firebase/firestore_customer_profile_service.dart';
import '../firebase/firestore_experience_service.dart';
import '../firebase/firestore_chat_service.dart';
import '../firebase/firestore_support_booking_service.dart';
import '../firebase/firebase_session_service.dart';
import '../models/experience_models.dart';
import 'agent_chat_service.dart';
import 'api_client.dart';
import 'local_coach_reply_service.dart';

class ExperienceRepository {
  ExperienceRepository({
    ApiClient? apiClient,
    AgentChatService? agentChatService,
    FirestoreExperienceService? firestoreExperienceService,
    FirestoreChatService? firestoreChatService,
    FirestoreCustomerProfileService? firestoreCustomerProfileService,
    FirestoreSupportBookingService? firestoreSupportBookingService,
    FirebaseSessionService? firebaseSessionService,
    LocalCoachReplyService? localCoachReplyService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _agentChatService = agentChatService ?? AgentChatService(),
        _firestoreExperienceService =
            firestoreExperienceService ?? FirestoreExperienceService(),
        _firestoreChatService = firestoreChatService ?? FirestoreChatService(),
        _firestoreCustomerProfileService = firestoreCustomerProfileService ??
            FirestoreCustomerProfileService(),
        _firestoreSupportBookingService =
            firestoreSupportBookingService ?? FirestoreSupportBookingService(),
        _firebaseSessionService =
            firebaseSessionService ?? FirebaseSessionService.instance,
        _localCoachReplyService =
            localCoachReplyService ?? const LocalCoachReplyService();

  final ApiClient _apiClient;
  final AgentChatService _agentChatService;
  final FirestoreExperienceService _firestoreExperienceService;
  final FirestoreChatService _firestoreChatService;
  final FirestoreCustomerProfileService _firestoreCustomerProfileService;
  final FirestoreSupportBookingService _firestoreSupportBookingService;
  final FirebaseSessionService _firebaseSessionService;
  final LocalCoachReplyService _localCoachReplyService;

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

  Future<CoachReply> sendCoachMessage(
    String patientId,
    String message, {
    ExperienceSnapshot? experience,
    CustomerProfile? customerProfile,
    List<SupportBooking> supportBookings = const [],
  }) async {
    if (experience != null && shouldUseLiveAgentFor(customerProfile)) {
      final agentReply = await _agentChatService.requestReply(
        message: message,
        patientId: patientId,
      );
      return CoachReply(
        reply: agentReply.reply,
        primaryFocus: experience.weeklyPlan.primaryFocus,
        updatedPillars: agentReply.evidenceIndex
            .map(PillarSnapshot.fromJson)
            .toList(growable: false),
      );
    }

    if (AppConfig.enableFirebase && experience != null) {
      return _localCoachReplyService.buildReply(
        experience: experience,
        message: message,
        customerProfile: customerProfile,
        supportBookings: supportBookings,
      );
    }

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

  Future<CustomerProfile> fetchCustomerProfile(
    String patientId, {
    ExperienceSnapshot? experience,
  }) async {
    if (AppConfig.enableFirebase) {
      final profile = await _firestoreCustomerProfileService.fetchProfile(
        patientId,
      );
      if (profile != null) {
        return profile;
      }
    }

    return _fallbackCustomerProfile(
      patientId: patientId,
      experience: experience,
    );
  }

  Future<CustomerProfile> updateDataSourceConnection({
    required CustomerProfile profile,
    required String sourceId,
    required bool connected,
    String? provider,
  }) async {
    final updatedSources = profile.dataSources.map((source) {
      if (source.sourceId != sourceId) {
        return source;
      }

      final nextProvider = connected ? (provider ?? source.provider) : '';
      return source.copyWith(
        connected: connected,
        provider: nextProvider,
        statusText: _statusTextForSource(
          sourceId: sourceId,
          connected: connected,
          provider: nextProvider,
        ),
      );
    }).toList(growable: false);

    final updatedProfile = profile.copyWith(
      dataSources: updatedSources,
      journeySummary: profile.isWelcomeJourney
          ? _welcomeSummaryForCount(
              updatedSources.where((source) => source.connected).length,
            )
          : profile.journeySummary,
      updatedAt: DateTime.now(),
    );

    if (AppConfig.enableFirebase) {
      return _firestoreCustomerProfileService.saveProfile(updatedProfile);
    }

    return updatedProfile;
  }

  Future<List<SupportBooking>> fetchSupportBookings(String patientId) async {
    if (AppConfig.enableFirebase) {
      return _firestoreSupportBookingService.fetchBookings(patientId);
    }
    return <SupportBooking>[];
  }

  Future<SupportBooking> createSupportBooking({
    required String patientId,
    required OfferOpportunity offer,
    required DateTime scheduledFor,
    required String scheduledLabel,
  }) {
    return _firestoreSupportBookingService.createBooking(
      patientId: patientId,
      offer: offer,
      scheduledFor: scheduledFor,
      scheduledLabel: scheduledLabel,
    );
  }

  bool get isFirebaseEnabled => AppConfig.enableFirebase;

  bool get hasAgentConfigured => AppConfig.agentBaseUrl.trim().isNotEmpty;

  bool shouldUseLiveAgentFor(CustomerProfile? customerProfile) =>
      hasAgentConfigured && !(customerProfile?.isWelcomeJourney ?? false);

  String? get currentFirebaseUserId => _firebaseSessionService.currentUserId;

  String? get firebaseSessionError => _firebaseSessionService.lastError;

  String get defaultPatientId => AppConfig.demoPatientId;

  void dispose() {
    _apiClient.dispose();
    _agentChatService.dispose();
  }

  CustomerProfile _fallbackCustomerProfile({
    required String patientId,
    ExperienceSnapshot? experience,
  }) {
    final hasWearable = experience?.progressSummary.latestReadingDate != null ||
        (experience?.progressSummary.headlineTrends.isNotEmpty ?? false);
    final hasDoctorContext =
        (experience?.careContext.lastAppointmentSummary.isNotEmpty ?? false) &&
            !(experience?.careContext.lastAppointmentSummary.contains(
                  'No doctor summary is connected yet',
                ) ??
                false);
    final needsMealTracking =
        experience?.dataCoverage.needsMealTracking ?? true;

    return CustomerProfile(
      patientId: patientId,
      displayName: patientId,
      journeyStage: 'active',
      journeyTitle: 'Your connected setup',
      journeySummary:
          'These are the sources currently shaping your plan and the ones you could add next.',
      possibilities: const [
        'Use the coach to explain the current plan in plain language.',
        'Connect another source if you want the app to get sharper over time.',
      ],
      dataSources: [
        DataSourceConnection(
          sourceId: 'smartwatch',
          label: 'Smartwatch or wearable',
          category: 'Wearables',
          connected: hasWearable,
          provider: hasWearable ? 'Connected wearable' : '',
          statusText: _statusTextForSource(
            sourceId: 'smartwatch',
            connected: hasWearable,
            provider: hasWearable ? 'Connected wearable' : '',
          ),
          ctaLabel: 'Connect wearable',
        ),
        DataSourceConnection(
          sourceId: 'doctor_records',
          label: 'Doctor records',
          category: 'Medical context',
          connected: hasDoctorContext,
          provider: hasDoctorContext ? 'Imported records' : '',
          statusText: _statusTextForSource(
            sourceId: 'doctor_records',
            connected: hasDoctorContext,
            provider: hasDoctorContext ? 'Imported records' : '',
          ),
          ctaLabel: 'Add doctor context',
        ),
        DataSourceConnection(
          sourceId: 'lab_results',
          label: 'Lab results',
          category: 'Diagnostics',
          connected: false,
          provider: '',
          statusText: _statusTextForSource(
            sourceId: 'lab_results',
            connected: false,
          ),
          ctaLabel: 'Add labs',
        ),
        DataSourceConnection(
          sourceId: 'meal_tracking',
          label: 'Meal tracking',
          category: 'Lifestyle',
          connected: !needsMealTracking,
          provider: !needsMealTracking ? 'In-app tracking' : '',
          statusText: _statusTextForSource(
            sourceId: 'meal_tracking',
            connected: !needsMealTracking,
            provider: !needsMealTracking ? 'In-app tracking' : '',
          ),
          ctaLabel: 'Turn on meal tracking',
        ),
      ],
      updatedAt: DateTime.now(),
    );
  }
}

String _statusTextForSource({
  required String sourceId,
  required bool connected,
  String? provider,
}) {
  switch (sourceId) {
    case 'smartwatch':
      return connected
          ? '${provider?.isNotEmpty == true ? provider : 'Wearable'} is connected and ready to feed recovery trends into the app.'
          : 'Connect a smartwatch or ring to unlock recovery and activity trends.';
    case 'doctor_records':
      return connected
          ? 'Doctor context is connected, so the coach can start informed.'
          : 'Add your last appointment summary or medication list so the coach does not start blind.';
    case 'lab_results':
      return connected
          ? 'Baseline lab markers are connected and can shape the next review.'
          : 'Add baseline labs if you want early recommendations to lean on objective markers.';
    case 'meal_tracking':
      return connected
          ? 'Meal tracking is on, so nutrition can react to real logs.'
          : 'Turn this on later if you want more specific nutrition guidance.';
    default:
      return connected ? 'Connected.' : 'Not connected yet.';
  }
}

String _welcomeSummaryForCount(int connectedCount) {
  if (connectedCount <= 0) {
    return 'Start with one source, one clear goal, and one first booking. That is enough to make the next screens meaningfully better.';
  }
  if (connectedCount == 1) {
    return 'You have started the setup. One more useful source or one first booking will make the journey feel much more concrete.';
  }
  return 'You have the foundations in place. The next step is to use the coach or book the first support option that matches your goal.';
}
