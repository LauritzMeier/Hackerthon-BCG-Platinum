import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              title: 'Ask why your compass changed, or what to do next.',
              subtitle:
                  'The coach is designed as the conversational interface to the six-pillar model, not as a separate novelty feature.',
            ),
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Firestore conversation sync',
              subtitle:
                  'Every send can be mirrored to `${controller.firestoreMessagesPath}` for clinic demos and backend handoff testing.',
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
            const SizedBox(height: 24),
            SectionSurface(
              title: 'Suggested prompts',
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
                  'A supportive, plain-language layer over your plan, flags, and offers.',
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
                          'Ask why a pillar is drifting or how to adapt the plan.',
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
