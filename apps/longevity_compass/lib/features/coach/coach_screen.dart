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

        final connectedSignals = experience.dataCoverage.connectedSources
            .take(2)
            .toList(growable: false);
        final missingSignals = experience.dataCoverage.missingSources
            .take(2)
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (controller.isWelcomeJourney) ...[
              ScreenHeader(
                eyebrow: experience.coach.coachName,
                title: 'Tell me what outcome you want first.',
                subtitle:
                    'The coach should narrow the first connection or first clinic step, not give you homework.',
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Start here',
                subtitle:
                    'Keep setup small. One clear goal and one useful connection are enough.',
                child: Column(
                  children: [
                    _CoachInfoList(
                      title: 'Best first moves',
                      items: experience.journeyStart.startHere,
                    ),
                    if ((controller.customerProfile?.possibilities.isNotEmpty ??
                        false)) ...[
                      const SizedBox(height: 16),
                      _CoachInfoList(
                        title: 'What opens up after that',
                        items: controller.customerProfile!.possibilities
                            .take(3)
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              ScreenHeader(
                eyebrow: experience.coach.coachName,
                title: 'Ask one clear question.',
                subtitle:
                    'The coach should answer from your linked care and device context, not from a blank slate.',
              ),
              const SizedBox(height: 24),
              SectionSurface(
                title: 'Answer quality',
                subtitle:
                    'This is the evidence the coach can use before answering.',
                child: Column(
                  children: [
                    _CoachStatusCard(
                      title: controller.usesLiveAgent
                          ? 'Live coach connected'
                          : 'Local guidance mode',
                      body: controller.usesLiveAgent
                          ? 'New questions in this view go to the real patient-specific agent.'
                          : 'The coach is using the loaded experience snapshot, not the live agent.',
                      accent: AppPalette.mint.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    _CoachStatusCard(
                      title: 'Using now',
                      body: connectedSignals.isEmpty
                          ? 'No strong connected data source is shaping the answer yet.'
                          : connectedSignals.join(' '),
                    ),
                    const SizedBox(height: 12),
                    _CoachStatusCard(
                      title: 'Medical context',
                      body: _firstSentence(
                        experience.careContext.lastAppointmentSummary,
                      ),
                      accent: AppPalette.sand.withValues(alpha: 0.82),
                    ),
                    const SizedBox(height: 12),
                    _CoachStatusCard(
                      title: 'Still coarse',
                      body: missingSignals.isEmpty
                          ? 'No major data gap is blocking a useful answer right now.'
                          : missingSignals.first,
                    ),
                    if (experience.careContext.medicalGuardrail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _CoachStatusCard(
                        title: 'Guardrail',
                        body: experience.careContext.medicalGuardrail,
                        accent: AppPalette.sand.withValues(alpha: 0.9),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Start with one of these',
              subtitle: controller.isWelcomeJourney
                  ? 'Use the prompts to decide what to connect or book first.'
                  : 'Use the prompts if you want the coach to explain the plan in plain language.',
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
                  ? 'Use this to choose the first useful connection or first clinic step.'
                  : 'Use this to clarify the plan, explain a change, or compare support options.',
              child: Column(
                children: [
                  if (controller.chatMessages.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPalette.canvas.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.isWelcomeJourney
                            ? 'No messages yet. Start by telling the coach what you want help with first.'
                            : 'No messages yet in this session. Ask a fresh question and the coach should answer from this patient context.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.ink.withValues(alpha: 0.78),
                              height: 1.4,
                            ),
                      ),
                    ),
                  if (controller.chatMessages.isEmpty)
                    const SizedBox(height: 12),
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
                          ? 'Tell the coach the outcome you want, what you can connect, or what feels most important first.'
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

class _CoachStatusCard extends StatelessWidget {
  const _CoachStatusCard({
    required this.title,
    required this.body,
    this.accent,
  });

  final String title;
  final String body;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent ?? Colors.white.withValues(alpha: 0.72),
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
        ],
      ),
    );
  }
}

String _firstSentence(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final match = RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(trimmed);
  return match == null ? trimmed : match.group(0)!.trim();
}
