import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

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
            title: 'Weekly plan unavailable',
            body: controller.errorMessage ??
                'The app could not load a plan yet.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ScreenHeader(
              eyebrow: 'Weekly Plan',
              title: experience.weeklyPlan.title,
              subtitle:
                  'This week stays intentionally small: one focus area, a short list of actions, and one check-in prompt for the coach.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Primary focus',
              subtitle: experience.weeklyPlan.primaryFocus.whyNow,
              child: DirectionBadge(experience.compass.overallDirection),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Actions for this week',
              child: Column(
                children: [
                  for (var index = 0; index < experience.weeklyPlan.actions.length; index++) ...[
                    ActionTile(
                      index: index + 1,
                      action: experience.weeklyPlan.actions[index],
                    ),
                    if (index < experience.weeklyPlan.actions.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Coach prompt',
              child: Text(
                experience.weeklyPlan.checkInPrompt,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
            if (experience.offers.recommended != null) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'If you need extra support',
                child: OfferTile(
                  offer: experience.offers.recommended!,
                  highlight: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
