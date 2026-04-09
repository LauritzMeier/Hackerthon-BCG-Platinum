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

        final recommended = experience?.offers.recommended;
        final additional = experience?.offers.additionalItems ?? const [];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const ScreenHeader(
              eyebrow: 'Support Options',
              title: 'Support should feel earned, relevant, and easy to understand.',
              subtitle:
                  'A new user should see one clear next step, why it fits their current situation, and what would make the recommendation even better.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'How these recommendations are being chosen',
              subtitle:
                  experience?.dataCoverage.confidenceLabel ??
                      'The app should be honest about what it knows and what is still missing.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience?.journeyStart.summary ??
                        'The recommendation engine should use care context, watch data, and obvious data gaps before it suggests extra support.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _OfferContextBlock(
                    title: 'What we already know',
                    items: experience?.journeyStart.whatWeKnow ?? const [],
                  ),
                  const SizedBox(height: 12),
                  _OfferContextBlock(
                    title: 'What would make support more precise',
                    items: experience?.journeyStart.whatWeNeed ?? const [],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (recommended != null) ...[
              SectionSurface(
                title: 'Best next support',
                subtitle:
                    'The first recommendation should solve the most obvious user need, not just advertise a package.',
                child: OfferTile(
                  offer: recommended,
                  highlight: true,
                ),
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'What should happen before the user buys more',
                subtitle:
                    'For a new user, trust grows when the app makes the next step feel manageable.',
                child: _OfferContextBlock(
                  title: 'Start here first',
                  items: experience?.journeyStart.startHere ?? const [],
                ),
              ),
              const SizedBox(height: 24),
            ] else
              SectionSurface(
                title: 'No primary support recommendation yet',
                subtitle:
                    'The screen should still explain what support would become relevant once the patient context loads.',
                child: Text(
                  controller.errorMessage ??
                      'No patient-specific support option is loaded right now.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            SectionSurface(
              title: 'Useful next options, but not first',
              subtitle:
                  'These remain relevant without overwhelming the user or pushing something unrelated.',
              child: Column(
                children: [
                  for (var index = 0; index < additional.length; index++) ...[
                    OfferTile(offer: additional[index]),
                    if (index < additional.length - 1)
                      const SizedBox(height: 12),
                  ],
                  if (additional.isEmpty)
                    Text(
                      'No secondary options are loaded right now.',
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

class _OfferContextBlock extends StatelessWidget {
  const _OfferContextBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFF2F5D4E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[index],
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
            if (index < items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
