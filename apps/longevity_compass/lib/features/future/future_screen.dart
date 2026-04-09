import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../core/models/experience_models.dart';
import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final experience = controller.experience;
        if (controller.isLoading && experience == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (experience == null) {
          return EmptyStateCard(
            title: 'Future view unavailable',
            body: controller.errorMessage ??
                'The future page needs a live patient experience before it can render.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final milestones = _buildMilestones(experience);
        final supportItems = [
          if (experience.offers.recommended != null)
            experience.offers.recommended!,
          ...experience.offers.additionalItems.take(2),
        ];
        final highlights = _buildProjectionHighlights(experience);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
          children: [
            const ScreenHeader(
              eyebrow: 'Future',
              title:
                  'See the next chapter before it turns into too many choices.',
              subtitle:
                  'This page turns the live recovery context into a clearer sequence: what to do now, what to track next, and where extra support actually fits.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Direction from here',
              subtitle:
                  'A forward-looking read should feel grounded in your current signals, not magical.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DirectionBadge(experience.compass.overallDirection),
                  const SizedBox(height: 16),
                  Text(
                    _projectionBody(experience),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'This week in motion',
              subtitle: experience.weeklyPlan.primaryFocus.whyNow,
              child: Column(
                children: [
                  for (var index = 0;
                      index < experience.weeklyPlan.actions.length;
                      index++) ...[
                    ActionTile(
                      index: index + 1,
                      action: experience.weeklyPlan.actions[index],
                    ),
                    if (index < experience.weeklyPlan.actions.length - 1)
                      const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.mint.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      experience.weeklyPlan.checkInPrompt,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Upcoming milestones',
              subtitle:
                  'The next page in the journey should feel concrete: habits, follow-up, and better signal collection.',
              child: Column(
                children: [
                  for (var index = 0; index < milestones.length; index++)
                    _FutureMilestoneTile(
                      milestone: milestones[index],
                      isLast: index == milestones.length - 1,
                    ),
                ],
              ),
            ),
            if (supportItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Support that may matter next',
                subtitle:
                    'Support should stay relevant to the next step, not interrupt it.',
                child: Column(
                  children: [
                    for (var index = 0;
                        index < supportItems.length;
                        index++) ...[
                      OfferTile(
                        offer: supportItems[index],
                        highlight: index == 0,
                      ),
                      if (index < supportItems.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionSurface(
              title: _projectionHeadline(experience),
              subtitle:
                  'A useful projection is directional, transparent, and still actionable.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _projectionBody(experience),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  for (var index = 0; index < highlights.length; index++) ...[
                    _ProjectionHighlight(text: highlights[index]),
                    if (index < highlights.length - 1)
                      const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _FutureStatCard(
                        label: 'Latest wearable date',
                        value: formatDateTime(
                          experience.progressSummary.latestReadingDate,
                        ),
                      ),
                      _FutureStatCard(
                        label: 'Age gap',
                        value: experience.profileSummary.ageGapYears == null
                            ? 'n/a'
                            : '${experience.profileSummary.ageGapYears!.toStringAsFixed(1)}y',
                      ),
                      _FutureStatCard(
                        label: 'Primary focus',
                        value: experience.compass.primaryFocus.pillarName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

List<_FutureMilestone> _buildMilestones(ExperienceSnapshot experience) {
  final milestones = <_FutureMilestone>[];
  final actions = experience.weeklyPlan.actions;

  if (actions.isNotEmpty) {
    milestones.add(
      _FutureMilestone(
        whenLabel: 'Today',
        title: actions.first.title,
        detail: actions.first.description,
        isOptional: false,
        accent: AppPalette.forest,
      ),
    );
  }

  if (actions.length > 1) {
    milestones.add(
      _FutureMilestone(
        whenLabel: 'This week',
        title: actions[1].title,
        detail: actions[1].description,
        isOptional: false,
        accent: AppPalette.moss,
      ),
    );
  }

  if (experience.dataCoverage.needsMealTracking) {
    milestones.add(
      const _FutureMilestone(
        whenLabel: 'Next 7 days',
        title: 'Meal tracking starter',
        detail:
            'Log one meal a day so the app can move from broad nutrition advice to something more personal.',
        isOptional: false,
        accent: AppPalette.amber,
      ),
    );
  }

  milestones.add(
    _FutureMilestone(
      whenLabel: 'Before next visit',
      title: experience.careContext.lastAppointmentTitle,
      detail: experience.careContext.lastAppointmentSummary,
      isOptional: true,
      accent: AppPalette.ink.withValues(alpha: 0.34),
    ),
  );

  final recommended = experience.offers.recommended;
  if (recommended != null) {
    milestones.add(
      _FutureMilestone(
        whenLabel: 'If more support is needed',
        title: recommended.offerLabel,
        detail: recommended.summary,
        isOptional: true,
        accent: AppPalette.coral,
      ),
    );
  }

  return milestones.take(5).toList(growable: false);
}

String _projectionHeadline(ExperienceSnapshot experience) {
  switch (experience.compass.overallDirection) {
    case 'drifting':
      return 'The next month can still bend back toward recovery.';
    case 'on_track':
      return 'The next month is about protecting momentum, not overcomplicating it.';
    default:
      return 'The next month should make the good signals easier to repeat.';
  }
}

String _projectionBody(ExperienceSnapshot experience) {
  final focus = experience.compass.primaryFocus.pillarName.toLowerCase();
  return 'Right now, the clearest way to improve the next chapter is to keep '
      '$focus consistent enough that it becomes a repeatable habit, not just a good week. '
      '${experience.dataCoverage.tailoringNote}';
}

List<String> _buildProjectionHighlights(ExperienceSnapshot experience) {
  final highlights = <String>[
    'The watch can already show whether recovery is stabilizing or slipping between weeks.',
    'Using the coach before the next appointment should make the clinical follow-up clearer, not more intimidating.',
  ];

  if (experience.dataCoverage.needsMealTracking) {
    highlights.add(
      'A week of meal tracking is the fastest way to make the next nutrition recommendation feel genuinely tailored.',
    );
  }

  if (experience.offers.recommended != null) {
    highlights.add(
      'If extra support is still needed, ${experience.offers.recommended!.offerLabel.toLowerCase()} is the most relevant next escalation.',
    );
  }

  return highlights.take(4).toList(growable: false);
}

class _FutureMilestone {
  const _FutureMilestone({
    required this.whenLabel,
    required this.title,
    required this.detail,
    required this.isOptional,
    required this.accent,
  });

  final String whenLabel;
  final String title;
  final String detail;
  final bool isOptional;
  final Color accent;
}

class _FutureMilestoneTile extends StatelessWidget {
  const _FutureMilestoneTile({
    required this.milestone,
    required this.isLast,
  });

  final _FutureMilestone milestone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final borderColor = milestone.isOptional
        ? AppPalette.ink.withValues(alpha: 0.18)
        : AppPalette.ink.withValues(alpha: 0.06);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: milestone.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: milestone.accent.withValues(alpha: 0.26),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: milestone.isOptional
                      ? Colors.white.withValues(alpha: 0.58)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.whenLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppPalette.ink.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      milestone.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      milestone.detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.ink.withValues(alpha: 0.7),
                            height: 1.42,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionHighlight extends StatelessWidget {
  const _ProjectionHighlight({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 8,
            color: AppPalette.forest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.42,
                ),
          ),
        ),
      ],
    );
  }
}

class _FutureStatCard extends StatelessWidget {
  const _FutureStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.62),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
