import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/experience_models.dart';
import '../core/services/experience_repository.dart';
import '../features/coach/coach_screen.dart';
import '../features/dashboard/dashboard_controller.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/future/future_screen.dart';
import 'app_theme.dart';

class CompassShell extends StatefulWidget {
  const CompassShell({super.key});

  @override
  State<CompassShell> createState() => _CompassShellState();
}

class _CompassShellState extends State<CompassShell> {
  late final DashboardController _controller;
  late final PageController _pageController;
  int _currentIndex = 1;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Coach',
      icon: Icons.chat_bubble_outline_rounded,
      screen: CoachScreen(),
    ),
    _ShellDestination(
      label: 'Today',
      icon: Icons.radar_rounded,
      screen: DashboardScreen(),
    ),
    _ShellDestination(
      label: 'Support',
      icon: Icons.medical_services_outlined,
      screen: FutureScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(repository: ExperienceRepository());
    _pageController = PageController(initialPage: _currentIndex);
    _controller.load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppPalette.canvas,
        body: _ShellBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useFrame = constraints.maxWidth >= 720;
                final shellWidth = useFrame
                    ? (constraints.maxWidth * 0.58)
                          .clamp(440.0, 620.0)
                          .toDouble()
                    : constraints.maxWidth;

                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(useFrame ? 18 : 0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: shellWidth),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: useFrame ? 0.14 : 0,
                          ),
                          borderRadius: BorderRadius.circular(
                            useFrame ? 42 : 0,
                          ),
                          border: useFrame
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.42),
                                )
                              : null,
                          boxShadow: useFrame
                              ? [
                                  BoxShadow(
                                    color: AppPalette.ink.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            useFrame ? 42 : 0,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.24),
                                  Colors.white.withValues(alpha: 0.06),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Column(
                              children: [
                                const _ShellTopBar(),
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                    children: const [
                                      CoachScreen(),
                                      DashboardScreen(),
                                      FutureScreen(),
                                    ],
                                  ),
                                ),
                                _ShellBottomBar(
                                  currentIndex: _currentIndex,
                                  destinations: _destinations,
                                  onSelected: _selectTab,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final Widget screen;
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F0E7), Color(0xFFEAE7DD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -40,
            child: _GlowOrb(
              size: 280,
              color: AppPalette.mint.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: _GlowOrb(
              size: 220,
              color: AppPalette.amber.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            child: _GlowOrb(
              size: 260,
              color: AppPalette.sand.withValues(alpha: 0.68),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final experience = controller.experience;
        final patientMeta = experience == null
            ? 'Loading demo profile'
            : '${experience.profileSummary.patientId} • ${experience.profileSummary.age} • ${experience.profileSummary.country}';
        final summary = experience == null
            ? 'Bringing your care context into view.'
            : 'This week: ${experience.weeklyPlan.primaryFocus.pillarName}.';

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Longevity Compass',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppPalette.ink.withValues(alpha: 0.7),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.isLoading
                      ? null
                      : () {
                          controller.refresh();
                        },
                  icon: controller.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                _ProfileButton(
                  patients: controller.patients,
                  selectedPatientId: controller.selectedPatientId,
                  patientMeta: patientMeta,
                  isLoading: controller.isLoading,
                  onRefresh: controller.refresh,
                  onSelected: (patientId) {
                    controller.selectPatient(patientId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.patients,
    required this.selectedPatientId,
    required this.patientMeta,
    required this.isLoading,
    required this.onRefresh,
    required this.onSelected,
  });

  final List<PatientListItem> patients;
  final String? selectedPatientId;
  final String patientMeta;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _ProfileSheet(
          patients: patients,
          selectedPatientId: selectedPatientId,
          patientMeta: patientMeta,
          isLoading: isLoading,
          onRefresh: onRefresh,
          onSelected: onSelected,
        ),
      ),
      icon: const Icon(Icons.person_outline_rounded),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.patients,
    required this.selectedPatientId,
    required this.patientMeta,
    required this.isLoading,
    required this.onRefresh,
    required this.onSelected,
  });

  final List<PatientListItem> patients;
  final String? selectedPatientId;
  final String patientMeta;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F0E7),
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  patientMeta,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internal demo controls',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Patient switching lives here so the customer journey stays clean. Real customers would not see this panel.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.ink.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var index = 0; index < patients.length; index++) ...[
                        _PatientSheetRow(
                          patient: patients[index],
                          selected:
                              patients[index].patientId == selectedPatientId,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelected(patients[index].patientId);
                          },
                        ),
                        if (index < patients.length - 1)
                          const Divider(height: 18),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onRefresh();
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh current data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientSheetRow extends StatelessWidget {
  const _PatientSheetRow({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  final PatientListItem patient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.patientId,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${patient.age} • ${patient.country} • ${patient.primaryFocusArea}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppPalette.forest),
          ],
        ),
      ),
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<_ShellDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppPalette.ink.withValues(alpha: 0.06),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _NavButton(
                  label: destinations[index].label,
                  icon: destinations[index].icon,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? AppPalette.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppPalette.ink,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : AppPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
