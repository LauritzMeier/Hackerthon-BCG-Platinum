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
            .take(2)
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
          children: [
            const ScreenHeader(
              eyebrow: 'Support',
              title: 'Only the help that makes sense right now.',
              subtitle:
                  'Keep this short. Start with one clinic-relevant next step, then open a card if you want the drill-down.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Before you choose support',
              subtitle:
                  'Support should reinforce the current medical plan, not distract from it.',
              child: _SupportGuardrailCard(
                careContext: experience.careContext,
                dataCoverage: experience.dataCoverage,
              ),
            ),
            if (recommendedOffer != null) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Best next step',
                subtitle: recommendedOffer.whyNow,
                child: OfferTile(
                  offer: recommendedOffer,
                  highlight: true,
                ),
              ),
            ],
            if (otherOffers.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Other ways we can help',
                subtitle:
                    'Only keep the options that support the current plan or make the app more useful.',
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

class _SupportGuardrailCard extends StatelessWidget {
  const _SupportGuardrailCard({
    required this.careContext,
    required this.dataCoverage,
  });

  final CareContext careContext;
  final DataCoverage dataCoverage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final children = [
          _SupportInsightCard(
            title: 'What is driving the recommendation',
            body: careContext.lastAppointmentSummary,
            footer: careContext.medicalGuardrail,
            accent: AppPalette.sand.withValues(alpha: 0.82),
          ),
          _SupportInsightCard(
            title: 'What would make this more precise',
            body: dataCoverage.tailoringNote,
            footer: dataCoverage.missingSources.isEmpty
                ? null
                : dataCoverage.missingSources.first,
            accent: AppPalette.mint.withValues(alpha: 0.34),
          ),
        ];

        if (stacked) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SupportInsightCard extends StatelessWidget {
  const _SupportInsightCard({
    required this.title,
    required this.body,
    required this.accent,
    this.footer,
  });

  final String title;
  final String body;
  final String? footer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.78),
                  height: 1.45,
                ),
          ),
          if (footer != null && footer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              footer!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
