import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../widgets/compass_components.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.experience == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.experience == null) {
          return EmptyStateCard(
            title: 'Compass unavailable',
            body: controller.errorMessage ??
                'The app could not load a patient experience yet.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final experience = controller.experience!;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const ScreenHeader(
                eyebrow: 'Today',
                title: 'Keep this week simple.',
                subtitle:
                    'See where you stand, the one goal for this week, and the few signals that matter most.',
              ),
              const SizedBox(height: 24),
              if (experience.compass.peerComparison.hasItems) ...[
                CompassRadarCard(experience: experience),
                const SizedBox(height: 24),
              ],
              CompassHeroCard(experience: experience),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'This week\'s focus',
                subtitle:
                    'Start with the smallest set of actions that can actually move the week forward.',
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
                    if (experience.weeklyPlan.checkInPrompt.isNotEmpty) ...[
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppPalette.ink,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'What informs the plan',
                subtitle:
                    'Doctor context, watch data, and one clear next input keep this grounded.',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 900;
                    final cards = [
                      _DashboardDetailCard(
                        title: 'From your last appointment',
                        body: experience.careContext.lastAppointmentSummary,
                        tagsTitle: 'Medications on file',
                        tags: experience.careContext.medications,
                        listTitle: 'Priorities now',
                        listItems: experience.careContext.clinicalPriorities
                            .take(3)
                            .toList(growable: false),
                        footer: experience.careContext.medicalGuardrail,
                        footerColor: AppPalette.sand.withValues(alpha: 0.92),
                      ),
                      _DashboardDetailCard(
                        title: 'To personalize next',
                        body: experience.dataCoverage.headline,
                        tagsTitle: 'Already connected',
                        tags: experience.dataCoverage.connectedSources
                            .take(3)
                            .toList(growable: false),
                        listTitle: 'Still missing',
                        listItems: experience.dataCoverage.missingSources
                            .take(3)
                            .toList(growable: false),
                        footer: experience.dataCoverage.tailoringNote,
                      ),
                    ];

                    if (stacked) {
                      return Column(
                        children: [
                          for (var index = 0;
                              index < cards.length;
                              index++) ...[
                            cards[index],
                            if (index < cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          Expanded(child: cards[index]),
                          if (index < cards.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (experience.progressSummary.headlineTrends.isNotEmpty)
                SectionSurface(
                  title: 'Recent watch signals',
                  subtitle:
                      'Use these as a quick recovery read, not as another thing to overthink.',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 760;
                      final trends = experience.progressSummary.headlineTrends
                          .take(3)
                          .toList(growable: false);
                      final children = trends
                          .map(
                            (trend) =>
                                Expanded(child: MetricTrendTile(trend: trend)),
                          )
                          .toList(growable: false);

                      if (stacked) {
                        return Column(
                          children: trends
                              .map(
                                (trend) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MetricTrendTile(trend: trend),
                                ),
                              )
                              .toList(growable: false),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var index = 0;
                              index < children.length;
                              index++) ...[
                            if (index > 0) const SizedBox(width: 12),
                            children[index],
                          ],
                        ],
                      );
                    },
                  ),
                ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 18),
                Text(
                  controller.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.wine,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DashboardDetailCard extends StatelessWidget {
  const _DashboardDetailCard({
    required this.title,
    required this.body,
    this.tagsTitle,
    this.tags = const <String>[],
    this.listTitle,
    this.listItems = const <String>[],
    this.footer,
    this.footerColor,
  });

  final String title;
  final String body;
  final String? tagsTitle;
  final List<String> tags;
  final String? listTitle;
  final List<String> listItems;
  final String? footer;
  final Color? footerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.76),
                  height: 1.45,
                ),
          ),
          if (tagsTitle != null && tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoTagWrap(title: tagsTitle!, items: tags),
          ],
          if (listTitle != null && listItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BulletList(title: listTitle!, items: listItems),
          ],
          if (footer != null && footer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: footerColor ?? AppPalette.mint.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                footer!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTagWrap extends StatelessWidget {
  const _InfoTagWrap({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.ink,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(item),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.ink,
              ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < items.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 8, color: AppPalette.forest),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.76),
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ),
          if (index < items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
