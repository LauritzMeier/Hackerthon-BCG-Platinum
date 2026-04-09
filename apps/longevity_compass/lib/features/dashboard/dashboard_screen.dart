import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../core/models/experience_models.dart';
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
              ScreenHeader(
                eyebrow: 'Longevity Compass',
                title:
                    'Understand your health, then take one sensible next step.',
                subtitle:
                    'A new user should quickly see what the app already knows, what is still missing, and which next step is actually worth attention.',
                trailing: _PatientPicker(
                  patients: controller.patients,
                  selectedPatientId: controller.selectedPatientId,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectPatient(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (experience.compass.peerComparison.hasItems) ...[
                CompassRadarCard(experience: experience),
                const SizedBox(height: 24),
              ],
              SectionSurface(
                title: experience.journeyStart.title,
                subtitle: experience.journeyStart.summary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 900;
                    final panels = [
                      _JourneyPanel(
                        title: 'What we already know',
                        items: experience.journeyStart.whatWeKnow,
                        color: AppPalette.mint,
                      ),
                      _JourneyPanel(
                        title: 'What we still need',
                        items: experience.journeyStart.whatWeNeed,
                        color: AppPalette.sand,
                      ),
                      _JourneyPanel(
                        title: 'Start here',
                        items: experience.journeyStart.startHere,
                        color: AppPalette.coral,
                      ),
                    ];

                    if (stacked) {
                      return Column(
                        children: [
                          for (var index = 0;
                              index < panels.length;
                              index++) ...[
                            panels[index],
                            if (index < panels.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0; index < panels.length; index++) ...[
                          Expanded(child: panels[index]),
                          if (index < panels.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              CompassHeroCard(experience: experience),
              const SizedBox(height: 24),
              SectionSurface(
                title: experience.careContext.lastAppointmentTitle,
                subtitle: experience.careContext.headline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.careContext.lastAppointmentSummary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                    ),
                    if (experience.careContext.medications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoTagWrap(
                        title: 'Medications on file',
                        items: experience.careContext.medications,
                      ),
                    ],
                    if (experience
                        .careContext.clinicalPriorities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoTagWrap(
                        title: 'What needs attention now',
                        items: experience.careContext.clinicalPriorities,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPalette.sand.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        experience.careContext.medicalGuardrail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: AppPalette.ink,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'How personal the recommendations can be today',
                subtitle: experience.dataCoverage.headline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DataCoverageRow(
                      title: 'Connected data',
                      items: experience.dataCoverage.connectedSources,
                    ),
                    const SizedBox(height: 16),
                    _DataCoverageRow(
                      title: 'Still missing',
                      items: experience.dataCoverage.missingSources,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      experience.dataCoverage.tailoringNote,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Six pillars',
                subtitle:
                    'Everything in the app is derived from these six health pillars.',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 980
                        ? 3
                        : constraints.maxWidth >= 640
                            ? 2
                            : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: experience.compass.pillars.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: crossAxisCount == 1 ? 1.65 : 1.15,
                      ),
                      itemBuilder: (context, index) {
                        return PillarCard(
                          pillar: experience.compass.pillars[index],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Recent trend signals',
                subtitle:
                    'A lightweight read on what has shifted between your recent and longer baseline.',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 760;
                    final children = experience.progressSummary.headlineTrends
                        .map((trend) =>
                            Expanded(child: MetricTrendTile(trend: trend)))
                        .toList(growable: false);

                    if (stacked) {
                      return Column(
                        children: experience.progressSummary.headlineTrends
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
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Flags and next-best support',
                subtitle:
                    'High-priority drift should lead to one understandable next step, not a wall of options.',
                child: Column(
                  children: [
                    for (final flag in experience.alerts.items) ...[
                      _FlagTile(flag: flag),
                      const SizedBox(height: 12),
                    ],
                    if (experience.offers.recommended != null)
                      OfferTile(
                        offer: experience.offers.recommended!,
                        highlight: true,
                      ),
                  ],
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

class _JourneyPanel extends StatelessWidget {
  const _JourneyPanel({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
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
          for (var index = 0; index < items.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: AppPalette.forest,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.ink.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
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

class _InfoTagWrap extends StatelessWidget {
  const _InfoTagWrap({
    required this.title,
    required this.items,
  });

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

class _DataCoverageRow extends StatelessWidget {
  const _DataCoverageRow({
    required this.title,
    required this.items,
  });

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
              Icon(
                title == 'Connected data'
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                size: 18,
                color: title == 'Connected data'
                    ? AppPalette.forest
                    : AppPalette.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.76),
                        height: 1.4,
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

class _PatientPicker extends StatelessWidget {
  const _PatientPicker({
    required this.patients,
    required this.selectedPatientId,
    required this.onChanged,
  });

  final List<PatientListItem> patients;
  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<String>(
        initialValue: selectedPatientId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Demo patient',
        ),
        items: patients
            .map(
              (patient) => DropdownMenuItem<String>(
                value: patient.patientId,
                child: Text(
                  patient.displayLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({required this.flag});

  final RiskFlag flag;

  @override
  Widget build(BuildContext context) {
    final color = switch (flag.severity) {
      'high' => AppPalette.coral,
      'medium' => AppPalette.amber,
      _ => AppPalette.forest,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flag.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
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
          const SizedBox(height: 10),
          Text(
            flag.recommendedAction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
