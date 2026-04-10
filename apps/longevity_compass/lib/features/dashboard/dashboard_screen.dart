import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../core/models/experience_models.dart';
import '../../core/presentation/customer_facing_content.dart';
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
        final customerProfile = controller.customerProfile;
        final bookings = controller.supportBookings;
        final isWelcomeJourney = controller.isWelcomeJourney;
        final startHere =
            experience.journeyStart.startHere.take(3).toList(growable: false);
        final watchTrends = experience.progressSummary.headlineTrends
            .take(3)
            .toList(growable: false);
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (isWelcomeJourney) ...[
                ScreenHeader(
                  eyebrow: 'Today',
                  title: controller.hasStartedOnboarding
                      ? 'One more setup step is enough.'
                      : 'Start with one useful first step.',
                  subtitle:
                      'Do not build the whole journey at once. Pick one outcome, one connection, and one optional clinic step.',
                ),
                const SizedBox(height: 24),
                SectionSurface(
                  title: 'Best first move',
                  subtitle: 'Get to the first moment of value quickly.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (startHere.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppPalette.mint.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            startHere.first,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppPalette.ink,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                          ),
                        ),
                      if (startHere.length > 1) ...[
                        const SizedBox(height: 16),
                        _BulletList(
                          title: 'Then do',
                          items: startHere.skip(1).toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (customerProfile != null)
                  SectionSurface(
                    title: 'What is connected',
                    subtitle:
                        'Only the sources that change the next decision belong here.',
                    child: _WelcomeSourcesCard(
                      profile: customerProfile,
                      bookings: bookings,
                    ),
                  ),
                if (bookings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionSurface(
                    title: 'Already booked',
                    subtitle:
                        'These are the real next steps already on your calendar.',
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < bookings.length;
                            index++) ...[
                          _BookedStepCard(booking: bookings[index]),
                          if (index < bookings.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const ScreenHeader(
                  eyebrow: 'Today',
                  title: 'Your biological age, and what is shaping it.',
                  subtitle:
                      'The longevity compass shows the six pillars behind the number and the one area to work on next.',
                ),
                const SizedBox(height: 24),
                if (experience.compass.peerComparison.hasItems) ...[
                  CompassRadarCard(experience: experience),
                  const SizedBox(height: 24),
                ] else ...[
                  CompassHeroCard(experience: experience),
                  const SizedBox(height: 24),
                ],
                SectionSurface(
                  title: 'What helps most this week',
                  subtitle:
                      'These are the few steps most likely to move the number in the right direction.',
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
                            _friendlyCheckInPrompt(
                              experience.weeklyPlan.checkInPrompt,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                if (watchTrends.isNotEmpty)
                  SectionSurface(
                    title: 'Signals worth watching',
                    subtitle:
                        'Only the few signals that help you judge the week.',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 760;
                        final children = watchTrends
                            .map(
                              (trend) => Expanded(
                                  child: MetricTrendTile(trend: trend)),
                            )
                            .toList(growable: false);

                        if (stacked) {
                          return Column(
                            children: watchTrends
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
              ],
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

class _WelcomeSourcesCard extends StatelessWidget {
  const _WelcomeSourcesCard({
    required this.profile,
    required this.bookings,
  });

  final CustomerProfile profile;
  final List<SupportBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final connected = profile.connectedSources;
    final disconnected = profile.disconnectedSources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BulletList(
          title: connected.isEmpty
              ? 'Nothing connected yet'
              : 'What is already in place',
          items: connected.isEmpty
              ? const [
                  'Connect a smartwatch, doctor summary, or baseline labs to move past the blank-slate stage.',
                ]
              : connected
                  .map(
                    (source) =>
                        '${source.label}${source.provider.isNotEmpty ? ' • ${source.provider}' : ''}: ${source.statusText}',
                  )
                  .toList(growable: false),
        ),
        if (disconnected.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BulletList(
            title: 'Good next connections',
            items: disconnected
                .take(3)
                .map((source) => '${source.label}: ${source.statusText}')
                .toList(growable: false),
          ),
        ],
        if (bookings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BulletList(
            title: 'What is already moving',
            items: bookings.map((booking) {
              final practical = practicalInfoForOfferCode(
                booking.offerCode,
                fallbackTitle: booking.offerLabel,
                fallbackFormat: booking.deliveryModel,
                offerType: booking.offerType,
              );
              return '${practical.title} is booked for ${booking.scheduledLabel}.';
            }).toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _BookedStepCard extends StatelessWidget {
  const _BookedStepCard({required this.booking});

  final SupportBooking booking;

  @override
  Widget build(BuildContext context) {
    final practical = practicalInfoForOfferCode(
      booking.offerCode,
      fallbackTitle: booking.offerLabel,
      fallbackFormat: booking.deliveryModel,
      offerType: booking.offerType,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.mint.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Booked',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practical.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.scheduledLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.74),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${practical.locationLabel} • ${practical.priceLabel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (practical.formatLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              practical.formatLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
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

String _friendlyCheckInPrompt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  if (trimmed.startsWith('Ask the coach to adapt')) {
    return 'If your week looks different than usual, ask the coach to tailor this plan to your schedule.';
  }

  return trimmed;
}
