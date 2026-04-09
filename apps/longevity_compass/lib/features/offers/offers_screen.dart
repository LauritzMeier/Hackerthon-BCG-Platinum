import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/mock/persona_clinic_service_catalog.dart';
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
              title:
                  'Clinic services should feel persona-specific, not generic.',
              subtitle:
                  'These mocked programs turn the three strongest MVP personas into concrete clinic packages your team can pitch and test.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Persona-ready clinic programs',
              subtitle:
                  'Mocked service bundles for Markus, Sofia, and Tomasz, the three strongest starter personas from the product strategy.',
              child: Column(
                children: [
                  for (var index = 0;
                      index < mvpPersonaClinicPrograms.length;
                      index++) ...[
                    _PersonaProgramCard(
                        program: mvpPersonaClinicPrograms[index]),
                    if (index < mvpPersonaClinicPrograms.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (recommended != null) ...[
              SectionSurface(
                title: 'Current patient offer from the Compass',
                subtitle:
                    'This option still comes from the current API payload and stays useful as a patient-level recommendation example.',
                child: OfferTile(
                  offer: recommended,
                  highlight: true,
                ),
              ),
              const SizedBox(height: 24),
            ] else
              SectionSurface(
                title: 'Current patient offer unavailable',
                subtitle:
                    'The mocked persona programs above are ready even if the patient payload has not loaded yet.',
                child: Text(
                  controller.errorMessage ??
                      'No patient-specific offer is loaded right now, so the persona service catalog is acting as the primary demo layer.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Additional API-driven options',
              subtitle:
                  'A fallback ladder for broader support, without overwhelming the user.',
              child: Column(
                children: [
                  for (var index = 0; index < additional.length; index++) ...[
                    OfferTile(offer: additional[index]),
                    if (index < additional.length - 1)
                      const SizedBox(height: 12),
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

class _PersonaProgramCard extends StatelessWidget {
  const _PersonaProgramCard({required this.program});

  final PersonaClinicProgram program;

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
            '${program.personaName} • ${program.country}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.focus,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.positioning,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            program.salesNarrative,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < program.services.length; index++) ...[
            _ClinicServiceTile(service: program.services[index]),
            if (index < program.services.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ClinicServiceTile extends StatelessWidget {
  const _ClinicServiceTile({required this.service});

  final ClinicServiceMock service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.format,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            service.outcome,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.commercialRole,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
