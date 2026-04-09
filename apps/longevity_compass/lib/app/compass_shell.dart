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
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      screen: CoachScreen(),
    ),
    _ShellDestination(
      label: 'Dashboard',
      icon: Icons.radar_rounded,
      screen: DashboardScreen(),
    ),
    _ShellDestination(
      label: 'Future',
      icon: Icons.timelapse_rounded,
      screen: FutureScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(
      repository: ExperienceRepository(),
    );
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
                          color: Colors.white
                              .withValues(alpha: useFrame ? 0.14 : 0),
                          borderRadius:
                              BorderRadius.circular(useFrame ? 42 : 0),
                          border: useFrame
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.42),
                                )
                              : null,
                          boxShadow: useFrame
                              ? [
                                  BoxShadow(
                                    color:
                                        AppPalette.ink.withValues(alpha: 0.12),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(useFrame ? 42 : 0),
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
  const _ShellBackdrop({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF6F0E7),
            Color(0xFFEAE7DD),
          ],
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
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
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
        final status = _statusPresentation(controller);
        final patientMeta = experience == null
            ? 'Waiting for live patient context'
            : '${experience.profileSummary.age} • ${experience.profileSummary.country}';
        final summary = experience == null
            ? 'Switching back to the three-page flow, now on real data.'
            : experience.journeyStart.summary;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Real patient flow',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusChip(status: status),
                    const SizedBox(width: 8),
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.72),
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 12),
                _PatientMenu(
                  patients: controller.patients,
                  selectedPatientId: controller.selectedPatientId,
                  patientMeta: patientMeta,
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

class _PatientMenu extends StatelessWidget {
  const _PatientMenu({
    required this.patients,
    required this.selectedPatientId,
    required this.patientMeta,
    required this.onSelected,
  });

  final List<PatientListItem> patients;
  final String? selectedPatientId;
  final String patientMeta;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = selectedPatientId ?? 'Select patient';

    return PopupMenuButton<String>(
      onSelected: onSelected,
      enabled: patients.isNotEmpty,
      itemBuilder: (context) => [
        for (final patient in patients)
          PopupMenuItem<String>(
            value: patient.patientId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.patientId,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.age} • ${patient.country} • ${patient.primaryFocusArea}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_pin_circle_outlined,
              color: AppPalette.ink,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    patientMeta,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.ink.withValues(alpha: 0.62),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppPalette.ink,
            ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final _StatusPresentation status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_StatusPresentation _statusPresentation(DashboardController controller) {
  if (!controller.isFirebaseEnabled) {
    return const _StatusPresentation(
      label: 'API mode',
      icon: Icons.cloud_outlined,
      color: AppPalette.forest,
    );
  }

  if (controller.firebaseUserId != null) {
    return const _StatusPresentation(
      label: 'Firebase sync on',
      icon: Icons.sync_rounded,
      color: AppPalette.forest,
    );
  }

  return const _StatusPresentation(
    label: 'Auth pending',
    icon: Icons.cloud_off_outlined,
    color: AppPalette.coral,
  );
}
