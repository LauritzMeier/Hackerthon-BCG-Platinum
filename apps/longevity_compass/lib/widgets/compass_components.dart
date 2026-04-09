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
        border: Border.all(
          color: AppPalette.ink.withValues(alpha: 0.05),
        ),
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
  const CompassHeroCard({
    super.key,
    required this.experience,
  });

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
                label: 'Primary focus',
                value: experience.compass.primaryFocus.pillarName,
              ),
              _HeroPill(
                label: 'Patient',
                value: '${experience.profileSummary.country} • ${experience.profileSummary.age}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Your compass says the next strongest longevity lever is ${experience.compass.primaryFocus.pillarName}.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            experience.compass.primaryFocus.whyNow,
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
                    : experience.compass.estimatedBiologicalAge!.toStringAsFixed(1),
              ),
              _HeroMetric(
                label: 'Gap',
                value: ageText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PillarCard extends StatelessWidget {
  const PillarCard({
    super.key,
    required this.pillar,
  });

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
        border: Border.all(
          color: AppPalette.ink.withValues(alpha: 0.05),
        ),
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
            pillar.score.toStringAsFixed(0),
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
  const MetricTrendTile({
    super.key,
    required this.trend,
  });

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
  const ActionTile({
    super.key,
    required this.index,
    required this.action,
  });

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

class OfferTile extends StatelessWidget {
  const OfferTile({
    super.key,
    required this.offer,
    this.highlight = false,
  });

  final OfferOpportunity offer;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          _MiniBadge(
            label: highlight ? 'Recommended now' : 'Additional support',
            background: highlight
                ? Colors.white.withValues(alpha: 0.14)
                : AppPalette.mint.withValues(alpha: 0.7),
            foreground: highlight ? Colors.white : AppPalette.ink,
          ),
          const SizedBox(height: 14),
          Text(
            offer.offerLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: highlight ? Colors.white : AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.rationale,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: highlight
                  ? Colors.white.withValues(alpha: 0.84)
                  : AppPalette.ink.withValues(alpha: 0.72),
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foreground,
                  height: 1.45,
                ),
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
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
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
  const _HeroMetric({
    required this.label,
    required this.value,
  });

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
  const _HeroPill({
    required this.label,
    required this.value,
  });

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
