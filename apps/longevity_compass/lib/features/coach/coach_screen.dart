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
            ScreenHeader(
              eyebrow: experience.coach.coachName,
              title: 'Talk through what happened and what to do next.',
              subtitle:
                  'A new user should feel like the coach already knows their health context, explains it in plain language, and is honest about what still needs tracking.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'What I already know about you',
              subtitle: experience.careContext.headline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.coach.intro,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.sand.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      experience.careContext.lastAppointmentSummary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: AppPalette.ink.withValues(alpha: 0.82),
                          ),
                    ),
                  ),
                  if (experience.careContext.medications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CoachInfoList(
                      title: 'Medications on file',
                      items: experience.careContext.medications,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'How I can tailor better',
              subtitle: experience.dataCoverage.confidenceLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.dataCoverage.tailoringNote,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  if (experience.dataCoverage.missingSources.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CoachInfoList(
                      title: 'What is still missing',
                      items: experience.dataCoverage.missingSources,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Suggested prompts',
              subtitle:
                  'These prompts should help a new user get oriented without guessing what to ask first.',
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
              title: 'Conversation',
              subtitle:
                  'Use the coach to explain your last visit, your next step, or what would make the plan more personal.',
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
                    decoration: const InputDecoration(
                      hintText:
                          'Tell the coach what happened, what your doctor said, or what feels unclear.',
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
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Conversation sync status',
              subtitle:
                  'Kept for demos and backend handoff checks, but no longer shown as the primary user story.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.firestoreStatusMessage ??
                        'Firebase session status has not been checked yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.isFirebaseEnabled
                        ? 'Authentication mode: Firebase anonymous sign-in.'
                        : 'Enable Firebase with `APP_ENABLE_FIREBASE=true` to persist messages.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              ),
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
