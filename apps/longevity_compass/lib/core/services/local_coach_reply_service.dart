import '../models/experience_models.dart';

class LocalCoachReplyService {
  const LocalCoachReplyService();

  CoachReply buildReply({
    required ExperienceSnapshot experience,
    required String message,
    CustomerProfile? customerProfile,
    List<SupportBooking> supportBookings = const [],
  }) {
    final focus = experience.weeklyPlan.primaryFocus;
    final care = experience.careContext;
    final dataCoverage = experience.dataCoverage;
    final lowerMessage = message.toLowerCase();
    final firstAction = experience.weeklyPlan.actions.isNotEmpty
        ? experience.weeklyPlan.actions.first.title
        : 'follow this week\'s plan';
    final recommendedOffer = experience.offers.recommended;
    final signalSummary = _buildSignalSummary(experience);
    final isWelcomeJourney = customerProfile?.isWelcomeJourney ?? false;
    final nextBooking =
        supportBookings.isNotEmpty ? supportBookings.first : null;

    var reply =
        'The clearest focus right now is ${focus.pillarName.toLowerCase()}. '
        '${focus.whyNow} '
        'This week, start with $firstAction.';

    if (isWelcomeJourney) {
      reply =
          'You are still in the setup stage, so the best next step is to keep this simple. '
          'Connect one useful source, tell me what outcome matters most to you, and I can guide you from there.';

      if (_containsAny(lowerMessage, const [
        'what can you do',
        'help',
        'start',
        'new here',
      ])) {
        reply =
            'I can help you choose the first data source to connect, explain what each clinic offer is for, and keep the first week simple. '
            'A smartwatch or your last doctor summary is usually enough to get started.';
      } else if (_containsAny(lowerMessage, const [
        'watch',
        'wearable',
        'connect',
        'data source',
      ])) {
        reply =
            'The fastest first connection is usually a smartwatch or ring because it starts showing sleep, movement, and recovery trends quickly. '
            'If you already have active medical care, adding your last doctor summary is the next best thing.';
      } else if (_containsAny(lowerMessage, const [
        'book',
        'visit',
        'screening',
        'intake',
        'lab',
      ])) {
        if (nextBooking != null) {
          reply =
              'You already booked ${nextBooking.offerLabel} for ${nextBooking.scheduledLabel}. '
              'That means the smartest next step is to connect one useful source before that appointment if you can.';
        } else if (recommendedOffer != null) {
          reply =
              'The clearest first support option is ${recommendedOffer.offerLabel}. '
              '${recommendedOffer.summary}';
        }
      }

      return CoachReply(reply: reply.trim(), primaryFocus: focus);
    }

    if (_containsAny(lowerMessage, const [
      'summarize',
      'what do you know',
      'what you know',
      'know about me',
      'context',
    ])) {
      reply =
          'I already have your doctor context and your watch trends on file. '
          '${care.lastAppointmentSummary} '
          'Right now, ${focus.pillarName.toLowerCase()} is the main focus.'
          '${dataCoverage.needsMealTracking ? ' Nutrition can get more specific later with a little meal logging.' : ''}';
    } else if (_containsAny(lowerMessage, const [
      'doctor',
      'appointment',
      'visit',
      'clinician',
    ])) {
      reply = '${care.lastAppointmentSummary} '
          'Right now, the main priorities are ${_joinPhrases(care.clinicalPriorities, limit: 2)}. '
          '${care.medicalGuardrail}';
    } else if (_containsAny(lowerMessage, const [
      'heart attack',
      'heart event',
      'cardiac',
      'heart problem',
    ])) {
      reply =
          'If you recently had a heart attack or another serious heart event, '
          'this app should support your clinician\'s recovery plan, not replace it. '
          '${care.lastAppointmentSummary} '
          'For this week, keep the goal simple: ${focus.pillarName.toLowerCase()}. '
          'Start with $firstAction, and use your watch trends to see whether recovery is settling in the right direction.';
    } else if (_containsAny(lowerMessage, const [
      'meal',
      'food',
      'nutrition',
      'eat',
      'eating',
    ])) {
      reply = '${dataCoverage.tailoringNote} '
          'Right now I do not have meaningful meal logging, so nutrition advice stays broad. '
          'Log one meal a day for the next 7 days and I can tailor that part much better.';
    } else if (_containsAny(lowerMessage, const [
      'support',
      'offer',
      'clinic',
      'program',
      'book',
      'supplement',
    ])) {
      if (recommendedOffer != null) {
        reply =
            'The best next support option right now is ${recommendedOffer.offerLabel}. '
            '${recommendedOffer.summary} '
            '${recommendedOffer.whyNow} '
            '${recommendedOffer.missingData.isNotEmpty ? 'To tailor it further, ${recommendedOffer.missingData.first}.' : ''}';
      }
    } else if (_containsAny(lowerMessage, const [
      'week',
      'plan',
      'next step',
      'focus',
      'this week',
    ])) {
      reply = 'Keep this week achievable. '
          '${_buildPlanSummary(experience.weeklyPlan.actions)} '
          '${signalSummary.isNotEmpty ? '$signalSummary ' : ''}';
    } else if (signalSummary.isNotEmpty) {
      reply = '$reply $signalSummary';
    }

    return CoachReply(
      reply: reply.trim(),
      primaryFocus: focus,
    );
  }
}

bool _containsAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) {
      return true;
    }
  }
  return false;
}

String _buildPlanSummary(List<PlanAction> actions) {
  if (actions.isEmpty) {
    return 'Start with one small repeatable action, then build from there.';
  }
  if (actions.length == 1) {
    return 'Start with ${actions.first.title}.';
  }

  final first = actions.first.title;
  final second = actions[1].title;
  return 'Start with $first, then move to $second.';
}

String _buildSignalSummary(ExperienceSnapshot experience) {
  final trends = experience.progressSummary.headlineTrends.take(2).toList();
  if (trends.isEmpty) {
    return '';
  }

  final parts = trends
      .map((trend) =>
          '${trend.label.toLowerCase()} is ${_trendPhrase(trend.trend)}')
      .toList(growable: false);
  return 'From your watch, ${_joinPhrases(parts)}.';
}

String _trendPhrase(String trend) {
  switch (trend) {
    case 'improving':
      return 'moving in the right direction';
    case 'drifting':
      return 'slipping versus your recent baseline';
    default:
      return 'holding steady';
  }
}

String _joinPhrases(List<String> items, {int? limit}) {
  final values =
      limit == null ? items : items.take(limit).toList(growable: false);
  if (values.isEmpty) {
    return 'the current plan';
  }
  if (values.length == 1) {
    return values.first;
  }
  if (values.length == 2) {
    return '${values.first} and ${values.last}';
  }

  final head = values.take(values.length - 1).join(', ');
  return '$head, and ${values.last}';
}
