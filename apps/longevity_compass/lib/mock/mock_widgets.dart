import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/app_theme.dart';
import 'mock_data.dart';

class MockGlassCard extends StatelessWidget {
  const MockGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 30,
    this.gradient,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: color ?? Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppPalette.ink.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MockBottomBar extends StatelessWidget {
  const MockBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    (icon: Icons.radar_rounded, label: 'Dashboard'),
    (icon: Icons.timelapse_rounded, label: 'Future'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: MockGlassCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        color: Colors.white.withValues(alpha: 0.88),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: _NavButton(
                  label: _items[index].label,
                  icon: _items[index].icon,
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
                  style: GoogleFonts.manrope(
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

class ConversationChip extends StatelessWidget {
  const ConversationChip({
    super.key,
    required this.label,
    required this.preview,
    required this.updatedLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String preview;
  final String updatedLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 218,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected ? AppPalette.ink : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? Colors.white : AppPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.76)
                          : AppPalette.ink.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                updatedLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.66)
                          : AppPalette.ink.withValues(alpha: 0.54),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final MockMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        message.isUser ? AppPalette.ink : Colors.white.withValues(alpha: 0.86);
    final foreground = message.isUser ? Colors.white : AppPalette.ink;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foreground,
                  height: 1.45,
                ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message.timeLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.48),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class RadarSnapshotCard extends StatelessWidget {
  const RadarSnapshotCard({
    super.key,
    required this.metrics,
    required this.selectedMetricId,
    required this.onMetricTap,
    required this.collapsed,
  });

  final List<CompassMetric> metrics;
  final String? selectedMetricId;
  final ValueChanged<String> onMetricTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMetricId == null
        ? metrics.first
        : metrics.firstWhere((metric) => metric.id == selectedMetricId);

    return MockGlassCard(
      radius: 40,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.94),
          AppPalette.sand.withValues(alpha: 0.74),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftChip(
                label: collapsed ? selected.label : 'Tap a factor',
                background: AppPalette.ink.withValues(alpha: 0.08),
                foreground: AppPalette.ink,
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 6,
                decoration: BoxDecoration(
                  color: AppPalette.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IgnorePointer(
              ignoring: collapsed,
              child: Opacity(
                opacity: collapsed ? 0.96 : 1,
                child: RadarMetricSelector(
                  metrics: metrics,
                  selectedMetricId: selectedMetricId,
                  onMetricTap: onMetricTap,
                ),
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 16),
            Text(
              selected.story,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink.withValues(alpha: 0.68),
                    height: 1.38,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class RadarMetricSelector extends StatelessWidget {
  const RadarMetricSelector({
    super.key,
    required this.metrics,
    required this.selectedMetricId,
    required this.onMetricTap,
  });

  final List<CompassMetric> metrics;
  final String? selectedMetricId;
  final ValueChanged<String> onMetricTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final square = size.clamp(220.0, 320.0);
        final center = square / 2;
        final radius = square * 0.31;
        final buttonSize = square * 0.31;

        return Center(
          child: SizedBox(
            width: square,
            height: square,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RadarChartPainter(
                      metrics: metrics,
                      selectedMetricId: selectedMetricId,
                    ),
                  ),
                ),
                for (var index = 0; index < metrics.length; index++)
                  Builder(
                    builder: (context) {
                      final metric = metrics[index];
                      final angle = (-math.pi / 2) +
                          ((2 * math.pi * index) / metrics.length);
                      final anchor = Offset(
                        center + math.cos(angle) * (radius + square * 0.13),
                        center + math.sin(angle) * (radius + square * 0.13),
                      );
                      final isSelected = metric.id == selectedMetricId;

                      return Positioned(
                        left: anchor.dx - (buttonSize / 2),
                        top: anchor.dy - (buttonSize / 2),
                        width: buttonSize,
                        height: buttonSize * 0.72,
                        child: Transform.scale(
                          scale: isSelected ? 1.05 : 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => onMetricTap(metric.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? metric.accent
                                    : Colors.white.withValues(alpha: 0.86),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: metric.accent.withValues(alpha: 0.22),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppPalette.ink.withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      metric.label,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: isSelected
                                            ? Colors.white
                                            : AppPalette.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      metric.displayValue,
                                      style: GoogleFonts.manrope(
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.86)
                                            : AppPalette.ink
                                                .withValues(alpha: 0.74),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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

class MetricTrendCard extends StatelessWidget {
  const MetricTrendCard({
    super.key,
    required this.metric,
    required this.onCollapse,
  });

  final CompassMetric metric;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final latestValue = metric.historyValues.last;
    final minValue = metric.historyValues.reduce(math.min);
    final maxValue = metric.historyValues.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SoftChip(
              label: metric.label,
              background: metric.accent.withValues(alpha: 0.18),
              foreground: AppPalette.ink,
            ),
            const SizedBox(width: 8),
            _SoftChip(
              label: metric.deltaLabel,
              background: Colors.white.withValues(alpha: 0.68),
              foreground: AppPalette.ink.withValues(alpha: 0.82),
            ),
            const Spacer(),
            IconButton(
              onPressed: onCollapse,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: AppPalette.ink,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MockGlassCard(
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.displayValue,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                metric.story,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPalette.ink.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 210,
                child: CustomPaint(
                  painter: MetricTrendPainter(
                    values: metric.historyValues,
                    accent: metric.accent,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: metric.historyLabels
                    .map(
                      (label) => Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.ink.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Current',
                      value: '$latestValue ${metric.unit}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Range',
                      value: '$minValue - $maxValue',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MetricImpactTile extends StatelessWidget {
  const MetricImpactTile({
    super.key,
    required this.impact,
  });

  final MetricImpact impact;

  @override
  Widget build(BuildContext context) {
    final accent = impact.positive ? AppPalette.forest : AppPalette.coral;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              impact.positive ? '+' : '-',
              style: GoogleFonts.spaceGrotesk(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        impact.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppPalette.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    Text(
                      impact.effectLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  impact.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.68),
                        height: 1.38,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  impact.whenLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.52),
                        fontWeight: FontWeight.w700,
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

class TimelineEntryTile extends StatelessWidget {
  const TimelineEntryTile({
    super.key,
    required this.entry,
    required this.isLast,
  });

  final FutureTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final borderColor = entry.isOptional
        ? AppPalette.ink.withValues(alpha: 0.22)
        : AppPalette.ink.withValues(alpha: 0.06);

    final timelineColor = entry.whenLabel == 'Today'
        ? AppPalette.forest
        : entry.isOptional
            ? AppPalette.ink.withValues(alpha: 0.32)
            : AppPalette.moss;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: timelineColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: timelineColor.withValues(alpha: 0.32),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CustomPaint(
                foregroundPainter: entry.isOptional
                    ? DashedRoundedRectPainter(
                        color: borderColor,
                        radius: 26,
                      )
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: entry.isOptional
                        ? Colors.white.withValues(alpha: 0.52)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(26),
                    border: entry.isOptional
                        ? null
                        : Border.all(
                            color: borderColor,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.whenLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppPalette.ink.withValues(alpha: 0.76),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppPalette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.detail,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppPalette.ink.withValues(alpha: 0.7),
                              height: 1.38,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _SoftChip(
                            label: entry.tag,
                            background: entry.isOptional
                                ? AppPalette.ink.withValues(alpha: 0.08)
                                : AppPalette.mint.withValues(alpha: 0.58),
                            foreground: AppPalette.ink,
                          ),
                          if (entry.ctaLabel != null)
                            FilledButton.tonal(
                              onPressed: () {},
                              style: FilledButton.styleFrom(
                                foregroundColor: AppPalette.ink,
                                backgroundColor:
                                    AppPalette.sand.withValues(alpha: 0.82),
                              ),
                              child: Text(entry.ctaLabel!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FutureProjectionCard extends StatelessWidget {
  const FutureProjectionCard({
    super.key,
    required this.projection,
  });

  final FutureProjection projection;

  @override
  Widget build(BuildContext context) {
    return MockGlassCard(
      radius: 34,
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [
          AppPalette.ink,
          AppPalette.forest.withValues(alpha: 0.96),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projection.headline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            projection.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: FutureAuraPainter(),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hiking_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Energetic, strong, and still curious',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final highlight in projection.highlights) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 7,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    highlight,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.sand.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.56),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
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

class DashedRoundedRectPainter extends CustomPainter {
  DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashPath = metric.extractPath(distance, distance + 8);
        canvas.drawPath(dashPath, paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class RadarChartPainter extends CustomPainter {
  RadarChartPainter({
    required this.metrics,
    required this.selectedMetricId,
  });

  final List<CompassMetric> metrics;
  final String? selectedMetricId;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final axisCount = metrics.length;

    final gridPaint = Paint()
      ..color = AppPalette.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final progress = ring / 4;
      final path = Path();

      for (var i = 0; i < axisCount; i++) {
        final angle = (-math.pi / 2) + ((2 * math.pi * i) / axisCount);
        final point = Offset(
          center.dx + math.cos(angle) * radius * progress,
          center.dy + math.sin(angle) * radius * progress,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = AppPalette.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i < axisCount; i++) {
      final angle = (-math.pi / 2) + ((2 * math.pi * i) / axisCount);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, point, axisPaint);
    }

    final selected = selectedMetricId == null
        ? metrics.first
        : metrics.firstWhere((metric) => metric.id == selectedMetricId);

    final fillPath = Path();
    for (var i = 0; i < axisCount; i++) {
      final metric = metrics[i];
      final angle = (-math.pi / 2) + ((2 * math.pi * i) / axisCount);
      final point = Offset(
        center.dx + math.cos(angle) * radius * metric.axisValue,
        center.dy + math.sin(angle) * radius * metric.axisValue,
      );
      if (i == 0) {
        fillPath.moveTo(point.dx, point.dy);
      } else {
        fillPath.lineTo(point.dx, point.dy);
      }
    }
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            selected.accent.withValues(alpha: 0.34),
            selected.accent.withValues(alpha: 0.12),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = selected.accent
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < axisCount; i++) {
      final metric = metrics[i];
      final angle = (-math.pi / 2) + ((2 * math.pi * i) / axisCount);
      final point = Offset(
        center.dx + math.cos(angle) * radius * metric.axisValue,
        center.dy + math.sin(angle) * radius * metric.axisValue,
      );
      canvas.drawCircle(
        point,
        metric.id == selectedMetricId ? 6 : 4.5,
        Paint()..color = metric.accent,
      );
      canvas.drawCircle(
        point,
        metric.id == selectedMetricId ? 10 : 7.5,
        Paint()..color = metric.accent.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.selectedMetricId != selectedMetricId ||
        oldDelegate.metrics != metrics;
  }
}

class MetricTrendPainter extends CustomPainter {
  MetricTrendPainter({
    required this.values,
    required this.accent,
  });

  final List<double> values;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final usableHeight = size.height - 28;
    final usableWidth = size.width - 12;
    final range =
        (maxValue - minValue).abs() < 0.0001 ? 1 : maxValue - minValue;

    final gridPaint = Paint()
      ..color = AppPalette.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = usableHeight * (i / 3);
      canvas.drawLine(
        Offset(0, y + 6),
        Offset(size.width, y + 6),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (usableWidth / (values.length - 1)) * i + 6;
      final normalized = (values[i] - minValue) / range;
      final y = usableHeight - (normalized * usableHeight) + 6;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control = Offset((prev.dx + current.dx) / 2, prev.dy);
      final control2 = Offset((prev.dx + current.dx) / 2, current.dy);
      path.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        current.dx,
        current.dy,
      );
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.24),
            accent.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    for (final point in points) {
      canvas.drawCircle(
        point,
        4.6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        3.2,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MetricTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.accent != accent;
  }
}

class FutureAuraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 4; i++) {
      paint.color = Colors.white.withValues(alpha: 0.08 + (i * 0.04));
      canvas.drawCircle(center, 40 + (i * 28), paint);
    }

    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppPalette.amber.withValues(alpha: 0.28),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.8),
        width: size.width * 0.84,
        height: 56,
      ),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
