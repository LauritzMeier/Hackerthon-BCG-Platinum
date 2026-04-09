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
      estimatedBiologicalAge: _asNullableDouble(json['estimated_biological_age']),
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
      progressSummary: ProgressSummary.fromJson(_asMap(json['progress_summary'])),
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
  final ProgressSummary progressSummary;
  final AlertSummary alerts;
  final OfferSummary offers;
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
      estimatedBiologicalAge: _asNullableDouble(json['estimated_biological_age']),
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
    required this.suggestedQuestions,
  });

  factory CompassSnapshot.fromJson(Map<String, dynamic> json) {
    return CompassSnapshot(
      overallDirection: _asString(json['overall_direction']),
      chronologicalAge: _asInt(json['chronological_age']),
      estimatedBiologicalAge: _asNullableDouble(json['estimated_biological_age']),
      primaryFocus: PrimaryFocus.fromJson(_asMap(json['primary_focus'])),
      pillars: _asObjectList(json['pillars'], PillarSnapshot.fromJson),
      suggestedQuestions:
          _asStringList(json['suggested_questions']),
    );
  }

  final String overallDirection;
  final int chronologicalAge;
  final double? estimatedBiologicalAge;
  final PrimaryFocus primaryFocus;
  final List<PillarSnapshot> pillars;
  final List<String> suggestedQuestions;
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
    required this.state,
    required this.trend,
    required this.whyItMatters,
  });

  factory PillarSnapshot.fromJson(Map<String, dynamic> json) {
    return PillarSnapshot(
      id: _asString(json['id']),
      name: _asString(json['name']),
      score: _asDouble(json['score']),
      state: _asString(json['state']),
      trend: _asString(json['trend']),
      whyItMatters: _asString(json['why_it_matters']),
    );
  }

  final String id;
  final String name;
  final double score;
  final String state;
  final String trend;
  final String whyItMatters;
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
  PlanAction({
    required this.title,
    required this.description,
  });

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
      headlineTrends: _asObjectList(json['headline_trends'], HeadlineTrend.fromJson),
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
  OfferSummary({
    required this.recommended,
    required this.additionalItems,
  });

  factory OfferSummary.fromJson(Map<String, dynamic> json) {
    final recommendedRaw = json['recommended'];
    return OfferSummary(
      recommended: recommendedRaw is Map<String, dynamic>
          ? OfferOpportunity.fromJson(recommendedRaw)
          : null,
      additionalItems:
          _asObjectList(json['additional_items'], OfferOpportunity.fromJson),
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
  });

  factory OfferOpportunity.fromJson(Map<String, dynamic> json) {
    return OfferOpportunity(
      offerCode: _asString(json['offer_code']),
      offerLabel: _asString(json['offer_label']),
      rationale: _asString(json['rationale']),
      priority: _asInt(json['priority']),
    );
  }

  final String offerCode;
  final String offerLabel;
  final String rationale;
  final int priority;
}

class CoachReply {
  CoachReply({
    required this.reply,
    required this.primaryFocus,
  });

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
  ChatMessage({
    required this.role,
    required this.text,
  });

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

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
