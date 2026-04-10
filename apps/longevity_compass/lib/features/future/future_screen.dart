import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../core/models/experience_models.dart';
import '../../core/presentation/customer_facing_content.dart';
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
            title: 'Support unavailable',
            body: controller.errorMessage ??
                'Support options need a live patient experience before they can render.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final bookedOffers = controller.supportBookings
            .where((booking) => booking.isBooked)
            .toList(growable: false);
        final bookedCodes =
            bookedOffers.map((booking) => booking.offerCode).toSet();
        final allOffers = <OfferOpportunity>[
          if (experience.offers.recommended != null)
            experience.offers.recommended!,
          ...experience.offers.additionalItems.where(
            (offer) =>
                offer.offerCode != experience.offers.recommended?.offerCode,
          ),
        ];
        final availableOffers = allOffers
            .where((offer) => !bookedCodes.contains(offer.offerCode))
            .toList(growable: false);
        final recommendedOffer =
            availableOffers.isNotEmpty ? availableOffers.first : null;
        final otherOffers = availableOffers.skip(1).take(2).toList(
              growable: false,
            );

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
          children: [
            ScreenHeader(
              eyebrow: 'Support',
              title: controller.isWelcomeJourney
                  ? 'Choose one useful first step.'
                  : 'Support worth acting on.',
              subtitle: controller.isWelcomeJourney
                  ? 'A first visit or baseline test is only worth it if it clarifies what happens next.'
                  : 'These options should help you make a clearer next decision, not just add more stuff.',
            ),
            if (bookedOffers.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Booked next steps',
                subtitle:
                    'This is what is already on the calendar, so you can see progress instead of guessing.',
                child: Column(
                  children: [
                    for (var index = 0;
                        index < bookedOffers.length;
                        index++) ...[
                      _BookedSupportCard(booking: bookedOffers[index]),
                      if (index < bookedOffers.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
            if (recommendedOffer != null) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Best next step',
                subtitle: controller.isWelcomeJourney
                    ? 'Start with one step that turns the blank slate into something concrete.'
                    : 'Start with the one clinic action that best fits the current plan.',
                child: OfferTile(
                  offer: recommendedOffer,
                  highlight: true,
                  onBook: (offer, scheduledFor, scheduledLabel) async {
                    return controller.bookSupportOffer(
                      offer: offer,
                      scheduledFor: scheduledFor,
                      scheduledLabel: scheduledLabel,
                    );
                  },
                ),
              ),
            ],
            if (otherOffers.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Also available now',
                subtitle: controller.isWelcomeJourney
                    ? 'These are second steps once you have a real starting point.'
                    : 'These still make sense, but they do not need to be first.',
                child: Column(
                  children: [
                    for (var index = 0;
                        index < otherOffers.length;
                        index++) ...[
                      OfferTile(
                        offer: otherOffers[index],
                        onBook: (offer, scheduledFor, scheduledLabel) async {
                          return controller.bookSupportOffer(
                            offer: offer,
                            scheduledFor: scheduledFor,
                            scheduledLabel: scheduledLabel,
                          );
                        },
                      ),
                      if (index < otherOffers.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BookedSupportCard extends StatelessWidget {
  const _BookedSupportCard({required this.booking});

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
        color: AppPalette.mint.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    color: AppPalette.ink.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
