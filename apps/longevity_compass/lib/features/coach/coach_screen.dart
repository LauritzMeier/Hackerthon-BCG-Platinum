import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send(DashboardController controller, String message) async {
    _textController.clear();
    await controller.sendCoachMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final experience = controller.experience;
        if (controller.isLoading && experience == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (experience == null) {
          return EmptyStateCard(
            title: 'Coach unavailable',
            body: controller.errorMessage ??
                'The coach needs a patient context before it can respond.',
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (controller.isWelcomeJourney) ...[
              ScreenHeader(
                eyebrow: experience.coach.coachName,
                title: 'Start with the outcome you want, not with busywork.',
                subtitle:
                    'I can help you choose the first data source, explain what each clinic option is for, and keep the setup simple.',
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'How I can help right now',
                subtitle:
                    'This is the guidance that matters before the app has much data.',
                child: Column(
                  children: [
                    _CoachInfoList(
                      title: 'What the first week should feel like',
                      items: experience.journeyStart.startHere,
                    ),
                    if ((controller.customerProfile?.possibilities.isNotEmpty ??
                        false)) ...[
                      const SizedBox(height: 16),
                      _CoachInfoList(
                        title: 'What becomes possible next',
                        items: controller.customerProfile!.possibilities,
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              ScreenHeader(
                eyebrow: experience.coach.coachName,
                title:
                    'Ask about your recovery, your last visit, or your next step.',
                subtitle:
                    'You should not need to start from zero. I already have your last doctor context and your connected watch data.',
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'What I already know',
                subtitle: 'This is the context I use before I answer anything.',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 900;
                    final cards = [
                      _CoachContextCard(
                        title: 'From your last appointment',
                        body: experience.careContext.lastAppointmentSummary,
                        accent: AppPalette.sand.withValues(alpha: 0.82),
                        itemsTitle: 'Priorities now',
                        items: experience.careContext.clinicalPriorities
                            .take(3)
                            .toList(growable: false),
                        footer: experience.careContext.medicalGuardrail,
                      ),
                      _CoachContextCard(
                        title: 'To personalize more',
                        body: experience.dataCoverage.tailoringNote,
                        accent: AppPalette.mint.withValues(alpha: 0.34),
                        itemsTitle: 'Still missing',
                        items: experience.dataCoverage.missingSources
                            .take(3)
                            .toList(growable: false),
                        footer: experience.dataCoverage.needsMealTracking
                            ? 'The fastest improvement is to log one meal a day for 7 days.'
                            : null,
                      ),
                    ];

                    if (stacked) {
                      return Column(
                        children: [
                          for (var index = 0;
                              index < cards.length;
                              index++) ...[
                            cards[index],
                            if (index < cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          Expanded(child: cards[index]),
                          if (index < cards.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Good first questions',
              subtitle: controller.isWelcomeJourney
                  ? 'Start here if you want to set up the journey without overcomplicating it.'
                  : 'Start here if you want the coach to explain the plan in plain language.',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: experience.coach.suggestedPrompts
                    .map(
                      (prompt) => ActionChip(
                        label: Text(prompt),
                        onPressed: () => _send(controller, prompt),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Chat',
              subtitle: controller.isWelcomeJourney
                  ? 'Use this to talk through what to connect first, what to book first, or what outcome you want from the app.'
                  : 'Use this to clarify the plan, explain what changed, or ask what support makes sense next.',
              child: Column(
                children: [
                  for (final message in controller.chatMessages) ...[
                    ChatBubble(message: message),
                    const SizedBox(height: 12),
                  ],
                  if (controller.isSendingMessage)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: controller.isWelcomeJourney
                          ? 'Tell the coach what you want help with, what you can connect, or what feels most important first.'
                          : 'Tell the coach what happened, what your doctor said, or what feels unclear.',
                    ),
                    onSubmitted: (value) => _send(controller, value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: controller.isSendingMessage
                      ? null
                      : () => _send(controller, _textController.text),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CoachInfoList extends StatelessWidget {
  const _CoachInfoList({
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
                        height: 1.4,
                        color: AppPalette.ink.withValues(alpha: 0.76),
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

class _CoachContextCard extends StatelessWidget {
  const _CoachContextCard({
    required this.title,
    required this.body,
    required this.accent,
    this.itemsTitle,
    this.items = const <String>[],
    this.footer,
  });

  final String title;
  final String body;
  final Color accent;
  final String? itemsTitle;
  final List<String> items;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent,
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
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.ink.withValues(alpha: 0.8),
                  height: 1.45,
                ),
          ),
          if (itemsTitle != null && items.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CoachInfoList(
              title: itemsTitle!,
              items: items,
            ),
          ],
          if (footer != null && footer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              footer!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
