import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/experience_models.dart';
import '../core/presentation/customer_facing_content.dart';
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
  int _lastPresentedWelcomeGuideSequence = -1;
  bool _welcomeGuideVisible = false;

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
    _controller.addListener(_handleControllerChanged);
    _pageController = PageController(initialPage: _currentIndex);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
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

  void _resetNavigation() {
    if (_currentIndex != 1) {
      setState(() {
        _currentIndex = 1;
      });
    }
    if (_pageController.hasClients) {
      _pageController.jumpToPage(1);
    }
  }

  void _handleControllerChanged() {
    _maybePresentWelcomeGuide();
  }

  void _maybePresentWelcomeGuide() {
    final patientId = _controller.selectedPatientId;
    final customerProfile = _controller.customerProfile;
    final experience = _controller.experience;
    if (!mounted ||
        _controller.isLoading ||
        _welcomeGuideVisible ||
        _controller.loginSequence == _lastPresentedWelcomeGuideSequence ||
        patientId == null ||
        customerProfile == null ||
        experience == null ||
        !_controller.shouldShowWelcomeGuide) {
      return;
    }

    _welcomeGuideVisible = true;
    _lastPresentedWelcomeGuideSequence = _controller.loginSequence;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _welcomeGuideVisible = false;
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _WelcomeGuideDialog(
          customerProfile: customerProfile,
          experience: experience,
          onOpenProfile: () {
            Navigator.of(dialogContext).pop();
            Future<void>.microtask(
              () => _showProfileSheet(context, _controller),
            );
          },
          onSeeSupport: () {
            Navigator.of(dialogContext).pop();
            _selectTab(2);
          },
        ),
      );

      _welcomeGuideVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (context, controller, _) {
          return Scaffold(
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

                    if (!controller.hasBootstrapped && controller.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!controller.isLoggedIn) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(useFrame ? 18 : 0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: shellWidth),
                            child: _LoginGate(
                              controller: controller,
                              onLoginSuccess: _resetNavigation,
                            ),
                          ),
                        ),
                      );
                    }

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
                                      color:
                                          Colors.white.withValues(alpha: 0.42),
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
          );
        },
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

class _LoginGate extends StatefulWidget {
  const _LoginGate({
    required this.controller,
    required this.onLoginSuccess,
  });

  final DashboardController controller;
  final VoidCallback onLoginSuccess;

  @override
  State<_LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<_LoginGate> {
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final success = await widget.controller.loginWithUsername(value);
    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a demo journey',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose Mila Neumann for the blank-slate onboarding journey or Daniel Moreau for the active recovery journey.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.74),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _usernameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Patient name',
                hintText: 'Mila Neumann or Daniel Moreau',
              ),
              onSubmitted: _submit,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final patientId in controller.supportedDemoPatientIds)
                  ActionChip(
                    label: Text(customerDisplayNameForPatientId(patientId)),
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            _usernameController.text =
                                customerDisplayNameForPatientId(patientId);
                            final success =
                                await controller.loginWithPatientId(patientId);
                            if (success && context.mounted) {
                              widget.onLoginSuccess();
                            }
                          },
                  ),
              ],
            ),
            if (controller.errorMessage != null &&
                controller.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                controller.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.isLoading
                  ? null
                  : () => _submit(_usernameController.text),
              child: Text(controller.isLoading ? 'Loading...' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showProfileSheet(
  BuildContext context,
  DashboardController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ProfileSheet(controller: controller),
  );
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
        final summary = experience == null
            ? 'Bringing the current plan into view.'
            : controller.isWelcomeJourney
                ? 'Start with one useful next step.'
                : 'Evidence first. One next step.';

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
                const _ProfileButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DashboardController>();

    return IconButton(
      tooltip: 'Profile',
      onPressed: () => _showProfileSheet(context, controller),
      icon: const Icon(Icons.person_outline_rounded),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final theme = Theme.of(context);
          final experience = controller.experience;
          final patientMeta = experience == null
              ? 'Loading demo profile'
              : customerMetaLabel(
                  patientId: experience.profileSummary.patientId,
                  age: experience.profileSummary.age,
                  country: experience.profileSummary.country,
                );
          final customerProfile = controller.customerProfile;

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
                      if (customerProfile != null) ...[
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
                                customerProfile.journeyTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppPalette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                customerProfile.journeySummary,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.ink.withValues(alpha: 0.72),
                                  height: 1.4,
                                ),
                              ),
                              if (customerProfile.possibilities.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                for (var index = 0;
                                    index <
                                        customerProfile.possibilities.length;
                                    index++) ...[
                                  Text(
                                    '• ${customerProfile.possibilities[index]}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppPalette.ink
                                          .withValues(alpha: 0.74),
                                      height: 1.4,
                                    ),
                                  ),
                                  if (index <
                                      customerProfile.possibilities.length - 1)
                                    const SizedBox(height: 6),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                'Connected data sources',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppPalette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'For demo mode, turn sources on or off to see how the journey changes.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.ink.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (var index = 0;
                                  index < customerProfile.dataSources.length;
                                  index++) ...[
                                _DataSourceCard(
                                  source: customerProfile.dataSources[index],
                                  onToggle: ({
                                    required bool connected,
                                    String? provider,
                                  }) {
                                    controller.updateDataSourceConnection(
                                      sourceId: customerProfile
                                          .dataSources[index].sourceId,
                                      connected: connected,
                                      provider: provider,
                                    );
                                  },
                                ),
                                if (index <
                                    customerProfile.dataSources.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                              'Account',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppPalette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'For this demo, you can switch between Mila Neumann and Daniel Moreau, or log out and return to the login screen.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppPalette.ink.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (var index = 0;
                                index < controller.supportedDemoPatientIds.length;
                                index++) ...[
                              if (controller.hasPatient(
                                controller.supportedDemoPatientIds[index],
                              ))
                                _LoginAccountRow(
                                  patientId:
                                      controller.supportedDemoPatientIds[index],
                                  selected:
                                      controller.supportedDemoPatientIds[index] ==
                                          controller.selectedPatientId,
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await controller.selectPatient(
                                      controller.supportedDemoPatientIds[index],
                                    );
                                  },
                                ),
                              if (index <
                                  controller.supportedDemoPatientIds.length - 1)
                                const Divider(height: 18),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.logout();
                              },
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: controller.isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                controller.refresh();
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
        });
  }
}

class _WelcomeGuideDialog extends StatelessWidget {
  const _WelcomeGuideDialog({
    required this.customerProfile,
    required this.experience,
    required this.onOpenProfile,
    required this.onSeeSupport,
  });

  final CustomerProfile customerProfile;
  final ExperienceSnapshot experience;
  final VoidCallback onOpenProfile;
  final VoidCallback onSeeSupport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectNow = customerProfile.disconnectedSources
        .take(3)
        .map((source) => source.label)
        .toList(growable: false);
    final firstQuestions =
        experience.coach.suggestedPrompts.take(2).toList(growable: false);
    final firstSupport = <String>[
      if (experience.offers.recommended != null)
        practicalInfoForOffer(experience.offers.recommended!).title,
      ...experience.offers.additionalItems
          .take(2)
          .map((offer) => practicalInfoForOffer(offer).title),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0E7),
          borderRadius: BorderRadius.circular(32),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start with one useful outcome',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w800,
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
                'Start with one connection, one question, and one real next step. You do not need a full setup before the app becomes useful.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.76),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              _GuideHighlightCard(
                icon: Icons.link_rounded,
                title: 'Connect one useful source',
                body:
                    'The fastest unlock is usually a wearable or your last doctor summary.',
                items: connectNow,
              ),
              const SizedBox(height: 12),
              _GuideHighlightCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Use the coach to get oriented',
                body:
                    'The coach can help you choose what to connect first and which support option actually matches your goal.',
                items: firstQuestions,
              ),
              const SizedBox(height: 12),
              _GuideHighlightCard(
                icon: Icons.medical_services_outlined,
                title: 'Book one real first step',
                body:
                    'If you want clinician-led help early, start with one visit or baseline step instead of trying to build everything yourself.',
                items: firstSupport,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.mint.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Best first move: connect one source you can realistically keep up to date.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: onOpenProfile,
                    child: const Text('Connect data'),
                  ),
                  OutlinedButton(
                    onPressed: onSeeSupport,
                    child: const Text('See support'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Start exploring'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideHighlightCard extends StatelessWidget {
  const _GuideHighlightCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.sand.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppPalette.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.76),
                    height: 1.4,
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (var index = 0; index < items.length; index++) ...[
                    Text(
                      '• ${items[index]}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                    ),
                    if (index < items.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceCard extends StatelessWidget {
  const _DataSourceCard({
    required this.source,
    required this.onToggle,
  });

  final DataSourceConnection source;
  final void Function({
    required bool connected,
    String? provider,
  }) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerOptions = _providerOptionsFor(source.sourceId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.canvas.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: source.connected
                      ? AppPalette.mint.withValues(alpha: 0.9)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  source.connected ? 'Connected' : 'Not connected',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            source.statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.74),
              height: 1.4,
            ),
          ),
          if (source.provider.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Current source: ${source.provider}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (providerOptions.isNotEmpty && !source.connected)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: providerOptions
                  .map(
                    (provider) => OutlinedButton(
                      onPressed: () =>
                          onToggle(connected: true, provider: provider),
                      child: Text(provider),
                    ),
                  )
                  .toList(growable: false),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed:
                      source.connected ? null : () => onToggle(connected: true),
                  child: Text(source.ctaLabel),
                ),
                if (source.connected)
                  TextButton(
                    onPressed: () => onToggle(connected: false),
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          if (providerOptions.isNotEmpty && source.connected) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final provider in providerOptions)
                  OutlinedButton(
                    onPressed: () =>
                        onToggle(connected: true, provider: provider),
                    child: Text(
                      provider == source.provider ? '$provider ✓' : provider,
                    ),
                  ),
                TextButton(
                  onPressed: () => onToggle(connected: false),
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

List<String> _providerOptionsFor(String sourceId) {
  switch (sourceId) {
    case 'smartwatch':
      return const ['Apple Watch', 'Garmin', 'Oura', 'Whoop', 'Fitbit'];
    default:
      return const [];
  }
}

class _LoginAccountRow extends StatelessWidget {
  const _LoginAccountRow({
    required this.patientId,
    required this.selected,
    required this.onTap,
  });

  final String patientId;
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
                    customerDisplayNameForPatientId(patientId),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${customerSubtitleForPatientId(patientId)} • ${customerLoginAliasForPatientId(patientId)}',
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
