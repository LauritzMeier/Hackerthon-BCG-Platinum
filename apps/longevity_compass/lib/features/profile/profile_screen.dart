import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            title: 'Profile unavailable',
            body: controller.errorMessage ??
                'The profile needs the Compass payload before it can render.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final profile = experience.profileSummary;
        final latest = experience.progressSummary.latestSnapshot;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const ScreenHeader(
              eyebrow: 'Profile And Progress',
              title: 'The trust layer behind the Compass.',
              subtitle:
                  'Recent wearable signals, core patient context, and alerts that explain why the experience looks the way it does.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Profile summary',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Patient ID', value: profile.patientId),
                  _StatCard(label: 'Country', value: profile.country),
                  _StatCard(label: 'Age', value: '${profile.age}'),
                  _StatCard(label: 'Sex', value: profile.sex),
                  _StatCard(
                    label: 'Biological age',
                    value: profile.estimatedBiologicalAge == null
                        ? 'n/a'
                        : profile.estimatedBiologicalAge!.toStringAsFixed(1),
                  ),
                  _StatCard(
                    label: 'Age gap',
                    value: profile.ageGapYears == null
                        ? 'n/a'
                        : profile.ageGapYears!.toStringAsFixed(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Latest wearable snapshot',
              subtitle:
                  'Most recent reading date: ${formatDateTime(experience.progressSummary.latestReadingDate)}',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'Steps',
                    value: latest.steps == null
                        ? 'n/a'
                        : latest.steps!.toStringAsFixed(0),
                  ),
                  _StatCard(
                    label: 'Active minutes',
                    value: latest.activeMinutes == null
                        ? 'n/a'
                        : latest.activeMinutes!.toStringAsFixed(0),
                  ),
                  _StatCard(
                    label: 'Sleep hours',
                    value: latest.sleepDurationHours == null
                        ? 'n/a'
                        : latest.sleepDurationHours!.toStringAsFixed(1),
                  ),
                  _StatCard(
                    label: 'Sleep quality',
                    value: latest.sleepQualityScore == null
                        ? 'n/a'
                        : latest.sleepQualityScore!.toStringAsFixed(0),
                  ),
                  _StatCard(
                    label: 'Resting HR',
                    value: latest.restingHeartRate == null
                        ? 'n/a'
                        : latest.restingHeartRate!.toStringAsFixed(0),
                  ),
                  _StatCard(
                    label: 'HRV',
                    value: latest.hrvRmssd == null
                        ? 'n/a'
                        : latest.hrvRmssd!.toStringAsFixed(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Top alerts',
              subtitle:
                  '${experience.alerts.highPriorityCount} high-priority items across ${experience.alerts.totalCount} total flags.',
              child: Column(
                children: [
                  for (final flag in experience.alerts.items) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppPalette.sand.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flag.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.ink,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            flag.rationale,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.ink.withValues(alpha: 0.72),
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.64),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
