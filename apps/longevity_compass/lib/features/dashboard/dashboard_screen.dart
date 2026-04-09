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
                title: 'Where you are now, and where you are heading.',
                subtitle:
                    'A six-pillar view that turns fragmented health data into one clear direction, one weekly plan, and one next-best support option.',
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
              CompassHeroCard(experience: experience),
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
                        .map((trend) => Expanded(child: MetricTrendTile(trend: trend)))
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
                        for (var index = 0; index < children.length; index++) ...[
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
                title: 'Flags and opportunities',
                subtitle:
                    'High-priority drift should lead to simple action, not confusion.',
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
        decoration: const InputDecoration(
          labelText: 'Demo patient',
        ),
        items: patients
            .map(
              (patient) => DropdownMenuItem<String>(
                value: patient.patientId,
                child: Text(patient.displayLabel),
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
