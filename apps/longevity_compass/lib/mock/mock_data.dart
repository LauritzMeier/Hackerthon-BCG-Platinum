import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class CompassMetric {
  const CompassMetric({
    required this.id,
    required this.label,
    required this.displayValue,
    required this.deltaLabel,
    required this.axisValue,
    required this.unit,
    required this.story,
    required this.accent,
    required this.historyValues,
    required this.historyLabels,
    required this.impacts,
  });

  final String id;
  final String label;
  final String displayValue;
  final String deltaLabel;
  final double axisValue;
  final String unit;
  final String story;
  final Color accent;
  final List<double> historyValues;
  final List<String> historyLabels;
  final List<MetricImpact> impacts;
}

class MetricImpact {
  const MetricImpact({
    required this.title,
    required this.detail,
    required this.effectLabel,
    required this.whenLabel,
    required this.positive,
  });

  final String title;
  final String detail;
  final String effectLabel;
  final String whenLabel;
  final bool positive;
}

class MockConversation {
  const MockConversation({
    required this.id,
    required this.label,
    required this.preview,
    required this.updatedLabel,
    required this.messages,
  });

  final String id;
  final String label;
  final String preview;
  final String updatedLabel;
  final List<MockMessage> messages;

  MockConversation copyWith({
    String? id,
    String? label,
    String? preview,
    String? updatedLabel,
    List<MockMessage>? messages,
  }) {
    return MockConversation(
      id: id ?? this.id,
      label: label ?? this.label,
      preview: preview ?? this.preview,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      messages: messages ?? this.messages,
    );
  }
}

class MockMessage {
  const MockMessage({
    required this.text,
    required this.timeLabel,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final String timeLabel;
  final bool isUser;
  final bool isError;

  MockMessage copyWith({
    String? text,
    String? timeLabel,
    bool? isUser,
    bool? isError,
  }) {
    return MockMessage(
      text: text ?? this.text,
      timeLabel: timeLabel ?? this.timeLabel,
      isUser: isUser ?? this.isUser,
      isError: isError ?? this.isError,
    );
  }
}

class FutureTimelineEntry {
  const FutureTimelineEntry({
    required this.whenLabel,
    required this.title,
    required this.detail,
    required this.tag,
    required this.isOptional,
    this.ctaLabel,
  });

  final String whenLabel;
  final String title;
  final String detail;
  final String tag;
  final bool isOptional;
  final String? ctaLabel;
}

class FutureProjection {
  const FutureProjection({
    required this.headline,
    required this.body,
    required this.highlights,
  });

  final String headline;
  final String body;
  final List<String> highlights;
}

const compassMetrics = <CompassMetric>[
  CompassMetric(
    id: 'bio_age',
    label: 'Bio-Age',
    displayValue: '38.7y',
    deltaLabel: '-3.1y vs Jan',
    axisValue: 0.82,
    unit: 'years',
    story:
        'Your biological age line is moving down because recovery, sleep regularity, and cardio load have become more consistent than the winter baseline.',
    accent: AppPalette.forest,
    historyValues: [41.8, 41.2, 40.7, 40.0, 39.4, 38.7],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Evening recovery walk',
        detail:
            'Three low-intensity walks after dinner improved glucose control and sleep onset.',
        effectLabel: '+0.9y younger',
        whenLabel: '2 weeks ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Red-eye travel week',
        detail:
            'Jet lag and missed meals pushed inflammation markers back up for a few days.',
        effectLabel: '+0.4y older',
        whenLabel: '18 days ago',
        positive: false,
      ),
      MetricImpact(
        title: 'Strength block restart',
        detail:
            'Two lighter strength sessions stabilized resting heart rate and morning energy.',
        effectLabel: '+0.6y younger',
        whenLabel: '1 month ago',
        positive: true,
      ),
    ],
  ),
  CompassMetric(
    id: 'cardio_age',
    label: 'Cardiovascular Age',
    displayValue: '34.8y',
    deltaLabel: '-2.0y in 6 weeks',
    axisValue: 0.76,
    unit: 'years',
    story:
        'Cardiovascular age is trending down because weekly aerobic volume is finally staying high enough to translate into real recovery gains.',
    accent: AppPalette.moss,
    historyValues: [36.8, 36.2, 35.9, 35.5, 35.1, 34.8],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Zone 2 Saturday run',
        detail:
            'The longer aerobic session improved VO2 response without adding much fatigue.',
        effectLabel: '+1.3y younger',
        whenLabel: '5 days ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Skipped cardio block',
        detail:
            'Three missed sessions created a noticeable dip in endurance continuity.',
        effectLabel: '+0.5y older',
        whenLabel: '3 weeks ago',
        positive: false,
      ),
      MetricImpact(
        title: 'Preventive check-up booked',
        detail:
            'The plan now includes a formal blood pressure and lipid review.',
        effectLabel: '+confidence',
        whenLabel: 'Today',
        positive: true,
      ),
    ],
  ),
  CompassMetric(
    id: 'sleep',
    label: 'Sleep',
    displayValue: '7.5h',
    deltaLabel: '+0.8h nightly',
    axisValue: 0.69,
    unit: 'hours',
    story:
        'Sleep is still the easiest lever to improve further. The line has turned upward, but weekend inconsistency is still visible in the variance.',
    accent: AppPalette.amber,
    historyValues: [6.4, 6.7, 6.9, 7.1, 7.3, 7.5],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Bedroom cooldown ritual',
        detail:
            'Cooler room temperature and a fixed wind-down cut sleep latency sharply.',
        effectLabel: '+0.7h',
        whenLabel: '6 days ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Late caffeine sprint',
        detail:
            'One high-pressure workday pushed caffeine too late into the evening.',
        effectLabel: '-0.4h',
        whenLabel: '11 days ago',
        positive: false,
      ),
      MetricImpact(
        title: 'Sleep lab recommendation',
        detail:
            'A formal check-up is suggested because better sleep could unlock multiple other scores.',
        effectLabel: '+recommended',
        whenLabel: 'Upcoming',
        positive: true,
      ),
    ],
  ),
  CompassMetric(
    id: 'recovery',
    label: 'Recovery',
    displayValue: '67 ms',
    deltaLabel: '+8 ms HRV',
    axisValue: 0.72,
    unit: 'ms',
    story:
        'Recovery is no longer flat. Better sleep timing and lower training spikes are creating a smoother upward trend across the last month.',
    accent: AppPalette.mint,
    historyValues: [58, 59, 60, 62, 65, 67],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Deload week',
        detail:
            'Dropping intensity for four sessions allowed heart-rate variability to rebound.',
        effectLabel: '+6 ms',
        whenLabel: '1 week ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Two consecutive late nights',
        detail:
            'Short sleep immediately showed up in the morning recovery snapshot.',
        effectLabel: '-3 ms',
        whenLabel: '16 days ago',
        positive: false,
      ),
    ],
  ),
  CompassMetric(
    id: 'activity',
    label: 'Activity',
    displayValue: '4.5x',
    deltaLabel: '+2 sessions',
    axisValue: 0.74,
    unit: 'sessions',
    story:
        'Activity is now frequent enough to support the other systems. The main challenge is keeping the cadence steady during travel weeks.',
    accent: AppPalette.coral,
    historyValues: [2.0, 2.4, 3.0, 3.7, 4.1, 4.5],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Run club every Wednesday',
        detail:
            'A recurring social slot removed friction from the weekly exercise plan.',
        effectLabel: '+1.0 session',
        whenLabel: '2 weeks ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Client travel',
        detail:
            'A compressed schedule eliminated two planned strength sessions.',
        effectLabel: '-0.6 session',
        whenLabel: '1 month ago',
        positive: false,
      ),
    ],
  ),
  CompassMetric(
    id: 'stress',
    label: 'Stress Load',
    displayValue: '23 pts',
    deltaLabel: '-9 pts',
    axisValue: 0.65,
    unit: 'points',
    story:
        'Stress load is calmer than the baseline, but the dips still depend too much on protected recovery blocks and not enough on daily habits.',
    accent: AppPalette.wine,
    historyValues: [32, 30, 29, 27, 25, 23],
    historyLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    impacts: [
      MetricImpact(
        title: 'Morning breathing reset',
        detail:
            'A short breathing sequence reduced high-alert mornings across the workweek.',
        effectLabel: '-4 pts',
        whenLabel: '4 days ago',
        positive: true,
      ),
      MetricImpact(
        title: 'Deadline cluster',
        detail:
            'A compressed product sprint caused a temporary stress spike and worse sleep.',
        effectLabel: '+5 pts',
        whenLabel: '12 days ago',
        positive: false,
      ),
    ],
  ),
];

const seedConversations = <MockConversation>[
  MockConversation(
    id: 'sleep',
    label: 'Sleep drift',
    preview: 'Why is sleep still the weakest signal?',
    updatedLabel: '3m ago',
    messages: [
      MockMessage(
        text:
            'Why is sleep still the weakest signal if the overall trend is improving?',
        timeLabel: '09:14',
        isUser: true,
      ),
      MockMessage(
        text:
            'The mockup suggests that weekend inconsistency is still creating a gap between good nights and repeatable nights. Sleep duration is up, but regularity is not fully locked in yet.',
        timeLabel: '09:14',
        isUser: false,
      ),
      MockMessage(
        text: 'What would move it fastest over the next two weeks?',
        timeLabel: '09:15',
        isUser: true,
      ),
      MockMessage(
        text:
            'A tighter bedtime window plus the recommended sleep lab screening would likely create the clearest change, especially because the dashboard links sleep to recovery and bio-age together.',
        timeLabel: '09:15',
        isUser: false,
      ),
    ],
  ),
  MockConversation(
    id: 'cardio',
    label: 'Cardio next step',
    preview: 'How do I keep cardiovascular age moving down?',
    updatedLabel: 'Yesterday',
    messages: [
      MockMessage(
        text:
            'How do I keep cardiovascular age moving down without overtraining?',
        timeLabel: '18:42',
        isUser: true,
      ),
      MockMessage(
        text:
            'The mock plan would keep one longer zone-2 session, one shorter interval session, and leave more room for recovery after travel days. The goal is consistency, not intensity spikes.',
        timeLabel: '18:42',
        isUser: false,
      ),
      MockMessage(
        text:
            'Should the preventive check-up happen before increasing training volume?',
        timeLabel: '18:44',
        isUser: true,
      ),
      MockMessage(
        text:
            'Yes. The check-up is treated as a confidence unlock in this concept, because it clarifies blood pressure and lipid context before pushing harder.',
        timeLabel: '18:44',
        isUser: false,
      ),
    ],
  ),
  MockConversation(
    id: 'future',
    label: 'Future self',
    preview: 'What does the 10-year projection assume?',
    updatedLabel: '2d ago',
    messages: [
      MockMessage(
        text: 'What does the 10-year projection actually assume?',
        timeLabel: '11:02',
        isUser: true,
      ),
      MockMessage(
        text:
            'It assumes the upcoming goals keep stacking: regular aerobic work, stronger sleep consistency, and the recommended appointments getting converted from optional to booked.',
        timeLabel: '11:02',
        isUser: false,
      ),
      MockMessage(
        text: 'So it is more of a trajectory than a promise?',
        timeLabel: '11:03',
        isUser: true,
      ),
      MockMessage(
        text:
            'Exactly. The visualization is meant to feel motivating and concrete, while still being transparent that it depends on the actions shown in the timeline.',
        timeLabel: '11:03',
        isUser: false,
      ),
    ],
  ),
];

const futureTimeline = <FutureTimelineEntry>[
  FutureTimelineEntry(
    whenLabel: 'Today',
    title: 'Morning mobility + hydration',
    detail:
        'Keep today light so sleep and recovery stay stable after the stronger cardio block.',
    tag: 'anchor',
    isOptional: false,
  ),
  FutureTimelineEntry(
    whenLabel: '14 May',
    title: 'Run club on the river loop',
    detail:
        'An easy aerobic session that mainly keeps your weekly rhythm intact.',
    tag: 'activity',
    isOptional: false,
  ),
  FutureTimelineEntry(
    whenLabel: '02 Jun',
    title: 'Sleep lab screening',
    detail:
        'Recommended because sleep still caps progress across recovery and bio-age.',
    tag: 'recommended',
    isOptional: true,
    ctaLabel: 'Book Now',
  ),
  FutureTimelineEntry(
    whenLabel: '18 Jun',
    title: 'Preventive cardio check-up',
    detail:
        'Suggested before raising training load again so the plan stays confident, not guessy.',
    tag: 'doctor',
    isOptional: true,
    ctaLabel: 'Book Now',
  ),
  FutureTimelineEntry(
    whenLabel: '01 Jul',
    title: 'VO2 max field test',
    detail:
        'A progress marker to compare against the current dashboard snapshot and coach discussions.',
    tag: 'milestone',
    isOptional: false,
  ),
];

const futureProjection = FutureProjection(
  headline: 'Me in 10 Years',
  body:
      'If the upcoming goals turn into a habit loop, this concept projects a version of you that moves well, recovers faster, and still has enough reserve for ambitious years ahead.',
  highlights: [
    'Weekend mountain hikes without needing long recovery',
    'Cardiovascular age still below chronological age',
    'Sleep consistency strong enough to protect energy during intense work weeks',
  ],
);

CompassMetric metricById(String id) {
  return compassMetrics.firstWhere((metric) => metric.id == id);
}
