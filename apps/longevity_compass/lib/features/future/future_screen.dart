import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

        final recommendedOffer = experience.offers.recommended;
        final otherOffers = experience.offers.additionalItems
            .where((offer) => offer.offerCode != recommendedOffer?.offerCode)
            .take(3)
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
          children: [
            const ScreenHeader(
              eyebrow: 'Support',
              title: 'Choose the next support that actually helps.',
              subtitle:
                  'These options are filtered to the services that still fit your medical plan and current recovery stage.',
            ),
            if (recommendedOffer != null) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Best next step',
                subtitle:
                    'Start with one clinic action that fits the current plan and recovery stage.',
                child: OfferTile(offer: recommendedOffer, highlight: true),
              ),
            ],
            if (otherOffers.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Also available now',
                subtitle:
                    'These still make sense right now, but they do not need to be first.',
                child: Column(
                  children: [
                    for (var index = 0;
                        index < otherOffers.length;
                        index++) ...[
                      OfferTile(offer: otherOffers[index]),
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
