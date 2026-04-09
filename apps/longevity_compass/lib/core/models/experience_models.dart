class PatientListItem {
  PatientListItem({
    required this.patientId,
    required this.age,
    required this.sex,
    required this.country,
    required this.primaryFocusArea,
    required this.estimatedBiologicalAge,
  });

  factory PatientListItem.fromJson(Map<String, dynamic> json) {
    return PatientListItem(
      patientId: _asString(json['patient_id']),
      age: _asInt(json['age']),
      sex: _asString(json['sex']),
      country: _asString(json['country']),
      primaryFocusArea: _asString(json['primary_focus_area']),
      estimatedBiologicalAge: _asNullableDouble(
        json['estimated_biological_age'],
      ),
    );
  }

  final String patientId;
  final int age;
  final String sex;
  final String country;
  final String primaryFocusArea;
  final double? estimatedBiologicalAge;

  String get displayLabel => '$patientId • $age • $country';
}

class ExperienceSnapshot {
  ExperienceSnapshot({
    required this.patientId,
    required this.generatedAt,
    required this.profileSummary,
    required this.compass,
    required this.weeklyPlan,
    required this.coach,
    required this.journeyStart,
    required this.careContext,
    required this.dataCoverage,
    required this.progressSummary,
    required this.alerts,
    required this.offers,
  });

  factory ExperienceSnapshot.fromJson(Map<String, dynamic> json) {
    return ExperienceSnapshot(
      patientId: _asString(json['patient_id']),
      generatedAt: _asDateTime(json['generated_at']),
      profileSummary: ProfileSummary.fromJson(_asMap(json['profile_summary'])),
      compass: CompassSnapshot.fromJson(_asMap(json['compass'])),
      weeklyPlan: WeeklyPlan.fromJson(_asMap(json['weekly_plan'])),
      coach: CoachSnapshot.fromJson(_asMap(json['coach'])),
      journeyStart: JourneyStart.fromJson(_asMap(json['journey_start'])),
      careContext: CareContext.fromJson(_asMap(json['care_context'])),
      dataCoverage: DataCoverage.fromJson(_asMap(json['data_coverage'])),
      progressSummary: ProgressSummary.fromJson(
        _asMap(json['progress_summary']),
      ),
      alerts: AlertSummary.fromJson(_asMap(json['alerts'])),
      offers: OfferSummary.fromJson(_asMap(json['offers'])),
    );
  }

  final String patientId;
  final DateTime? generatedAt;
  final ProfileSummary profileSummary;
  final CompassSnapshot compass;
  final WeeklyPlan weeklyPlan;
  final CoachSnapshot coach;
  final JourneyStart journeyStart;
  final CareContext careContext;
  final DataCoverage dataCoverage;
  final ProgressSummary progressSummary;
  final AlertSummary alerts;
  final OfferSummary offers;
}

class JourneyStart {
  JourneyStart({
    required this.title,
    required this.summary,
    required this.whatWeKnow,
    required this.whatWeNeed,
    required this.startHere,
  });

  factory JourneyStart.fromJson(Map<String, dynamic> json) {
    return JourneyStart(
      title: _asString(json['title']),
      summary: _asString(json['summary']),
      whatWeKnow: _asStringList(json['what_we_know']),
      whatWeNeed: _asStringList(json['what_we_need']),
      startHere: _asStringList(json['start_here']),
    );
  }

  final String title;
  final String summary;
  final List<String> whatWeKnow;
  final List<String> whatWeNeed;
  final List<String> startHere;
}

class CareContext {
  CareContext({
    required this.headline,
    required this.lastAppointmentTitle,
    required this.lastAppointmentSummary,
    required this.medications,
    required this.conditions,
    required this.clinicalPriorities,
    required this.medicalGuardrail,
  });

  factory CareContext.fromJson(Map<String, dynamic> json) {
    return CareContext(
      headline: _asString(json['headline']),
      lastAppointmentTitle: _asString(json['last_appointment_title']),
      lastAppointmentSummary: _asString(json['last_appointment_summary']),
      medications: _asStringList(json['medications']),
      conditions: _asStringList(json['conditions']),
      clinicalPriorities: _asStringList(json['clinical_priorities']),
      medicalGuardrail: _asString(json['medical_guardrail']),
    );
  }

  final String headline;
  final String lastAppointmentTitle;
  final String lastAppointmentSummary;
  final List<String> medications;
  final List<String> conditions;
  final List<String> clinicalPriorities;
  final String medicalGuardrail;
}

class DataCoverage {
  DataCoverage({
    required this.headline,
    required this.confidenceLabel,
    required this.connectedSources,
    required this.missingSources,
    required this.tailoringNote,
    required this.needsMealTracking,
  });

  factory DataCoverage.fromJson(Map<String, dynamic> json) {
    return DataCoverage(
      headline: _asString(json['headline']),
      confidenceLabel: _asString(json['confidence_label']),
      connectedSources: _asStringList(json['connected_sources']),
      missingSources: _asStringList(json['missing_sources']),
      tailoringNote: _asString(json['tailoring_note']),
      needsMealTracking: _asBool(json['needs_meal_tracking']),
    );
  }

  final String headline;
  final String confidenceLabel;
  final List<String> connectedSources;
  final List<String> missingSources;
  final String tailoringNote;
  final bool needsMealTracking;
}

class ProfileSummary {
  ProfileSummary({
    required this.patientId,
    required this.age,
    required this.sex,
    required this.country,
    required this.estimatedBiologicalAge,
    required this.ageGapYears,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      patientId: _asString(json['patient_id']),
      age: _asInt(json['age']),
      sex: _asString(json['sex']),
      country: _asString(json['country']),
      estimatedBiologicalAge: _asNullableDouble(
        json['estimated_biological_age'],
      ),
      ageGapYears: _asNullableDouble(json['age_gap_years']),
    );
  }

  final String patientId;
  final int age;
  final String sex;
  final String country;
  final double? estimatedBiologicalAge;
  final double? ageGapYears;
}

class CompassSnapshot {
  CompassSnapshot({
    required this.overallDirection,
    required this.chronologicalAge,
    required this.estimatedBiologicalAge,
    required this.primaryFocus,
    required this.pillars,
    required this.peerComparison,
    required this.suggestedQuestions,
  });

  factory CompassSnapshot.fromJson(Map<String, dynamic> json) {
    return CompassSnapshot(
      overallDirection: _asString(json['overall_direction']),
      chronologicalAge: _asInt(json['chronological_age']),
      estimatedBiologicalAge: _asNullableDouble(
        json['estimated_biological_age'],
      ),
      primaryFocus: PrimaryFocus.fromJson(_asMap(json['primary_focus'])),
      pillars: _asObjectList(json['pillars'], PillarSnapshot.fromJson),
      peerComparison: PeerComparisonSnapshot.fromJson(
        _asMap(json['peer_comparison']),
      ),
      suggestedQuestions: _asStringList(json['suggested_questions']),
    );
  }

  final String overallDirection;
  final int chronologicalAge;
  final double? estimatedBiologicalAge;
  final PrimaryFocus primaryFocus;
  final List<PillarSnapshot> pillars;
  final PeerComparisonSnapshot peerComparison;
  final List<String> suggestedQuestions;
}

class PeerComparisonSnapshot {
  PeerComparisonSnapshot({
    required this.headline,
    required this.cohortLabel,
    required this.sampleSize,
    required this.strongestRelativePillarId,
    required this.biggestGapPillarId,
    required this.items,
  });

  factory PeerComparisonSnapshot.fromJson(Map<String, dynamic> json) {
    return PeerComparisonSnapshot(
      headline: _asString(json['headline']),
      cohortLabel: _asString(json['cohort_label']),
      sampleSize: _asInt(json['sample_size']),
      strongestRelativePillarId: _asString(
        json['strongest_relative_pillar_id'],
      ),
      biggestGapPillarId: _asString(json['biggest_gap_pillar_id']),
      items: _asObjectList(json['items'], PeerComparisonItem.fromJson),
    );
  }

  final String headline;
  final String cohortLabel;
  final int sampleSize;
  final String strongestRelativePillarId;
  final String biggestGapPillarId;
  final List<PeerComparisonItem> items;

  bool get hasItems => items.isNotEmpty;
}

class PeerComparisonItem {
  PeerComparisonItem({
    required this.pillarId,
    required this.pillarName,
    required this.patientScore,
    required this.patientScoreLabel,
    required this.peerScore,
    required this.peerScoreLabel,
    required this.difference,
    required this.hasEnoughData,
    required this.scoreConfidence,
  });

  factory PeerComparisonItem.fromJson(Map<String, dynamic> json) {
    final patientScore = _asDouble(json['patient_score']);
    final peerScore = _asDouble(json['peer_score']);
    final patientScoreLabel = _asString(json['patient_score_label']);
    final peerScoreLabel = _asString(json['peer_score_label']);
    return PeerComparisonItem(
      pillarId: _asString(json['pillar_id']),
      pillarName: _asString(json['pillar_name']),
      patientScore: patientScore,
      patientScoreLabel: patientScoreLabel.isNotEmpty
          ? patientScoreLabel
          : patientScore.toStringAsFixed(0),
      peerScore: peerScore,
      peerScoreLabel: peerScoreLabel.isNotEmpty
          ? peerScoreLabel
          : peerScore.toStringAsFixed(0),
      difference: _asDouble(json['difference']),
      hasEnoughData: json.containsKey('has_enough_data')
          ? _asBool(json['has_enough_data'])
          : true,
      scoreConfidence: _asString(json['score_confidence']),
    );
  }

  final String pillarId;
  final String pillarName;
  final double patientScore;
  final String patientScoreLabel;
  final double peerScore;
  final String peerScoreLabel;
  final double difference;
  final bool hasEnoughData;
  final String scoreConfidence;
}

class PrimaryFocus {
  PrimaryFocus({
    required this.pillarId,
    required this.pillarName,
    required this.whyNow,
  });

  factory PrimaryFocus.fromJson(Map<String, dynamic> json) {
    return PrimaryFocus(
      pillarId: _asString(json['pillar_id']),
      pillarName: _asString(json['pillar_name']),
      whyNow: _asString(json['why_now']),
    );
  }

  final String pillarId;
  final String pillarName;
  final String whyNow;
}

class PillarSnapshot {
  PillarSnapshot({
    required this.id,
    required this.name,
    required this.score,
    required this.scoreLabel,
    required this.state,
    required this.trend,
    required this.whyItMatters,
    required this.hasEnoughData,
    required this.scoreConfidence,
  });

  factory PillarSnapshot.fromJson(Map<String, dynamic> json) {
    final score = _asDouble(json['score']);
    final scoreLabel = _asString(json['score_label']);
    return PillarSnapshot(
      id: _asString(json['id']),
      name: _asString(json['name']),
      score: score,
      scoreLabel: scoreLabel.isNotEmpty ? scoreLabel : score.toStringAsFixed(0),
      state: _asString(json['state']),
      trend: _asString(json['trend']),
      whyItMatters: _asString(json['why_it_matters']),
      hasEnoughData: json.containsKey('has_enough_data')
          ? _asBool(json['has_enough_data'])
          : true,
      scoreConfidence: _asString(json['score_confidence']),
    );
  }

  final String id;
  final String name;
  final double score;
  final String scoreLabel;
  final String state;
  final String trend;
  final String whyItMatters;
  final bool hasEnoughData;
  final String scoreConfidence;
}

class WeeklyPlan {
  WeeklyPlan({
    required this.title,
    required this.primaryFocus,
    required this.actions,
    required this.checkInPrompt,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      title: _asString(json['title']),
      primaryFocus: PrimaryFocus.fromJson(_asMap(json['primary_focus'])),
      actions: _asObjectList(json['actions'], PlanAction.fromJson),
      checkInPrompt: _asString(json['check_in_prompt']),
    );
  }

  final String title;
  final PrimaryFocus primaryFocus;
  final List<PlanAction> actions;
  final String checkInPrompt;
}

class PlanAction {
  PlanAction({required this.title, required this.description});

  factory PlanAction.fromJson(Map<String, dynamic> json) {
    return PlanAction(
      title: _asString(json['title']),
      description: _asString(json['description']),
    );
  }

  final String title;
  final String description;
}

class CoachSnapshot {
  CoachSnapshot({
    required this.coachName,
    required this.intro,
    required this.suggestedPrompts,
  });

  factory CoachSnapshot.fromJson(Map<String, dynamic> json) {
    return CoachSnapshot(
      coachName: _asString(json['coach_name']),
      intro: _asString(json['intro']),
      suggestedPrompts: _asStringList(json['suggested_prompts']),
    );
  }

  final String coachName;
  final String intro;
  final List<String> suggestedPrompts;
}

class ProgressSummary {
  ProgressSummary({
    required this.latestReadingDate,
    required this.latestSnapshot,
    required this.headlineTrends,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      latestReadingDate: _asDateTime(json['latest_reading_date']),
      latestSnapshot: LatestSnapshot.fromJson(_asMap(json['latest_snapshot'])),
      headlineTrends: _asObjectList(
        json['headline_trends'],
        HeadlineTrend.fromJson,
      ),
    );
  }

  final DateTime? latestReadingDate;
  final LatestSnapshot latestSnapshot;
  final List<HeadlineTrend> headlineTrends;
}

class LatestSnapshot {
  LatestSnapshot({
    required this.steps,
    required this.activeMinutes,
    required this.sleepDurationHours,
    required this.sleepQualityScore,
    required this.restingHeartRate,
    required this.hrvRmssd,
  });

  factory LatestSnapshot.fromJson(Map<String, dynamic> json) {
    return LatestSnapshot(
      steps: _asNullableDouble(json['steps']),
      activeMinutes: _asNullableDouble(json['active_minutes']),
      sleepDurationHours: _asNullableDouble(json['sleep_duration_hrs']),
      sleepQualityScore: _asNullableDouble(json['sleep_quality_score']),
      restingHeartRate: _asNullableDouble(json['resting_hr_bpm']),
      hrvRmssd: _asNullableDouble(json['hrv_rmssd_ms']),
    );
  }

  final double? steps;
  final double? activeMinutes;
  final double? sleepDurationHours;
  final double? sleepQualityScore;
  final double? restingHeartRate;
  final double? hrvRmssd;
}

class HeadlineTrend {
  HeadlineTrend({
    required this.id,
    required this.label,
    required this.currentValue,
    required this.baselineValue,
    required this.unit,
    required this.trend,
  });

  factory HeadlineTrend.fromJson(Map<String, dynamic> json) {
    return HeadlineTrend(
      id: _asString(json['id']),
      label: _asString(json['label']),
      currentValue: _asDouble(json['current_value']),
      baselineValue: _asDouble(json['baseline_value']),
      unit: _asString(json['unit']),
      trend: _asString(json['trend']),
    );
  }

  final String id;
  final String label;
  final double currentValue;
  final double baselineValue;
  final String unit;
  final String trend;
}

class AlertSummary {
  AlertSummary({
    required this.totalCount,
    required this.highPriorityCount,
    required this.items,
  });

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      totalCount: _asInt(json['total_count']),
      highPriorityCount: _asInt(json['high_priority_count']),
      items: _asObjectList(json['items'], RiskFlag.fromJson),
    );
  }

  final int totalCount;
  final int highPriorityCount;
  final List<RiskFlag> items;
}

class RiskFlag {
  RiskFlag({
    required this.flagCode,
    required this.severity,
    required this.title,
    required this.rationale,
    required this.recommendedAction,
  });

  factory RiskFlag.fromJson(Map<String, dynamic> json) {
    return RiskFlag(
      flagCode: _asString(json['flag_code']),
      severity: _asString(json['severity']),
      title: _asString(json['title']),
      rationale: _asString(json['rationale']),
      recommendedAction: _asString(json['recommended_action']),
    );
  }

  final String flagCode;
  final String severity;
  final String title;
  final String rationale;
  final String recommendedAction;
}

class OfferSummary {
  OfferSummary({required this.recommended, required this.additionalItems});

  factory OfferSummary.fromJson(Map<String, dynamic> json) {
    final recommendedRaw = json['recommended'];
    return OfferSummary(
      recommended: recommendedRaw is Map<String, dynamic>
          ? OfferOpportunity.fromJson(recommendedRaw)
          : null,
      additionalItems: _asObjectList(
        json['additional_items'],
        OfferOpportunity.fromJson,
      ),
    );
  }

  final OfferOpportunity? recommended;
  final List<OfferOpportunity> additionalItems;
}

class OfferOpportunity {
  OfferOpportunity({
    required this.offerCode,
    required this.offerLabel,
    required this.rationale,
    required this.priority,
    required this.category,
    required this.offerType,
    required this.deliveryModel,
    required this.summary,
    required this.whyNow,
    required this.includes,
    required this.expectedOutcome,
    required this.timeCommitment,
    required this.dataUsed,
    required this.missingData,
    required this.firstWeek,
    required this.caution,
    required this.personalizationNote,
    required this.ctaLabel,
  });

  factory OfferOpportunity.fromJson(Map<String, dynamic> json) {
    return OfferOpportunity(
      offerCode: _asString(json['offer_code']),
      offerLabel: _asString(json['offer_label']),
      rationale: _asString(json['rationale']),
      priority: _asInt(json['priority']),
      category: _asString(json['category']),
      offerType: _asString(json['offer_type']),
      deliveryModel: _asString(json['delivery_model']),
      summary: _asString(json['summary']),
      whyNow: _asString(json['why_now']),
      includes: _asStringList(json['includes']),
      expectedOutcome: _asString(json['expected_outcome']),
      timeCommitment: _asString(json['time_commitment']),
      dataUsed: _asStringList(json['data_used']),
      missingData: _asStringList(json['missing_data']),
      firstWeek: _asStringList(json['first_week']),
      caution: _asString(json['caution']),
      personalizationNote: _asString(json['personalization_note']),
      ctaLabel: _asString(json['cta_label']),
    );
  }

  final String offerCode;
  final String offerLabel;
  final String rationale;
  final int priority;
  final String category;
  final String offerType;
  final String deliveryModel;
  final String summary;
  final String whyNow;
  final List<String> includes;
  final String expectedOutcome;
  final String timeCommitment;
  final List<String> dataUsed;
  final List<String> missingData;
  final List<String> firstWeek;
  final String caution;
  final String personalizationNote;
  final String ctaLabel;

  String get primaryActionLabel {
    if (ctaLabel.isNotEmpty) {
      return ctaLabel;
    }

    switch (offerType) {
      case 'appointment':
      case 'appointment_prep':
        return 'Book visit';
      case 'diagnostic':
        return 'Book test';
      case 'program':
      case 'coaching':
        return 'Start plan';
      case 'supplement':
        return 'Book review';
      case 'starter':
        return 'Start now';
      default:
        return 'See next step';
    }
  }
}

class CustomerProfile {
  CustomerProfile({
    required this.patientId,
    required this.displayName,
    required this.journeyStage,
    required this.journeyTitle,
    required this.journeySummary,
    required this.possibilities,
    required this.dataSources,
    required this.updatedAt,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      patientId: _asString(json['patient_id']),
      displayName: _asString(json['display_name']),
      journeyStage: _asString(json['journey_stage']),
      journeyTitle: _asString(json['journey_title']),
      journeySummary: _asString(json['journey_summary']),
      possibilities: _asStringList(json['possibilities']),
      dataSources: _asObjectList(
        json['data_sources'],
        DataSourceConnection.fromJson,
      ),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  final String patientId;
  final String displayName;
  final String journeyStage;
  final String journeyTitle;
  final String journeySummary;
  final List<String> possibilities;
  final List<DataSourceConnection> dataSources;
  final DateTime? updatedAt;

  bool get isWelcomeJourney => journeyStage == 'welcome';

  int get connectedSourceCount =>
      dataSources.where((source) => source.connected).length;

  List<DataSourceConnection> get connectedSources =>
      dataSources.where((source) => source.connected).toList(growable: false);

  List<DataSourceConnection> get disconnectedSources =>
      dataSources.where((source) => !source.connected).toList(growable: false);

  CustomerProfile copyWith({
    String? patientId,
    String? displayName,
    String? journeyStage,
    String? journeyTitle,
    String? journeySummary,
    List<String>? possibilities,
    List<DataSourceConnection>? dataSources,
    DateTime? updatedAt,
  }) {
    return CustomerProfile(
      patientId: patientId ?? this.patientId,
      displayName: displayName ?? this.displayName,
      journeyStage: journeyStage ?? this.journeyStage,
      journeyTitle: journeyTitle ?? this.journeyTitle,
      journeySummary: journeySummary ?? this.journeySummary,
      possibilities: possibilities ?? this.possibilities,
      dataSources: dataSources ?? this.dataSources,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DataSourceConnection {
  DataSourceConnection({
    required this.sourceId,
    required this.label,
    required this.category,
    required this.connected,
    required this.provider,
    required this.statusText,
    required this.ctaLabel,
  });

  factory DataSourceConnection.fromJson(Map<String, dynamic> json) {
    return DataSourceConnection(
      sourceId: _asString(json['source_id']),
      label: _asString(json['label']),
      category: _asString(json['category']),
      connected: _asBool(json['connected']),
      provider: _asString(json['provider']),
      statusText: _asString(json['status_text']),
      ctaLabel: _asString(json['cta_label']),
    );
  }

  final String sourceId;
  final String label;
  final String category;
  final bool connected;
  final String provider;
  final String statusText;
  final String ctaLabel;

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'label': label,
      'category': category,
      'connected': connected,
      'provider': provider,
      'status_text': statusText,
      'cta_label': ctaLabel,
    };
  }

  DataSourceConnection copyWith({
    String? sourceId,
    String? label,
    String? category,
    bool? connected,
    String? provider,
    String? statusText,
    String? ctaLabel,
  }) {
    return DataSourceConnection(
      sourceId: sourceId ?? this.sourceId,
      label: label ?? this.label,
      category: category ?? this.category,
      connected: connected ?? this.connected,
      provider: provider ?? this.provider,
      statusText: statusText ?? this.statusText,
      ctaLabel: ctaLabel ?? this.ctaLabel,
    );
  }
}

class SupportBooking {
  SupportBooking({
    required this.bookingId,
    required this.patientId,
    required this.offerCode,
    required this.offerLabel,
    required this.offerType,
    required this.deliveryModel,
    required this.status,
    required this.scheduledFor,
    required this.scheduledLabel,
    required this.createdAt,
  });

  factory SupportBooking.fromJson(Map<String, dynamic> json) {
    return SupportBooking(
      bookingId: _asString(json['booking_id']),
      patientId: _asString(json['patient_id']),
      offerCode: _asString(json['offer_code']),
      offerLabel: _asString(json['offer_label']),
      offerType: _asString(json['offer_type']),
      deliveryModel: _asString(json['delivery_model']),
      status: _asString(json['status']),
      scheduledFor: _asDateTime(json['scheduled_for']),
      scheduledLabel: _asString(json['scheduled_label']),
      createdAt: _asDateTime(json['created_at']),
    );
  }

  final String bookingId;
  final String patientId;
  final String offerCode;
  final String offerLabel;
  final String offerType;
  final String deliveryModel;
  final String status;
  final DateTime? scheduledFor;
  final String scheduledLabel;
  final DateTime? createdAt;

  bool get isBooked => status == 'booked';
}

class CoachReply {
  CoachReply({required this.reply, required this.primaryFocus});

  factory CoachReply.fromJson(Map<String, dynamic> json) {
    return CoachReply(
      reply: _asString(json['reply']),
      primaryFocus: PrimaryFocus.fromJson(_asMap(json['primary_focus'])),
    );
  }

  final String reply;
  final PrimaryFocus primaryFocus;
}

class ChatMessage {
  ChatMessage({required this.role, required this.text});

  factory ChatMessage.assistant(String text) {
    return ChatMessage(role: 'assistant', text: text);
  }

  factory ChatMessage.user(String text) {
    return ChatMessage(role: 'user', text: text);
  }

  final String role;
  final String text;

  bool get isUser => role == 'user';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<T> _asObjectList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) builder,
) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(builder)
      .toList(growable: false);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value.map((item) => item.toString()).toList(growable: false);
}

String _asString(dynamic value) => value?.toString() ?? '';

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
