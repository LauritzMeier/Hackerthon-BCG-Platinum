import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app/app_theme.dart';
import '../core/models/experience_models.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: AppPalette.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.74),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

class SectionSurface extends StatelessWidget {
  const SectionSurface({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppPalette.ink.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.68),
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class DirectionBadge extends StatelessWidget {
  const DirectionBadge(this.direction, {super.key});

  final String direction;

  @override
  Widget build(BuildContext context) {
    final appearance = _appearanceForDirection(direction);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: appearance.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 18, color: appearance.foreground),
          const SizedBox(width: 8),
          Text(
            appearance.label,
            style: GoogleFonts.manrope(
              color: appearance.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CompassHeroCard extends StatelessWidget {
  const CompassHeroCard({super.key, required this.experience});

  final ExperienceSnapshot experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ageGap = experience.profileSummary.ageGapYears;
    final ageText = ageGap == null
        ? 'Biological age estimate not available yet'
        : ageGap > 0
        ? '${ageGap.toStringAsFixed(1)} years above chronological age'
        : '${ageGap.abs().toStringAsFixed(1)} years below chronological age';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [AppPalette.ink, AppPalette.forest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DirectionBadge(experience.compass.overallDirection),
              _HeroPill(
                label: 'This week',
                value: experience.weeklyPlan.primaryFocus.pillarName,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'This week, focus on ${experience.weeklyPlan.primaryFocus.pillarName}.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            experience.weeklyPlan.primaryFocus.whyNow,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(
                label: 'Chronological age',
                value: '${experience.compass.chronologicalAge}',
              ),
              _HeroMetric(
                label: 'Estimated biological age',
                value: experience.compass.estimatedBiologicalAge == null
                    ? 'n/a'
                    : experience.compass.estimatedBiologicalAge!
                          .toStringAsFixed(1),
              ),
              _HeroMetric(label: 'Age gap', value: ageText),
            ],
          ),
        ],
      ),
    );
  }
}

class CompassRadarCard extends StatefulWidget {
  const CompassRadarCard({super.key, required this.experience});

  final ExperienceSnapshot experience;

  @override
  State<CompassRadarCard> createState() => _CompassRadarCardState();
}

class _CompassRadarCardState extends State<CompassRadarCard> {
  late String _selectedPillarId;

  @override
  void initState() {
    super.initState();
    _selectedPillarId = widget.experience.compass.primaryFocus.pillarId;
  }

  @override
  void didUpdateWidget(covariant CompassRadarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final items = widget.experience.compass.peerComparison.items;
    final stillExists = items.any((item) => item.pillarId == _selectedPillarId);
    if (!stillExists && items.isNotEmpty) {
      _selectedPillarId = widget.experience.compass.primaryFocus.pillarId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = widget.experience.compass.peerComparison;
    if (!comparison.hasItems) {
      return const SizedBox.shrink();
    }

    final selectedComparison = comparison.items.firstWhere(
      (item) => item.pillarId == _selectedPillarId,
      orElse: () => comparison.items.first,
    );
    final selectedPillar = widget.experience.compass.pillars.firstWhere(
      (pillar) => pillar.id == selectedComparison.pillarId,
      orElse: () => widget.experience.compass.pillars.first,
    );
    final differenceAppearance = selectedComparison.hasEnoughData
        ? (selectedComparison.difference >= 0
              ? _appearanceForDirection('improving')
              : _appearanceForDirection('drifting'))
        : _appearanceForDataConfidence(selectedComparison.scoreConfidence);
    final stateAppearance = _appearanceForState(selectedPillar.state);
    final trendAppearance = _appearanceForDirection(selectedPillar.trend);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.96),
            AppPalette.sand.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppPalette.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniBadge(
                label: 'Six-pillar compass',
                background: AppPalette.ink.withValues(alpha: 0.08),
                foreground: AppPalette.ink,
              ),
              if (comparison.sampleSize > 0)
                _MiniBadge(
                  label: '${comparison.sampleSize} peers',
                  background: AppPalette.mint.withValues(alpha: 0.9),
                  foreground: AppPalette.ink,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comparison.headline,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comparison.cohortLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 920;

              final chart = _CompassRadarDiagram(
                items: comparison.items,
                selectedPillarId: _selectedPillarId,
                onSelect: (pillarId) {
                  setState(() {
                    _selectedPillarId = pillarId;
                  });
                },
              );

              final detail = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(
                        label: selectedComparison.pillarName,
                        background: _pillarAccent(
                          selectedComparison.pillarId,
                        ).withValues(alpha: 0.16),
                        foreground: AppPalette.ink,
                      ),
                      _MiniBadge(
                        label: selectedComparison.hasEnoughData
                            ? differenceAppearance.label
                            : 'Needs more data',
                        background: differenceAppearance.background,
                        foreground: differenceAppearance.foreground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _comparisonHeadline(selectedComparison),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _comparisonBody(
                      selectedComparison,
                      comparison,
                      widget.experience.compass.primaryFocus,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.74),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ComparisonStatTile(
                        label: 'You',
                        value: selectedComparison.patientScoreLabel,
                      ),
                      _ComparisonStatTile(
                        label: 'Age cohort',
                        value: selectedComparison.peerScoreLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(
                        label: stateAppearance.label,
                        background: stateAppearance.background,
                        foreground: stateAppearance.foreground,
                      ),
                      if (!selectedPillar.hasEnoughData)
                        _MiniBadge(
                          label: 'Estimate only',
                          background: AppPalette.sand.withValues(alpha: 0.95),
                          foreground: AppPalette.ink,
                        ),
                      _MiniBadge(
                        label: trendAppearance.label,
                        background: trendAppearance.background,
                        foreground: trendAppearance.foreground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedPillar.whyItMatters,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap any pillar around the chart to drill into the comparison.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.56),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [chart, const SizedBox(height: 24), detail],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: chart),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: detail),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompassRadarDiagram extends StatelessWidget {
  const _CompassRadarDiagram({
    required this.items,
    required this.selectedPillarId,
    required this.onSelect,
  });

  final List<PeerComparisonItem> items;
  final String selectedPillarId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = math
            .min(constraints.maxWidth, 430.0)
            .clamp(280.0, 430.0);
        final center = canvasSize / 2;
        final radius = canvasSize * 0.28;
        const chipWidth = 112.0;
        const chipHeight = 62.0;

        return Center(
          child: SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CompassRadarPainter(
                      items: items,
                      selectedPillarId: selectedPillarId,
                    ),
                  ),
                ),
                for (var index = 0; index < items.length; index++)
                  Builder(
                    builder: (context) {
                      final item = items[index];
                      final angle =
                          (-math.pi / 2) +
                          ((2 * math.pi * index) / items.length);
                      final anchor = Offset(
                        center + math.cos(angle) * (radius + 58),
                        center + math.sin(angle) * (radius + 58),
                      );
                      final selected = item.pillarId == selectedPillarId;
                      final accent = _pillarAccent(item.pillarId);
                      final foreground = selected
                          ? _foregroundFor(accent)
                          : AppPalette.ink;

                      return Positioned(
                        left: anchor.dx - (chipWidth / 2),
                        top: anchor.dy - (chipHeight / 2),
                        width: chipWidth,
                        height: chipHeight,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: selected ? 1.04 : 1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onSelect(item.pillarId),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent
                                      : Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? accent
                                        : AppPalette.ink.withValues(
                                            alpha: 0.08,
                                          ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppPalette.ink.withValues(
                                        alpha: selected ? 0.12 : 0.05,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _shortPillarLabel(item.pillarName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: foreground,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.patientScoreLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: foreground,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
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

class _CompassRadarPainter extends CustomPainter {
  _CompassRadarPainter({required this.items, required this.selectedPillarId});

  final List<PeerComparisonItem> items;
  final String selectedPillarId;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    final gridPaint = Paint()
      ..color = AppPalette.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final progress = ring / 4;
      final ringPath = _buildRadarPath(
        center: center,
        radius: radius * progress,
        items: items,
        scoreSelector: (_) => 100,
      );
      canvas.drawPath(ringPath, gridPaint);
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final angle = (-math.pi / 2) + ((2 * math.pi * index) / items.length);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final selected = item.pillarId == selectedPillarId;
      canvas.drawLine(
        center,
        point,
        Paint()
          ..color = selected
              ? _pillarAccent(item.pillarId).withValues(alpha: 0.34)
              : AppPalette.ink.withValues(alpha: 0.08)
          ..strokeWidth = selected ? 1.8 : 1,
      );
    }

    final peerPath = _buildRadarPath(
      center: center,
      radius: radius,
      items: items,
      scoreSelector: (item) => item.peerScore,
    );
    canvas.drawPath(
      peerPath,
      Paint()..color = AppPalette.sand.withValues(alpha: 0.82),
    );
    canvas.drawPath(
      peerPath,
      Paint()
        ..color = AppPalette.ink.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final patientPath = _buildRadarPath(
      center: center,
      radius: radius,
      items: items,
      scoreSelector: (item) => item.patientScore,
    );
    canvas.drawPath(
      patientPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.forest.withValues(alpha: 0.34),
            AppPalette.moss.withValues(alpha: 0.12),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      patientPath,
      Paint()
        ..color = AppPalette.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final angle = (-math.pi / 2) + ((2 * math.pi * index) / items.length);
      final patientPoint = Offset(
        center.dx +
            math.cos(angle) * radius * (_normalizedScore(item.patientScore)),
        center.dy +
            math.sin(angle) * radius * (_normalizedScore(item.patientScore)),
      );
      final peerPoint = Offset(
        center.dx +
            math.cos(angle) * radius * (_normalizedScore(item.peerScore)),
        center.dy +
            math.sin(angle) * radius * (_normalizedScore(item.peerScore)),
      );
      final selected = item.pillarId == selectedPillarId;
      final accent = _pillarAccent(item.pillarId);

      canvas.drawCircle(
        peerPoint,
        selected ? 4.5 : 3.5,
        Paint()..color = AppPalette.ink.withValues(alpha: 0.32),
      );
      canvas.drawCircle(
        patientPoint,
        selected ? 7 : 5,
        Paint()..color = accent,
      );
      canvas.drawCircle(
        patientPoint,
        selected ? 12 : 8,
        Paint()..color = accent.withValues(alpha: 0.14),
      );
    }
  }

  Path _buildRadarPath({
    required Offset center,
    required double radius,
    required List<PeerComparisonItem> items,
    required double Function(PeerComparisonItem item) scoreSelector,
  }) {
    final path = Path();
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final angle = (-math.pi / 2) + ((2 * math.pi * index) / items.length);
      final point = Offset(
        center.dx +
            math.cos(angle) * radius * _normalizedScore(scoreSelector(item)),
        center.dy +
            math.sin(angle) * radius * _normalizedScore(scoreSelector(item)),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  double _normalizedScore(double value) {
    return value.clamp(0, 100).toDouble() / 100;
  }

  @override
  bool shouldRepaint(covariant _CompassRadarPainter oldDelegate) {
    return oldDelegate.selectedPillarId != selectedPillarId ||
        oldDelegate.items != items;
  }
}

class _ComparisonStatTile extends StatelessWidget {
  const _ComparisonStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PillarCard extends StatelessWidget {
  const PillarCard({super.key, required this.pillar});

  final PillarSnapshot pillar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateAppearance = _appearanceForState(pillar.state);
    final trendAppearance = _appearanceForDirection(pillar.trend);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.ink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pillar.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            pillar.scoreLabel,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pillar.whyItMatters,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: stateAppearance.label,
                background: stateAppearance.background,
                foreground: stateAppearance.foreground,
              ),
              if (!pillar.hasEnoughData)
                _MiniBadge(
                  label: 'Estimate only',
                  background: AppPalette.sand.withValues(alpha: 0.95),
                  foreground: AppPalette.ink,
                ),
              _MiniBadge(
                label: trendAppearance.label,
                background: trendAppearance.background,
                foreground: trendAppearance.foreground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricTrendTile extends StatelessWidget {
  const MetricTrendTile({super.key, required this.trend});

  final HeadlineTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = _appearanceForDirection(trend.trend);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appearance.background.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trend.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${trend.currentValue.toStringAsFixed(trend.currentValue < 10 ? 1 : 0)} ${trend.unit}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Baseline ${trend.baselineValue.toStringAsFixed(trend.baselineValue < 10 ? 1 : 0)} ${trend.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 12),
          DirectionBadge(trend.trend),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.index, required this.action});

  final int index;
  final PlanAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.sand.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppPalette.forest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showOfferDetailSheet(
  BuildContext context,
  OfferOpportunity offer, {
  required bool highlight,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _OfferDetailSheet(
      offer: offer,
      highlight: highlight,
      hostContext: context,
    ),
  );
}

Future<void> _showOfferActionSheet(
  BuildContext context,
  OfferOpportunity offer,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _OfferActionSheet(offer: offer, hostContext: context),
  );
}

class OfferTile extends StatelessWidget {
  const OfferTile({super.key, required this.offer, this.highlight = false});

  final OfferOpportunity offer;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = highlight ? Colors.white : AppPalette.ink;
    final secondary = highlight
        ? Colors.white.withValues(alpha: 0.84)
        : AppPalette.ink.withValues(alpha: 0.72);
    final previewItems = offer.includes.take(2).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [AppPalette.forest, AppPalette.moss],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniBadge(
                label: highlight ? 'Best next step' : offer.category,
                background: highlight
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppPalette.mint.withValues(alpha: 0.7),
                foreground: highlight ? Colors.white : AppPalette.ink,
              ),
              if (offer.deliveryModel.isNotEmpty)
                _MiniBadge(
                  label: offer.deliveryModel,
                  background: highlight
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppPalette.sand.withValues(alpha: 0.9),
                  foreground: highlight ? Colors.white : AppPalette.ink,
                ),
              if (offer.timeCommitment.isNotEmpty)
                _MiniBadge(
                  label: offer.timeCommitment,
                  background: highlight
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  foreground: highlight ? Colors.white : AppPalette.ink,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            offer.offerLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.summary.isNotEmpty ? offer.summary : offer.rationale,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: secondary,
              height: 1.42,
            ),
          ),
          if (offer.whyNow.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              offer.whyNow,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondary,
                height: 1.4,
              ),
            ),
          ],
          if (previewItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'What you get',
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in previewItems) ...[
              _OfferPreviewPoint(
                text: item,
                foreground: secondary,
                highlight: highlight,
              ),
              if (item != previewItems.last) const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _showOfferActionSheet(context, offer),
                  style: FilledButton.styleFrom(
                    backgroundColor: highlight
                        ? Colors.white
                        : AppPalette.forest,
                    foregroundColor: highlight ? AppPalette.ink : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(offer.primaryActionLabel),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () =>
                    _showOfferDetailSheet(context, offer, highlight: highlight),
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferPreviewPoint extends StatelessWidget {
  const _OfferPreviewPoint({
    required this.text,
    required this.foreground,
    required this.highlight,
  });

  final String text;
  final Color foreground;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: highlight ? Colors.white : AppPalette.forest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: foreground, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _OfferDetailSheet extends StatelessWidget {
  const _OfferDetailSheet({
    required this.offer,
    required this.highlight,
    required this.hostContext,
  });

  final OfferOpportunity offer;
  final bool highlight;
  final BuildContext hostContext;

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
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniBadge(
                            label: highlight
                                ? 'Best next step'
                                : offer.category,
                            background: AppPalette.mint.withValues(alpha: 0.85),
                            foreground: AppPalette.ink,
                          ),
                          if (offer.deliveryModel.isNotEmpty)
                            _MiniBadge(
                              label: offer.deliveryModel,
                              background: AppPalette.sand,
                              foreground: AppPalette.ink,
                            ),
                          if (offer.timeCommitment.isNotEmpty)
                            _MiniBadge(
                              label: offer.timeCommitment,
                              background: Colors.white,
                              foreground: AppPalette.ink,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer.offerLabel,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  offer.summary.isNotEmpty ? offer.summary : offer.rationale,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                _OfferDetailSection(
                  title: 'Why this is recommended now',
                  body: offer.whyNow,
                ),
                _OfferDetailSection(
                  title: 'What outcome this should create',
                  body: offer.expectedOutcome,
                ),
                _OfferDetailListSection(
                  title: 'What this includes',
                  items: offer.includes,
                ),
                _OfferDetailListSection(
                  title: 'What data we used',
                  items: offer.dataUsed,
                ),
                if (offer.missingData.isNotEmpty)
                  _OfferDetailListSection(
                    title: 'What would make this even sharper',
                    items: offer.missingData,
                  ),
                _OfferDetailListSection(
                  title: 'What the first week looks like',
                  items: offer.firstWeek,
                ),
                if (offer.personalizationNote.isNotEmpty)
                  _OfferDetailSection(
                    title: 'Why this fits this user',
                    body: offer.personalizationNote,
                  ),
                if (offer.caution.isNotEmpty)
                  _OfferDetailSection(
                    title: 'Important guardrail',
                    body: offer.caution,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Future<void>.microtask(
                            () => _showOfferActionSheet(hostContext, offer),
                          );
                        },
                        child: Text(offer.primaryActionLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferActionSheet extends StatelessWidget {
  const _OfferActionSheet({required this.offer, required this.hostContext});

  final OfferOpportunity offer;
  final BuildContext hostContext;

  String get _headline {
    switch (offer.offerType) {
      case 'appointment':
      case 'appointment_prep':
        return 'Book the visit';
      case 'diagnostic':
        return 'Book the diagnostic';
      case 'program':
      case 'coaching':
        return 'Start with an intake';
      case 'supplement':
        return 'Request a guided review';
      case 'starter':
        return 'Start this from the app';
      default:
        return 'Choose the next step';
    }
  }

  String get _body {
    switch (offer.offerType) {
      case 'appointment':
      case 'appointment_prep':
        return 'This would route you to the clinic team for ${offer.offerLabel.toLowerCase()} and confirm the right visit format.';
      case 'diagnostic':
        return 'This would hand you off to booking for the right lab or diagnostic slot.';
      case 'program':
      case 'coaching':
        return 'This would start the intake process so the care team can tailor the plan to your current recovery stage.';
      case 'supplement':
        return 'This would create a clinician-reviewed supplement discussion instead of leaving you to guess on your own.';
      case 'starter':
        return 'This would begin a lighter-weight plan inside the app and set up the first week.';
      default:
        return 'This would move you into the next guided support step.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextSteps = offer.firstWeek.isNotEmpty
        ? offer.firstWeek.take(3).toList(growable: false)
        : offer.includes.take(3).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
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
                        _headline,
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
                  offer.offerLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                if (offer.deliveryModel.isNotEmpty ||
                    offer.timeCommitment.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (offer.deliveryModel.isNotEmpty)
                        _MiniBadge(
                          label: offer.deliveryModel,
                          background: AppPalette.mint.withValues(alpha: 0.7),
                          foreground: AppPalette.ink,
                        ),
                      if (offer.timeCommitment.isNotEmpty)
                        _MiniBadge(
                          label: offer.timeCommitment,
                          background: AppPalette.sand,
                          foreground: AppPalette.ink,
                        ),
                    ],
                  ),
                if (nextSteps.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _OfferDetailListSection(
                    title: 'What happens next',
                    items: nextSteps,
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Demo action: ${offer.primaryActionLabel.toLowerCase()} for ${offer.offerLabel}.',
                              ),
                            ),
                          );
                        },
                        child: Text(offer.primaryActionLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Maybe later'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferDetailSection extends StatelessWidget {
  const _OfferDetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.76),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferDetailListSection extends StatelessWidget {
  const _OfferDetailListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 8, color: AppPalette.forest),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.76),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final background = message.isUser
        ? AppPalette.ink
        : Colors.white.withValues(alpha: 0.88);
    final foreground = message.isUser ? Colors.white : AppPalette.ink;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            message.text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: foreground, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SectionSurface(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

String formatDateTime(DateTime? value) {
  if (value == null) {
    return 'No recent data';
  }
  return DateFormat('dd MMM yyyy').format(value.toLocal());
}

String _shortPillarLabel(String label) {
  switch (label) {
    case 'Sleep and Recovery':
      return 'Sleep';
    case 'Cardiovascular Health':
      return 'Cardio';
    case 'Metabolic Health':
      return 'Metabolic';
    case 'Movement and Fitness':
      return 'Movement';
    case 'Nutrition Quality':
      return 'Nutrition';
    case 'Mental Resilience':
      return 'Resilience';
    default:
      return label;
  }
}

String _comparisonHeadline(PeerComparisonItem item) {
  if (!item.hasEnoughData) {
    return 'Not enough tracked data yet';
  }

  final absoluteDifference = item.difference.abs();
  if (absoluteDifference < 2) {
    return 'Right in line with your age cohort';
  }

  final rounded = absoluteDifference >= 10
      ? absoluteDifference.toStringAsFixed(0)
      : absoluteDifference.toStringAsFixed(1);
  return item.difference >= 0
      ? '$rounded points ahead of peers'
      : '$rounded points behind peers';
}

String _comparisonBody(
  PeerComparisonItem item,
  PeerComparisonSnapshot comparison,
  PrimaryFocus primaryFocus,
) {
  if (!item.hasEnoughData) {
    return 'This pillar is still being estimated from limited or stale data. '
        'Track a little more here before treating the score as precise.';
  }

  final notes = <String>[];

  if (item.pillarId == comparison.biggestGapPillarId) {
    notes.add('This is the clearest gap against your age group right now.');
  } else if (item.pillarId == comparison.strongestRelativePillarId) {
    notes.add('This is currently your strongest pillar relative to peers.');
  }

  if (item.pillarId == primaryFocus.pillarId) {
    notes.add('It also matches the area the app is prioritizing first.');
  }

  if (item.difference.abs() < 2) {
    notes.add('You are tracking very close to the cohort average here.');
  } else if (item.difference > 0) {
    notes.add('You are outperforming the age-group average on this pillar.');
  } else {
    notes.add('You are trailing the age-group average on this pillar.');
  }

  return notes.join(' ');
}

_BadgeAppearance _appearanceForDataConfidence(String raw) {
  switch (raw) {
    case 'medium':
      return const _BadgeAppearance(
        label: 'Estimate',
        background: Color(0xFFF3E2C6),
        foreground: AppPalette.amber,
        icon: Icons.tune_rounded,
      );
    default:
      return const _BadgeAppearance(
        label: 'Needs more data',
        background: Color(0xFFE7E1D8),
        foreground: AppPalette.ink,
        icon: Icons.question_mark_rounded,
      );
  }
}

Color _pillarAccent(String pillarId) {
  switch (pillarId) {
    case 'sleep_recovery':
      return AppPalette.moss;
    case 'cardiovascular_health':
      return AppPalette.coral;
    case 'metabolic_health':
      return AppPalette.amber;
    case 'movement_fitness':
      return AppPalette.forest;
    case 'nutrition_quality':
      return const Color(0xFF6D8B3D);
    case 'mental_resilience':
      return AppPalette.wine;
    default:
      return AppPalette.forest;
  }
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : AppPalette.ink;
}

_BadgeAppearance _appearanceForDirection(String raw) {
  switch (raw) {
    case 'on_track':
      return const _BadgeAppearance(
        label: 'On track',
        background: Color(0xFFD4EADF),
        foreground: AppPalette.forest,
        icon: Icons.north_east_rounded,
      );
    case 'mixed':
      return const _BadgeAppearance(
        label: 'Mixed',
        background: Color(0xFFF3E2C6),
        foreground: AppPalette.amber,
        icon: Icons.adjust_rounded,
      );
    case 'drifting':
      return const _BadgeAppearance(
        label: 'Drifting',
        background: Color(0xFFF4D6D0),
        foreground: AppPalette.coral,
        icon: Icons.south_east_rounded,
      );
    case 'improving':
      return const _BadgeAppearance(
        label: 'Improving',
        background: Color(0xFFD4EADF),
        foreground: AppPalette.forest,
        icon: Icons.trending_up_rounded,
      );
    case 'stable':
      return const _BadgeAppearance(
        label: 'Stable',
        background: Color(0xFFE7E1D8),
        foreground: AppPalette.ink,
        icon: Icons.horizontal_rule_rounded,
      );
    default:
      return const _BadgeAppearance(
        label: 'Needs attention',
        background: Color(0xFFF4D6D0),
        foreground: AppPalette.coral,
        icon: Icons.priority_high_rounded,
      );
  }
}

_BadgeAppearance _appearanceForState(String raw) {
  switch (raw) {
    case 'strong':
      return const _BadgeAppearance(
        label: 'Strong',
        background: Color(0xFFD4EADF),
        foreground: AppPalette.forest,
        icon: Icons.star_rounded,
      );
    case 'watch':
      return const _BadgeAppearance(
        label: 'Watch',
        background: Color(0xFFF3E2C6),
        foreground: AppPalette.amber,
        icon: Icons.remove_red_eye_rounded,
      );
    default:
      return const _BadgeAppearance(
        label: 'Needs focus',
        background: Color(0xFFF4D6D0),
        foreground: AppPalette.coral,
        icon: Icons.track_changes_rounded,
      );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeAppearance {
  const _BadgeAppearance({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
}
