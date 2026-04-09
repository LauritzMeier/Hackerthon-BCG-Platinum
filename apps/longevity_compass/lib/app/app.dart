import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/experience_repository.dart';
import '../features/coach/coach_screen.dart';
import '../features/dashboard/dashboard_controller.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/offers/offers_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/profile/profile_screen.dart';
import 'app_theme.dart';

class LongevityCompassApp extends StatelessWidget {
  const LongevityCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardController(
        repository: ExperienceRepository(),
      )..load(),
      child: MaterialApp(
        title: 'Longevity Compass',
        theme: AppTheme.build(),
        debugShowCheckedModeBanner: false,
        home: const _CompassShell(),
      ),
    );
  }
}

class _CompassShell extends StatefulWidget {
  const _CompassShell();

  @override
  State<_CompassShell> createState() => _CompassShellState();
}

class _CompassShellState extends State<_CompassShell> {
  int _index = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Compass',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Plan',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Coach',
    ),
    NavigationDestination(
      icon: Icon(Icons.local_hospital_outlined),
      selectedIcon: Icon(Icons.local_hospital),
      label: 'Offers',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  static const _railDestinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: Text('Compass'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: Text('Plan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: Text('Coach'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.local_hospital_outlined),
      selectedIcon: Icon(Icons.local_hospital),
      label: Text('Offers'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];

  static const _screens = <Widget>[
    DashboardScreen(),
    PlanScreen(),
    CoachScreen(),
    OffersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1080;

        return Scaffold(
          body: _ShellBackdrop(
            child: SafeArea(
              child: isWide
                  ? Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: NavigationRail(
                              selectedIndex: _index,
                              backgroundColor: Colors.white.withValues(alpha: 0.88),
                              minWidth: 92,
                              extended: true,
                              labelType: NavigationRailLabelType.none,
                              onDestinationSelected: (index) {
                                setState(() {
                                  _index = index;
                                });
                              },
                              destinations: _railDestinations,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1240),
                              child: _screens[_index],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _screens[_index],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  destinations: _destinations,
                  onDestinationSelected: (index) {
                    setState(() {
                      _index = index;
                    });
                  },
                ),
        );
      },
    );
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.mint.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.sand.withValues(alpha: 0.68),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
