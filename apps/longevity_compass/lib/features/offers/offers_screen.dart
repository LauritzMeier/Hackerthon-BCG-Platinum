import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

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
            title: 'Offers unavailable',
            body: controller.errorMessage ??
                'No support options are available until the Compass payload loads.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final recommended = experience.offers.recommended;
        final additional = experience.offers.additionalItems;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const ScreenHeader(
              eyebrow: 'Support Options',
              title: 'Monetization should feel earned.',
              subtitle:
                  'Offers appear only when the Compass can explain why they are relevant now.',
            ),
            const SizedBox(height: 24),
            if (recommended != null) ...[
              SectionSurface(
                title: 'Recommended now',
                subtitle:
                    'This option is tied to the current primary focus and the latest risk pattern.',
                child: OfferTile(
                  offer: recommended,
                  highlight: true,
                ),
              ),
              const SizedBox(height: 24),
            ],
            SectionSurface(
              title: 'Additional options',
              subtitle:
                  'A fallback ladder for broader support, without overwhelming the user.',
              child: Column(
                children: [
                  for (var index = 0; index < additional.length; index++) ...[
                    OfferTile(offer: additional[index]),
                    if (index < additional.length - 1) const SizedBox(height: 12),
                  ],
                  if (additional.isEmpty)
                    Text(
                      'The Compass does not suggest additional support right now.',
                      style: Theme.of(context).textTheme.bodyLarge,
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
