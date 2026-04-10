import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app/app_theme.dart';
import '../core/models/experience_models.dart';
import '../core/presentation/customer_facing_content.dart';

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
    final sourceLabels = _heroSourceLabels(experience);
    final showBiologicalAge = _hasReliableBiologicalAgeEstimate(experience);
    final biologicalAge = experience.compass.estimatedBiologicalAge;
    final chronologicalAge = experience.compass.chronologicalAge;
    final ageGapYears = experience.profileSummary.ageGapYears ??
        (biologicalAge == null ? null : biologicalAge - chronologicalAge);
    final reliablePillarCount = _reliablePillarCount(experience);

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
                label: 'Precision',
                value: experience.dataCoverage.confidenceLabel,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: showBiologicalAge
                ? _BiologicalAgeNorthStar(
                    biologicalAge: biologicalAge!,
                    chronologicalAge: chronologicalAge,
                    ageGapYears: ageGapYears,
                  )
                : _BiologicalAgePending(
                    reliablePillarCount: reliablePillarCount,
                  ),
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
          Text(
            'Using now',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sourceLabels
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

bool _hasReliableBiologicalAgeEstimate(ExperienceSnapshot experience) {
  if (experience.compass.estimatedBiologicalAge == null) {
    return false;
  }

  return _reliablePillarCount(experience) >= 4;
}

int _reliablePillarCount(ExperienceSnapshot experience) {
  return experience.compass.pillars
      .where((pillar) => pillar.hasEnoughData)
      .length;
}

List<String> _heroSourceLabels(ExperienceSnapshot experience) {
  final labels = <String>[];
  for (final source in experience.dataCoverage.connectedSources) {
    final lower = source.toLowerCase();
    if (lower.contains('smartwatch') || lower.contains('wearable')) {
      labels.add('Smartwatch trends');
    } else if (lower.contains('medical record') || lower.contains('doctor')) {
      labels.add('Doctor context');
    } else if (lower.contains('survey')) {
      labels.add('Lifestyle survey');
    } else if (lower.contains('meal')) {
      labels.add('Meal logging');
    }
  }

  if (labels.isEmpty) {
    labels.add('Limited connected data');
  }

  return labels.toSet().take(3).toList(growable: false);
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
    final showBiologicalAge = _hasReliableBiologicalAgeEstimate(
      widget.experience,
    );
    final biologicalAge = widget.experience.compass.estimatedBiologicalAge;
    final chronologicalAge = widget.experience.compass.chronologicalAge;
    final ageGapYears = widget.experience.profileSummary.ageGapYears ??
        (biologicalAge == null ? null : biologicalAge - chronologicalAge);
    final reliablePillarCount = _reliablePillarCount(widget.experience);
    final primaryFocus = widget.experience.compass.primaryFocus;
    final strongestPillarLabel = _pillarLabelForId(
      comparison.items,
      comparison.strongestRelativePillarId,
    );
    final biggestGapLabel = _pillarLabelForId(
      comparison.items,
      comparison.biggestGapPillarId,
    );
    final unscoredPillars = comparison.items
        .where((item) => !item.hasEnoughData)
        .map((item) => _shortPillarLabel(item.pillarName))
        .toList(growable: false);

    final selectedComparison = comparison.items.firstWhere(
      (item) => item.pillarId == _selectedPillarId,
      orElse: () => comparison.items.first,
    );
    final selectedPillar = widget.experience.compass.pillars.firstWhere(
      (pillar) => pillar.id == selectedComparison.pillarId,
      orElse: () => widget.experience.compass.pillars.first,
    );
    final differenceAppearance = selectedComparison.hasEnoughData
        ? _appearanceForPeerDifference(selectedComparison.difference)
        : _appearanceForDataConfidence(selectedComparison.scoreConfidence);
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
          Text(
            'Longevity compass',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          showBiologicalAge
              ? _CompassNorthStar(
                  biologicalAge: biologicalAge!,
                  chronologicalAge: chronologicalAge,
                  ageGapYears: ageGapYears,
                )
              : _CompassNorthStarPending(
                  reliablePillarCount: reliablePillarCount,
                ),
          const SizedBox(height: 14),
          Text(
            _compassSummaryLine(
              primaryFocusLabel: _shortPillarLabel(primaryFocus.pillarName),
              biggestGapLabel: biggestGapLabel,
              strongestPillarLabel: strongestPillarLabel,
              unscoredPillars: unscoredPillars,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _CompassRadarDiagram(
            items: comparison.items,
            selectedPillarId: _selectedPillarId,
            onSelect: (pillarId) {
              setState(() {
                _selectedPillarId = pillarId;
              });
            },
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPalette.ink.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedComparison.pillarName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      label: selectedComparison.hasEnoughData
                          ? differenceAppearance.label
                          : 'Not scored yet',
                      background: differenceAppearance.background,
                      foreground: differenceAppearance.foreground,
                    ),
                    _MiniBadge(
                      label: trendAppearance.label,
                      background: trendAppearance.background,
                      foreground: trendAppearance.foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedPillarMetricLine(selectedComparison),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPillarSummary(
                    selectedComparison,
                    comparison,
                    primaryFocus,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _PillarTransparencyPanel(pillar: selectedPillar),
              ],
            ),
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
        final canvasSize =
            math.min(constraints.maxWidth, 520.0).clamp(320.0, 520.0);
        final center = canvasSize / 2;
        final radius = canvasSize * 0.29;
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
                      final angle = (-math.pi / 2) +
                          ((2 * math.pi * index) / items.length);
                      final anchor = Offset(
                        center + math.cos(angle) * (radius + 58),
                        center + math.sin(angle) * (radius + 58),
                      );
                      final selected = item.pillarId == selectedPillarId;
                      final accent = _pillarAccent(item.pillarId);
                      final foreground =
                          selected ? _foregroundFor(accent) : AppPalette.ink;

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
                                          item.hasEnoughData
                                              ? item.patientScoreLabel
                                              : '?',
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
    final hasFullComparisonData = items.every((item) => item.hasEnoughData);

    if (hasFullComparisonData) {
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
    } else {
      _drawSegmentedSeries(
        canvas,
        center: center,
        radius: radius,
        items: items,
        scoreSelector: (item) => item.patientScore,
        strokePaint: Paint()
          ..color = AppPalette.forest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

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
      if (!item.hasEnoughData) {
        continue;
      }
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

  void _drawSegmentedSeries(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<PeerComparisonItem> items,
    required double Function(PeerComparisonItem item) scoreSelector,
    required Paint strokePaint,
  }) {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (!item.hasEnoughData) {
        continue;
      }

      final nextIndex = (index + 1) % items.length;
      final nextItem = items[nextIndex];
      if (!nextItem.hasEnoughData) {
        continue;
      }

      final startAngle =
          (-math.pi / 2) + ((2 * math.pi * index) / items.length);
      final endAngle =
          (-math.pi / 2) + ((2 * math.pi * nextIndex) / items.length);
      final startPoint = Offset(
        center.dx +
            math.cos(startAngle) *
                radius *
                _normalizedScore(scoreSelector(item)),
        center.dy +
            math.sin(startAngle) *
                radius *
                _normalizedScore(scoreSelector(item)),
      );
      final endPoint = Offset(
        center.dx +
            math.cos(endAngle) *
                radius *
                _normalizedScore(scoreSelector(nextItem)),
        center.dy +
            math.sin(endAngle) *
                radius *
                _normalizedScore(scoreSelector(nextItem)),
      );
      canvas.drawLine(startPoint, endPoint, strokePaint);
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

enum _SignalTone { positive, warning, neutral }

class _SignalInsight {
  const _SignalInsight({
    required this.label,
    required this.value,
    required this.note,
    required this.tag,
    required this.tone,
  });

  final String label;
  final String value;
  final String note;
  final String tag;
  final _SignalTone tone;
}

class _PillarTransparencyPanel extends StatelessWidget {
  const _PillarTransparencyPanel({required this.pillar});

  final PillarSnapshot pillar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceSummary = _pillarSourceSummary(pillar);
    final insights = _signalInsightsForPillar(pillar);
    final confidenceAppearance = _appearanceForConfidence(pillar);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.canvas.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How this score is built',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: confidenceAppearance.label,
                background: confidenceAppearance.background,
                foreground: confidenceAppearance.foreground,
              ),
              _MiniBadge(
                label: _pillarCalculationFrame(pillar),
                background: AppPalette.sand.withValues(alpha: 0.9),
                foreground: AppPalette.ink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _pillarCalculationSummary(pillar),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          if (pillar.whyItMatters.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pillar.whyItMatters,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ],
          if (sourceSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Data used: $sourceSummary',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.64),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var index = 0; index < insights.length; index++) ...[
              _SignalInsightRow(insight: insights[index]),
              if (index < insights.length - 1) const SizedBox(height: 10),
            ],
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'This pillar is still waiting for enough connected detail to show a deeper breakdown.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.66),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _pillarTrendSummary(pillar),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalInsightRow extends StatelessWidget {
  const _SignalInsightRow({required this.insight});

  final _SignalInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = _appearanceForSignalTone(insight.tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appearance.background.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appearance.background.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  insight.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  insight.value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniBadge(
                label: insight.tag,
                background: appearance.background,
                foreground: appearance.foreground,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  insight.note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.74),
                    height: 1.35,
                  ),
                ),
              ),
            ],
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
  required Future<SupportBooking?> Function(
    OfferOpportunity offer,
    DateTime scheduledFor,
    String scheduledLabel,
  ) onBook,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _OfferDetailSheet(
      offer: offer,
      highlight: highlight,
      hostContext: context,
      onBook: onBook,
    ),
  );
}

Future<SupportBooking?> _noopBookOffer(
  OfferOpportunity offer,
  DateTime scheduledFor,
  String scheduledLabel,
) async {
  return null;
}

Future<void> _showOfferActionSheet(
  BuildContext context,
  OfferOpportunity offer,
  Future<SupportBooking?> Function(
    OfferOpportunity offer,
    DateTime scheduledFor,
    String scheduledLabel,
  ) onBook,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _OfferActionSheet(offer: offer, hostContext: context, onBook: onBook),
  );
}

class OfferTile extends StatelessWidget {
  const OfferTile({
    super.key,
    required this.offer,
    this.onBook = _noopBookOffer,
    this.highlight = false,
  });

  final OfferOpportunity offer;
  final Future<SupportBooking?> Function(
    OfferOpportunity offer,
    DateTime scheduledFor,
    String scheduledLabel,
  ) onBook;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practical = practicalInfoForOffer(offer);
    final foreground = highlight ? Colors.white : AppPalette.ink;
    final secondary = highlight
        ? Colors.white.withValues(alpha: 0.84)
        : AppPalette.ink.withValues(alpha: 0.72);
    final evidencePreview = customerFriendlyOfferEvidence(offer.dataUsed)
        .take(2)
        .toList(growable: false);
    final missingPreview = customerFriendlyMissingData(offer.missingData);

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
                label: highlight ? 'Best next step' : practical.categoryLabel,
                background: highlight
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppPalette.mint.withValues(alpha: 0.7),
                foreground: highlight ? Colors.white : AppPalette.ink,
              ),
              if (practical.locationShortLabel.isNotEmpty)
                _MiniBadge(
                  label: practical.locationShortLabel,
                  background: highlight
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppPalette.sand.withValues(alpha: 0.9),
                  foreground: highlight ? Colors.white : AppPalette.ink,
                ),
              if (practical.priceLabel.isNotEmpty)
                _MiniBadge(
                  label: practical.priceLabel,
                  background: highlight
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  foreground: highlight ? Colors.white : AppPalette.ink,
                ),
              _MiniBadge(
                label: _offerReadinessLabel(offer),
                background: highlight
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppPalette.canvas.withValues(alpha: 0.88),
                foreground: highlight ? Colors.white : AppPalette.ink,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            practical.title,
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
            const SizedBox(height: 16),
            _OfferDecisionRow(
              label: 'Why this now',
              text: offer.whyNow,
              foreground: secondary,
              highlight: highlight,
            ),
          ],
          if (offer.expectedOutcome.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OfferDecisionRow(
              label: 'Expected result',
              text: offer.expectedOutcome,
              foreground: secondary,
              highlight: highlight,
            ),
          ],
          if (evidencePreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OfferDecisionRow(
              label: 'Based on',
              text: evidencePreview.join(' • '),
              foreground: secondary,
              highlight: highlight,
            ),
          ],
          const SizedBox(height: 12),
          _OfferDecisionRow(
            label: 'Practical',
            text: '${practical.formatLabel} • ${practical.locationLabel}',
            foreground: secondary,
            highlight: highlight,
          ),
          if (highlight && offer.missingData.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OfferDecisionRow(
              label: 'Sharper later with',
              text: missingPreview.first,
              foreground: secondary,
              highlight: highlight,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _showOfferActionSheet(context, offer, onBook),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        highlight ? Colors.white : AppPalette.forest,
                    foregroundColor: highlight ? AppPalette.ink : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(offer.primaryActionLabel),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _showOfferDetailSheet(
                  context,
                  offer,
                  highlight: highlight,
                  onBook: onBook,
                ),
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: const Text('Why this'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferDecisionRow extends StatelessWidget {
  const _OfferDecisionRow({
    required this.label,
    required this.text,
    required this.foreground,
    required this.highlight,
  });

  final String label;
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
            Icons.circle,
            size: 16,
            color: highlight ? Colors.white : AppPalette.forest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: foreground, height: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _offerReadinessLabel(OfferOpportunity offer) {
  if (offer.missingData.isEmpty) {
    return 'Ready now';
  }
  if (offer.offerType == 'supplement' || offer.offerType == 'starter') {
    return 'Context first';
  }
  return 'Sharper with more data';
}

class _OfferDetailSheet extends StatelessWidget {
  const _OfferDetailSheet({
    required this.offer,
    required this.highlight,
    required this.hostContext,
    required this.onBook,
  });

  final OfferOpportunity offer;
  final bool highlight;
  final BuildContext hostContext;
  final Future<SupportBooking?> Function(
    OfferOpportunity offer,
    DateTime scheduledFor,
    String scheduledLabel,
  ) onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practical = practicalInfoForOffer(offer);
    final friendlyEvidence = customerFriendlyOfferEvidence(offer.dataUsed);
    final friendlyMissing = customerFriendlyMissingData(offer.missingData);

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
                                : practical.categoryLabel,
                            background: AppPalette.mint.withValues(alpha: 0.85),
                            foreground: AppPalette.ink,
                          ),
                          if (practical.locationShortLabel.isNotEmpty)
                            _MiniBadge(
                              label: practical.locationShortLabel,
                              background: AppPalette.sand,
                              foreground: AppPalette.ink,
                            ),
                          if (practical.priceLabel.isNotEmpty)
                            _MiniBadge(
                              label: practical.priceLabel,
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
                  practical.title,
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
                  title: 'What this is based on',
                  items: friendlyEvidence,
                ),
                _OfferDetailListSection(
                  title: 'Practical details',
                  items: practical.detailLines,
                ),
                if (offer.missingData.isNotEmpty)
                  _OfferDetailListSection(
                    title: 'What would make this even sharper',
                    items: friendlyMissing,
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
                            () => _showOfferActionSheet(
                              hostContext,
                              offer,
                              onBook,
                            ),
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

class _OfferActionSheet extends StatefulWidget {
  const _OfferActionSheet({
    required this.offer,
    required this.hostContext,
    required this.onBook,
  });

  final OfferOpportunity offer;
  final BuildContext hostContext;
  final Future<SupportBooking?> Function(
    OfferOpportunity offer,
    DateTime scheduledFor,
    String scheduledLabel,
  ) onBook;

  @override
  State<_OfferActionSheet> createState() => _OfferActionSheetState();
}

class _OfferActionSheetState extends State<_OfferActionSheet> {
  int _selectedSlotIndex = 0;
  bool _isBooking = false;

  String get _headline {
    switch (widget.offer.offerType) {
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
    final practical = practicalInfoForOffer(widget.offer);
    switch (widget.offer.offerType) {
      case 'appointment':
      case 'appointment_prep':
        return 'This books ${practical.title.toLowerCase()} with the clinic team and confirms the final visit format.';
      case 'diagnostic':
        return 'This books the right lab slot and makes sure the clinic team has the results for the next decision.';
      case 'program':
      case 'coaching':
        return 'This starts a guided intake so the plan matches your current recovery stage instead of staying generic.';
      case 'supplement':
        return 'This sets up a clinician-reviewed supplement discussion so you do not have to guess what is safe or useful.';
      case 'starter':
        return 'This starts a light in-app plan so you can build signal before committing to a clinic visit.';
      default:
        return 'This moves you into the next guided support step.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practical = practicalInfoForOffer(widget.offer);
    final nextSteps = widget.offer.firstWeek.isNotEmpty
        ? widget.offer.firstWeek.take(3).toList(growable: false)
        : widget.offer.includes.take(3).toList(growable: false);
    final slots = _buildOfferSlots(widget.offer);
    final selectedSlot = slots.isEmpty
        ? null
        : slots[_selectedSlotIndex.clamp(0, slots.length - 1)];

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
                  practical.title,
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
                if (practical.locationShortLabel.isNotEmpty ||
                    practical.priceLabel.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (practical.locationShortLabel.isNotEmpty)
                        _MiniBadge(
                          label: practical.locationShortLabel,
                          background: AppPalette.mint.withValues(alpha: 0.7),
                          foreground: AppPalette.ink,
                        ),
                      if (practical.priceLabel.isNotEmpty)
                        _MiniBadge(
                          label: practical.priceLabel,
                          background: AppPalette.sand,
                          foreground: AppPalette.ink,
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                _OfferDetailListSection(
                  title: 'Practical details',
                  items: practical.detailLines,
                ),
                if (nextSteps.isNotEmpty) ...[
                  _OfferDetailListSection(
                    title: 'What happens next',
                    items: nextSteps,
                  ),
                ],
                if (slots.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Available demo slots',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var index = 0; index < slots.length; index++)
                        ChoiceChip(
                          label: Text(slots[index].label),
                          selected: index == _selectedSlotIndex,
                          onSelected: _isBooking
                              ? null
                              : (selected) {
                                  if (!selected) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedSlotIndex = index;
                                  });
                                },
                          selectedColor:
                              AppPalette.mint.withValues(alpha: 0.86),
                          backgroundColor: Colors.white,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.ink,
                            fontWeight: index == _selectedSlotIndex
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: index == _selectedSlotIndex
                                ? AppPalette.forest
                                : AppPalette.ink.withValues(alpha: 0.08),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedSlot == null || _isBooking
                            ? null
                            : () async {
                                setState(() {
                                  _isBooking = true;
                                });
                                final booking = await widget.onBook(
                                  widget.offer,
                                  selectedSlot.scheduledFor,
                                  selectedSlot.label,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                setState(() {
                                  _isBooking = false;
                                });
                                Navigator.of(context).pop();
                                if (booking != null) {
                                  ScaffoldMessenger.of(widget.hostContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Booked ${practical.title} for ${selectedSlot.label}.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          _isBooking
                              ? 'Booking...'
                              : widget.offer.primaryActionLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed:
                          _isBooking ? null : () => Navigator.of(context).pop(),
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

class _OfferSlotOption {
  const _OfferSlotOption({
    required this.label,
    required this.scheduledFor,
  });

  final String label;
  final DateTime scheduledFor;
}

List<_OfferSlotOption> _buildOfferSlots(OfferOpportunity offer) {
  final now = DateTime.now();
  final practical = practicalInfoForOffer(offer);
  final baseHour = switch (offer.offerType) {
    'diagnostic' => 8,
    'program' || 'coaching' => 10,
    'supplement' => 15,
    _ => 9,
  };
  final offsets = switch (offer.offerType) {
    'diagnostic' => <int>[3, 6, 10],
    'program' || 'coaching' => <int>[2, 5, 9],
    'starter' => <int>[1, 3, 7],
    _ => <int>[2, 5, 8],
  };

  final formatter = DateFormat('EEE d MMM • HH:mm');
  return offsets.map((days) {
    final scheduledFor = DateTime(
      now.year,
      now.month,
      now.day + days,
      baseHour,
      days == offsets.first ? 0 : 30,
    );
    return _OfferSlotOption(
      label:
          '${formatter.format(scheduledFor)} • ${practical.locationShortLabel}',
      scheduledFor: scheduledFor,
    );
  }).toList(growable: false);
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
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final background =
        message.isUser ? AppPalette.ink : Colors.white.withValues(alpha: 0.88);
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
      return 'Cardiovascular';
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

String _pillarLabelForId(List<PeerComparisonItem> items, String pillarId) {
  for (final item in items) {
    if (item.pillarId == pillarId) {
      return _shortPillarLabel(item.pillarName);
    }
  }
  return '';
}

String _selectedPillarSummary(
  PeerComparisonItem item,
  PeerComparisonSnapshot comparison,
  PrimaryFocus primaryFocus,
) {
  if (!item.hasEnoughData) {
    return 'Your score is still hidden here until more recent tracking is connected. The age-group line stays visible for orientation.';
  }

  final notes = <String>[];
  if (item.pillarId == primaryFocus.pillarId) {
    notes.add('Main focus this week.');
  }
  if (item.pillarId == comparison.biggestGapPillarId) {
    notes.add('This is your biggest gap right now.');
  } else if (item.pillarId == comparison.strongestRelativePillarId) {
    notes.add('This is your strongest relative pillar.');
  }

  if (item.difference.abs() < 2) {
    notes.add('You are close to the age-group average.');
  } else if (item.difference > 0) {
    notes.add('You are ahead of the age-group average.');
  } else {
    notes.add('You are below the age-group average.');
  }

  return notes.join(' ');
}

String _compassSummaryLine({
  required String primaryFocusLabel,
  required String biggestGapLabel,
  required String strongestPillarLabel,
  required List<String> unscoredPillars,
}) {
  final parts = <String>[];
  parts.add('Focus now on $primaryFocusLabel.');
  if (biggestGapLabel.isNotEmpty) {
    parts.add('Biggest gap: $biggestGapLabel.');
  }
  if (strongestPillarLabel.isNotEmpty) {
    parts.add('Strongest: $strongestPillarLabel.');
  }
  if (unscoredPillars.isNotEmpty) {
    parts.add('Not scored yet: ${unscoredPillars.join(', ')}.');
  }
  return parts.join(' ');
}

String _selectedPillarMetricLine(PeerComparisonItem item) {
  final youValue = item.hasEnoughData ? item.patientScoreLabel : '?';
  return 'You $youValue  •  Age group ${item.peerScoreLabel}';
}

_BadgeAppearance _appearanceForConfidence(PillarSnapshot pillar) {
  if (!pillar.hasEnoughData || pillar.scoreConfidence == 'low') {
    return const _BadgeAppearance(
      label: 'Estimate only',
      background: Color(0xFFE7E1D8),
      foreground: AppPalette.ink,
      icon: Icons.question_mark_rounded,
    );
  }
  if (pillar.scoreConfidence == 'medium') {
    return const _BadgeAppearance(
      label: 'Medium confidence',
      background: Color(0xFFF3E2C6),
      foreground: AppPalette.amber,
      icon: Icons.tune_rounded,
    );
  }
  return const _BadgeAppearance(
    label: 'High confidence',
    background: Color(0xFFDDF0E3),
    foreground: AppPalette.forest,
    icon: Icons.verified_rounded,
  );
}

_BadgeAppearance _appearanceForSignalTone(_SignalTone tone) {
  switch (tone) {
    case _SignalTone.positive:
      return const _BadgeAppearance(
        label: 'Helps',
        background: Color(0xFFDDF0E3),
        foreground: AppPalette.forest,
        icon: Icons.arrow_upward_rounded,
      );
    case _SignalTone.warning:
      return const _BadgeAppearance(
        label: 'Pressure',
        background: Color(0xFFF8DDD7),
        foreground: AppPalette.coral,
        icon: Icons.arrow_downward_rounded,
      );
    case _SignalTone.neutral:
      return const _BadgeAppearance(
        label: 'Context',
        background: Color(0xFFF3E2C6),
        foreground: AppPalette.amber,
        icon: Icons.remove_rounded,
      );
  }
}

String _pillarCalculationFrame(PillarSnapshot pillar) {
  switch (pillar.id) {
    case 'sleep_recovery':
      return '30d score • recent trend';
    case 'cardiovascular_health':
      return 'risk + recovery blend';
    case 'metabolic_health':
      return 'lab-driven estimate';
    case 'movement_fitness':
      return '30d volume • 7d trend';
    case 'nutrition_quality':
      return 'habit score';
    case 'mental_resilience':
      return 'survey-led estimate';
    default:
      return 'Composite score';
  }
}

String _pillarCalculationSummary(PillarSnapshot pillar) {
  switch (pillar.id) {
    case 'sleep_recovery':
      return 'Sleep uses your 30-day sleep quality and duration as the main score, while deep sleep and the last 7 days explain whether recovery is drifting or stabilizing.';
    case 'cardiovascular_health':
      return 'Cardiovascular health blends resting heart rate, HRV, blood pressure, LDL, walking volume, and cardiac history. Recent acute heart events can cap the score during recovery.';
    case 'metabolic_health':
      return 'Metabolic health is mostly driven by labs and body composition, especially HbA1c, fasting glucose, LDL, triglycerides, and BMI.';
    case 'movement_fitness':
      return 'Movement combines your 30-day steps, active minutes, and exercise frequency. The trend checks whether the last 7 days are moving above or below that baseline.';
    case 'nutrition_quality':
      return 'Nutrition quality combines diet quality, fruit and veg intake, hydration, and alcohol load, with inflammation acting as supporting context.';
    case 'mental_resilience':
      return 'Mental resilience combines perceived stress, WHO-5 wellbeing, self-rated health, and sleep satisfaction to estimate how sustainable your current routine feels.';
    default:
      return 'This pillar combines several connected inputs rather than using a single metric.';
  }
}

String _pillarTrendSummary(PillarSnapshot pillar) {
  switch (pillar.id) {
    case 'sleep_recovery':
      return 'Trend checks whether the last 7 days of sleep are better or worse than the 30-day baseline.';
    case 'cardiovascular_health':
      return 'Trend compares recent resting heart rate and HRV with the 30-day baseline. Recent cardiac events can keep the trend cautious even if wearables briefly look steadier.';
    case 'movement_fitness':
      return 'Trend compares the last 7 days of steps and active minutes with the 30-day baseline.';
    case 'metabolic_health':
      return 'Metabolic trend moves more slowly and usually changes when new labs or meaningful coaching updates arrive.';
    case 'nutrition_quality':
      return 'Nutrition trend depends more on survey and coach updates than passive wearable data, so it changes less often.';
    case 'mental_resilience':
      return 'Mental resilience trend reflects stress, wellbeing, and recovery context rather than one live sensor.';
    default:
      return 'Trend compares the latest connected signal with the broader baseline available for this pillar.';
  }
}

String _pillarSourceSummary(PillarSnapshot pillar) {
  final labels = pillar.dataSources
      .map(_friendlyDataSourceLabel)
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (labels.isNotEmpty) {
    return labels.join(' + ');
  }

  switch (pillar.id) {
    case 'sleep_recovery':
      return 'wearable sleep trends';
    case 'cardiovascular_health':
      return 'wearable recovery + clinical cardio markers';
    case 'metabolic_health':
      return 'labs + clinical baseline';
    case 'movement_fitness':
      return 'wearable activity + exercise history';
    case 'nutrition_quality':
      return 'survey nutrition habits + inflammation context';
    case 'mental_resilience':
      return 'survey wellbeing + recovery context';
    default:
      return '';
  }
}

String _friendlyDataSourceLabel(String raw) {
  switch (raw) {
    case 'curated.patient_metrics':
      return 'wearable trends';
    case 'curated.patient_profile':
      return 'clinical and survey baseline';
    case 'patient_reported_chat_updates':
      return 'coach updates';
    default:
      return raw.replaceAll('_', ' ');
  }
}

dynamic _firstSignalValue(Map<String, dynamic> signals, List<String> keys) {
  for (final key in keys) {
    if (!signals.containsKey(key)) {
      continue;
    }
    final value = signals[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    return value;
  }
  return null;
}

double? _signalNumber(Map<String, dynamic> signals, List<String> keys) {
  final value = _firstSignalValue(signals, keys);
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String _formatSignalNumber(
  double value, {
  int digits = 0,
  String suffix = '',
}) {
  final roundedValue = digits == 0 ? value.roundToDouble() : value;
  final label = digits == 0
      ? roundedValue.toStringAsFixed(0)
      : roundedValue.toStringAsFixed(digits);
  return '$label$suffix';
}

List<_SignalInsight> _signalInsightsForPillar(PillarSnapshot pillar) {
  final signals = pillar.keySignals;
  final insights = <_SignalInsight>[];

  switch (pillar.id) {
    case 'sleep_recovery':
      final quality30 = _signalNumber(signals, ['sleep_quality_30d_avg']);
      if (quality30 != null) {
        final tone = quality30 >= 80
            ? _SignalTone.positive
            : (quality30 >= 70 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day sleep quality',
            value: '${_formatSignalNumber(quality30)}/100',
            note: quality30 >= 80
                ? 'Sleep quality is consistently strong and helping recovery.'
                : (quality30 >= 70
                    ? 'Quality is acceptable but not yet fully restorative.'
                    : 'Quality is too low to support strong recovery.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final duration30 = _signalNumber(
        signals,
        ['sleep_duration_30d_avg', 'sleep_duration_30d_avg_hrs'],
      );
      if (duration30 != null) {
        final tone = duration30 >= 7.0 && duration30 <= 8.5
            ? _SignalTone.positive
            : (duration30 >= 6.0 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day sleep duration',
            value: '${_formatSignalNumber(duration30, digits: 1)} h',
            note: duration30 >= 7.0 && duration30 <= 8.5
                ? 'Sleep duration is in the zone the score wants to see.'
                : (duration30 >= 6.0
                    ? 'Duration is a little short, so the score stays cautious.'
                    : 'Short sleep is a major drag on this pillar.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final deepSleep = _signalNumber(signals, ['deep_sleep_30d_avg_pct']);
      if (deepSleep != null) {
        final tone = deepSleep >= 20
            ? _SignalTone.positive
            : (deepSleep >= 16 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day deep sleep share',
            value: '${_formatSignalNumber(deepSleep, digits: 1)}%',
            note: deepSleep >= 20
                ? 'Restorative sleep is showing up often enough to help the score.'
                : (deepSleep >= 16
                    ? 'Deep sleep is present but not especially strong.'
                    : 'Low deep sleep makes the recovery picture weaker.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
    case 'cardiovascular_health':
      final recentEventDays = _signalNumber(
        signals,
        ['recent_acute_cardiac_event_days_ago'],
      );
      if (recentEventDays != null) {
        insights.add(
          _SignalInsight(
            label: 'Recent acute cardiac event',
            value: '${_formatSignalNumber(recentEventDays)} days ago',
            note: recentEventDays <= 30
                ? 'A very recent event keeps the score capped during recovery.'
                : 'A recent event still keeps the score conservative.',
            tag: 'Pressure',
            tone: _SignalTone.warning,
          ),
        );
      }
      final restingHr = _signalNumber(signals, ['resting_hr_30d_avg']);
      if (restingHr != null) {
        final tone = restingHr <= 65
            ? _SignalTone.positive
            : (restingHr <= 75 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day resting heart rate',
            value: '${_formatSignalNumber(restingHr)} bpm',
            note: restingHr <= 65
                ? 'Resting heart rate is supporting resilience.'
                : (restingHr <= 75
                    ? 'Resting heart rate is acceptable but not ideal.'
                    : 'Resting heart rate is high for a strong cardio score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final hrv = _signalNumber(signals, ['hrv_30d_avg']);
      if (hrv != null) {
        final tone = hrv >= 35
            ? _SignalTone.positive
            : (hrv >= 28 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day HRV',
            value: '${_formatSignalNumber(hrv, digits: 1)} ms',
            note: hrv >= 35
                ? 'HRV is helping the recovery side of the score.'
                : (hrv >= 28
                    ? 'HRV is workable but not especially strong.'
                    : 'Lower HRV keeps the score under pressure.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final sbp = _signalNumber(signals, ['sbp_mmhg']);
      final dbp = _signalNumber(signals, ['dbp_mmhg']);
      if (sbp != null || dbp != null) {
        final tone = (sbp != null && sbp < 120) && (dbp != null && dbp < 80)
            ? _SignalTone.positive
            : ((sbp != null && sbp < 130) && (dbp != null && dbp < 80)
                ? _SignalTone.neutral
                : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Blood pressure',
            value:
                '${sbp != null ? _formatSignalNumber(sbp) : '?'} / ${dbp != null ? _formatSignalNumber(dbp) : '?'} mmHg',
            note: tone == _SignalTone.positive
                ? 'Blood pressure is at goal and helping the score.'
                : (tone == _SignalTone.warning
                    ? 'Blood pressure is above the ideal cardio range.'
                    : 'Blood pressure is close to target but not fully there.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final ldl = _signalNumber(signals, ['ldl_mmol']);
      final ldlTarget = _signalNumber(
        signals,
        ['secondary_prevention_ldl_target_mmol'],
      );
      if (ldl != null) {
        final target = ldlTarget ?? 2.6;
        final tone = ldl <= target
            ? _SignalTone.positive
            : (ldl <= target + 0.7 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'LDL cholesterol',
            value: '${_formatSignalNumber(ldl, digits: 2)} mmol/L',
            note: ldl <= target
                ? 'LDL is at or below the current target.'
                : (ldl <= target + 0.7
                    ? 'LDL is still above target, keeping the score cautious.'
                    : 'LDL is well above target and materially drags the score down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
    case 'metabolic_health':
      final hba1c = _signalNumber(signals, ['hba1c_pct']);
      if (hba1c != null) {
        final tone = hba1c < 5.7
            ? _SignalTone.positive
            : (hba1c < 6.5 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'HbA1c',
            value: '${_formatSignalNumber(hba1c, digits: 1)}%',
            note: hba1c < 5.7
                ? 'HbA1c is in range and helping the score.'
                : (hba1c < 6.5
                    ? 'HbA1c is elevated, so the score stays cautious.'
                    : 'HbA1c is in the diabetic range and strongly lowers the score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final glucose = _signalNumber(signals, ['fasting_glucose_mmol']);
      if (glucose != null) {
        final tone = glucose < 5.6
            ? _SignalTone.positive
            : (glucose < 7.0 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Fasting glucose',
            value: '${_formatSignalNumber(glucose, digits: 1)} mmol/L',
            note: glucose < 5.6
                ? 'Fasting glucose is supporting a stronger metabolic score.'
                : (glucose < 7.0
                    ? 'Fasting glucose is above ideal and keeps the score cautious.'
                    : 'Fasting glucose is high and meaningfully lowers the score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final bmi = _signalNumber(signals, ['bmi']);
      if (bmi != null) {
        final tone = bmi < 25
            ? _SignalTone.positive
            : (bmi < 30 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'BMI',
            value: _formatSignalNumber(bmi, digits: 1),
            note: bmi < 25
                ? 'Body composition is helping the metabolic score.'
                : (bmi < 30
                    ? 'BMI adds some pressure but is not the main issue.'
                    : 'BMI is high enough to materially drag the score down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final ldl = _signalNumber(signals, ['ldl_mmol']);
      if (ldl != null) {
        final tone = ldl <= 2.6
            ? _SignalTone.positive
            : (ldl <= 3.4 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'LDL cholesterol',
            value: '${_formatSignalNumber(ldl, digits: 2)} mmol/L',
            note: ldl <= 2.6
                ? 'LDL is in a range that supports a stronger metabolic score.'
                : (ldl <= 3.4
                    ? 'LDL is above ideal and keeps the score from rising.'
                    : 'LDL is high enough to meaningfully lower this pillar.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
    case 'movement_fitness':
      final steps30 = _signalNumber(signals, ['steps_30d_avg']);
      if (steps30 != null) {
        final tone = steps30 >= 9000
            ? _SignalTone.positive
            : (steps30 >= 7000 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day daily steps',
            value: _formatSignalNumber(steps30),
            note: steps30 >= 9000
                ? 'Step volume is strong and lifting the score.'
                : (steps30 >= 7000
                    ? 'Step volume is decent but not yet a strong advantage.'
                    : 'Daily movement volume is below the target range.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final active30 = _signalNumber(signals, ['active_minutes_30d_avg']);
      if (active30 != null) {
        final tone = active30 >= 45
            ? _SignalTone.positive
            : (active30 >= 25 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: '30-day active minutes',
            value: '${_formatSignalNumber(active30)} min/day',
            note: active30 >= 45
                ? 'Active minutes are high enough to help the score clearly.'
                : (active30 >= 25
                    ? 'Activity is building but still short of a strong baseline.'
                    : 'Moderate-to-vigorous activity is too low for a strong score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Steady'),
            tone: tone,
          ),
        );
      }
      final exercise = _signalNumber(signals, ['exercise_sessions_weekly']);
      if (exercise != null) {
        final tone = exercise >= 4
            ? _SignalTone.positive
            : (exercise >= 2 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Exercise sessions per week',
            value: _formatSignalNumber(exercise, digits: 1),
            note: exercise >= 4
                ? 'Weekly exercise structure is helping this pillar.'
                : (exercise >= 2
                    ? 'There is some structure, but not enough to drive a strong score.'
                    : 'Too few dedicated sessions are showing up each week.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final sedentary = _signalNumber(signals, ['sedentary_hrs_day']);
      if (sedentary != null) {
        final tone = sedentary <= 6
            ? _SignalTone.positive
            : (sedentary <= 8 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Sedentary time',
            value: '${_formatSignalNumber(sedentary, digits: 1)} h/day',
            note: sedentary <= 6
                ? 'Sitting time is low enough to help movement quality.'
                : (sedentary <= 8
                    ? 'Sedentary time is manageable but still worth tightening.'
                    : 'Long sitting time is dragging the score down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
    case 'nutrition_quality':
      final diet = _signalNumber(signals, ['diet_quality_score']);
      if (diet != null) {
        final tone = diet >= 7
            ? _SignalTone.positive
            : (diet >= 5 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Diet quality',
            value: '${_formatSignalNumber(diet, digits: 1)}/10',
            note: diet >= 7
                ? 'Diet quality is supporting the score.'
                : (diet >= 5
                    ? 'Diet quality looks mixed, so the score stays cautious.'
                    : 'Diet quality is low enough to pull this pillar down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final fruitVeg = _signalNumber(signals, ['fruit_veg_servings_daily']);
      if (fruitVeg != null) {
        final tone = fruitVeg >= 5
            ? _SignalTone.positive
            : (fruitVeg >= 3 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Fruit and veg',
            value: '${_formatSignalNumber(fruitVeg, digits: 1)} servings/day',
            note: fruitVeg >= 5
                ? 'Plant intake is in the target range.'
                : (fruitVeg >= 3
                    ? 'Plant intake is improving but still below target.'
                    : 'Plant intake is low for a stronger nutrition score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final water = _signalNumber(signals, ['water_glasses_daily']);
      if (water != null) {
        final tone = water >= 8
            ? _SignalTone.positive
            : (water >= 6 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Hydration',
            value: '${_formatSignalNumber(water)} glasses/day',
            note: water >= 8
                ? 'Hydration is supporting the score.'
                : (water >= 6
                    ? 'Hydration is okay but not yet ideal.'
                    : 'Hydration looks light for a stronger nutrition score.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final alcohol = _signalNumber(
        signals,
        ['alcohol_units_weekly', 'current_alcohol_units_weekly'],
      );
      if (alcohol != null) {
        final tone = alcohol <= 10
            ? _SignalTone.positive
            : (alcohol <= 14 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Alcohol load',
            value: '${_formatSignalNumber(alcohol, digits: 1)} units/week',
            note: alcohol <= 10
                ? 'Alcohol is not adding much pressure to the score.'
                : (alcohol <= 14
                    ? 'Alcohol is slightly above the cleaner baseline for this pillar.'
                    : 'Alcohol load is high enough to drag the score down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
    case 'mental_resilience':
      final stress = _signalNumber(signals, ['stress_level']);
      if (stress != null) {
        final tone = stress <= 4
            ? _SignalTone.positive
            : (stress <= 6 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Stress level',
            value: '${_formatSignalNumber(stress, digits: 1)}/10',
            note: stress <= 4
                ? 'Stress looks manageable and helps resilience.'
                : (stress <= 6
                    ? 'Stress is elevated enough to keep the score cautious.'
                    : 'High stress is a major drag on this pillar.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final wellbeing = _signalNumber(signals, ['mental_wellbeing_who5']);
      if (wellbeing != null) {
        final tone = wellbeing >= 18
            ? _SignalTone.positive
            : (wellbeing >= 13 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'WHO-5 wellbeing',
            value: '${_formatSignalNumber(wellbeing)}/25',
            note: wellbeing >= 18
                ? 'Wellbeing is in a range that supports resilience.'
                : (wellbeing >= 13
                    ? 'Wellbeing looks mixed, so the score stays cautious.'
                    : 'Low wellbeing is pulling the score down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final selfRated = _signalNumber(signals, ['self_rated_health']);
      if (selfRated != null) {
        final tone = selfRated >= 4
            ? _SignalTone.positive
            : (selfRated >= 3 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Self-rated health',
            value: '${_formatSignalNumber(selfRated, digits: 1)}/5',
            note: selfRated >= 4
                ? 'You currently perceive your health as supportive.'
                : (selfRated >= 3
                    ? 'Your self-rating is middling, which keeps this pillar cautious.'
                    : 'Low self-rated health is a strong warning sign for this pillar.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      final sleepSat = _signalNumber(signals, ['sleep_satisfaction']);
      if (sleepSat != null) {
        final tone = sleepSat >= 5
            ? _SignalTone.positive
            : (sleepSat >= 4 ? _SignalTone.neutral : _SignalTone.warning);
        insights.add(
          _SignalInsight(
            label: 'Sleep satisfaction',
            value: '${_formatSignalNumber(sleepSat, digits: 1)}/7',
            note: sleepSat >= 5
                ? 'Sleep satisfaction is reinforcing resilience.'
                : (sleepSat >= 4
                    ? 'Sleep feels mixed, so this pillar stays watchful.'
                    : 'Poor sleep satisfaction is pulling resilience down.'),
            tag: tone == _SignalTone.positive
                ? 'Helps'
                : (tone == _SignalTone.warning ? 'Pressure' : 'Context'),
            tone: tone,
          ),
        );
      }
      break;
  }

  if (insights.isNotEmpty) {
    return insights;
  }

  return signals.entries.take(4).map((entry) {
    return _SignalInsight(
      label: _prettifySignalKey(entry.key),
      value: entry.value is num
          ? _formatSignalNumber((entry.value as num).toDouble(), digits: 1)
          : entry.value.toString(),
      note: 'This signal is part of the context behind the current score.',
      tag: 'Context',
      tone: _SignalTone.neutral,
    );
  }).toList(growable: false);
}

String _prettifySignalKey(String key) {
  return key
      .replaceAll('_', ' ')
      .replaceAll('avg', 'avg.')
      .replaceAll('mmhg', 'mmHg')
      .replaceAll('pct', '%')
      .trim();
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

_BadgeAppearance _appearanceForPeerDifference(double difference) {
  if (difference.abs() < 2) {
    return const _BadgeAppearance(
      label: 'In line with peers',
      background: Color(0xFFE7E1D8),
      foreground: AppPalette.ink,
      icon: Icons.horizontal_rule_rounded,
    );
  }
  if (difference > 0) {
    return const _BadgeAppearance(
      label: 'Ahead of peers',
      background: Color(0xFFD4EADF),
      foreground: AppPalette.forest,
      icon: Icons.north_east_rounded,
    );
  }
  return const _BadgeAppearance(
    label: 'Below peers',
    background: Color(0xFFF4D6D0),
    foreground: AppPalette.coral,
    icon: Icons.south_east_rounded,
  );
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

class _CompassNorthStar extends StatelessWidget {
  const _CompassNorthStar({
    required this.biologicalAge,
    required this.chronologicalAge,
    required this.ageGapYears,
  });

  final double biologicalAge;
  final int chronologicalAge;
  final double? ageGapYears;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biological age',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              biologicalAge.toStringAsFixed(1),
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppPalette.canvas.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${_ageGapLabel(ageGapYears)} vs calendar age $chronologicalAge',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _ageGapColor(ageGapYears),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassNorthStarPending extends StatelessWidget {
  const _CompassNorthStarPending({required this.reliablePillarCount});

  final int reliablePillarCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biological age',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '--',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppPalette.canvas.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '$reliablePillarCount of 6 pillars scored',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BiologicalAgeNorthStar extends StatelessWidget {
  const _BiologicalAgeNorthStar({
    required this.biologicalAge,
    required this.chronologicalAge,
    required this.ageGapYears,
  });

  final double biologicalAge;
  final int chronologicalAge;
  final double? ageGapYears;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ageGapLabel = _ageGapLabel(ageGapYears);
    final ageGapColor = _ageGapColor(ageGapYears);

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'North star',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: biologicalAge.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' biological age',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar age $chronologicalAge',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ageGapLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ageGapColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is the single summary number built from the six pillars when enough of them are scored confidently.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BiologicalAgePending extends StatelessWidget {
  const _BiologicalAgePending({required this.reliablePillarCount});

  final int reliablePillarCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'North star',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Biological age is still calibrating.',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$reliablePillarCount of 6 pillars are scored confidently. We will show a single biological age once at least 4 pillars are reliable.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.45,
          ),
        ),
      ],
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

String _ageGapLabel(double? ageGapYears) {
  if (ageGapYears == null) {
    return 'Still calibrating';
  }

  final absoluteGap = ageGapYears.abs();
  if (absoluteGap < 0.3) {
    return 'In line with calendar age';
  }

  final rounded = absoluteGap >= 10
      ? absoluteGap.toStringAsFixed(0)
      : absoluteGap.toStringAsFixed(1);
  return ageGapYears < 0 ? '$rounded years younger' : '$rounded years older';
}

Color _ageGapColor(double? ageGapYears) {
  if (ageGapYears == null) {
    return Colors.white;
  }
  if (ageGapYears < -0.3) {
    return AppPalette.mint;
  }
  if (ageGapYears > 0.3) {
    return AppPalette.coral;
  }
  return Colors.white;
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
