import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/app_theme.dart';
import '../../core/models/experience_models.dart';
import '../../widgets/compass_components.dart';
import '../dashboard/dashboard_controller.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String? _voiceStatus;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _composerFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isListening = false;
          _voiceStatus = 'Voice input is not available right now.';
        });
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _speechAvailable = available;
      _voiceStatus = available ? 'Voice input ready.' : null;
    });
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = status == 'listening';
      if (status == 'listening') {
        _voiceStatus = 'Listening... say your question.';
      } else if (status == 'done' || status == 'notListening') {
        _voiceStatus = 'Voice captured. Review and send.';
      }
    });
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final spokenText = result.recognizedWords.trim();
    if (spokenText.isEmpty) {
      return;
    }

    _textController.value = TextEditingValue(
      text: spokenText,
      selection: TextSelection.collapsed(offset: spokenText.length),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _voiceStatus = result.finalResult
          ? 'Voice captured. Review and send.'
          : 'Listening...';
    });
  }

  Future<void> _send(DashboardController controller, String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _textController.clear();
    if (_isListening) {
      await _speechToText.stop();
    }
    await controller.sendCoachMessage(trimmed);
  }

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is not available on this device yet.'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      return;
    }

    final didStart = await _speechToText.listen(
      onResult: _handleSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = didStart;
      _voiceStatus = didStart
          ? 'Listening... say your question.'
          : 'Voice input could not start.';
    });
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

        final hasUserMessages = controller.chatMessages.any(
          (message) => message.isUser,
        );
        final conversationMessages = controller.chatMessages.isEmpty
            ? [ChatMessage.assistant(experience.coach.intro)]
            : controller.chatMessages;
        final showStarterPrompts =
            experience.coach.suggestedPrompts.isNotEmpty && !hasUserMessages;

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
            ],
            SectionSurface(
              title: controller.isWelcomeJourney ? 'Coach chat' : 'Chat',
              subtitle: controller.isWelcomeJourney
                  ? 'Use this to choose the first useful connection or first clinic step.'
                  : 'Use this to clarify the plan, explain a change, or compare support options.',
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.canvas.withValues(alpha: 0.44),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final message in conversationMessages) ...[
                          ChatBubble(message: message),
                          const SizedBox(height: 12),
                        ],
                        if (showStarterPrompts) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: experience.coach.suggestedPrompts
                                  .map(
                                    (prompt) => ActionChip(
                                      label: Text(prompt),
                                      onPressed: controller.isSendingMessage
                                          ? null
                                          : () => _send(controller, prompt),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (controller.isSendingMessage)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                'The coach is writing back...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppPalette.ink
                                          .withValues(alpha: 0.74),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.sand.withValues(alpha: 0.44),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }
                              final isEnter = event.logicalKey ==
                                      LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter;
                              if (!isEnter ||
                                  HardwareKeyboard.instance.isShiftPressed) {
                                return KeyEventResult.ignored;
                              }
                              if (controller.isSendingMessage) {
                                return KeyEventResult.handled;
                              }
                              _send(controller, _textController.text);
                              return KeyEventResult.handled;
                            },
                            child: TextField(
                              controller: _textController,
                              focusNode: _composerFocusNode,
                              enabled: !controller.isSendingMessage,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: controller.isWelcomeJourney
                                    ? 'Tell the coach what you want help with first.'
                                    : 'Ask about your plan, your recent appointment, or your next step.',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (value) => _send(controller, value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: _isListening
                              ? 'Stop voice input'
                              : 'Start voice input',
                          onPressed:
                              controller.isSendingMessage ? null : _toggleVoice,
                          icon: Icon(
                            _isListening
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _isListening
                                ? AppPalette.forest
                                : Colors.white.withValues(alpha: 0.82),
                            foregroundColor:
                                _isListening ? Colors.white : AppPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: controller.isSendingMessage
                              ? null
                              : () => _send(controller, _textController.text),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                  if (_voiceStatus != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _voiceStatus!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.ink.withValues(alpha: 0.64),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
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
