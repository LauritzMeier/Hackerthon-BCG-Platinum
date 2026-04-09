import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'mock_data.dart';
import 'mock_widgets.dart';

class MockCompassShell extends StatefulWidget {
  const MockCompassShell({super.key});

  @override
  State<MockCompassShell> createState() => _MockCompassShellState();
}

class _MockCompassShellState extends State<MockCompassShell> {
  late final PageController _pageController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ShellBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useFrame = constraints.maxWidth >= 620;
              final shellWidth =
                  useFrame ? 428.0 : constraints.maxWidth.clamp(320.0, 520.0);

              return Center(
                child: Padding(
                  padding: EdgeInsets.all(useFrame ? 18 : 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: shellWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: useFrame ? 0.14 : 0),
                        borderRadius: BorderRadius.circular(useFrame ? 42 : 0),
                        border: useFrame
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.42),
                              )
                            : null,
                        boxShadow: useFrame
                            ? [
                                BoxShadow(
                                  color: AppPalette.ink.withValues(alpha: 0.12),
                                  blurRadius: 36,
                                  offset: const Offset(0, 18),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(useFrame ? 42 : 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.24),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentIndex = index;
                                    });
                                  },
                                  children: const [
                                    ChatMockScreen(),
                                    DashboardMockScreen(),
                                    GoalsFutureMockScreen(),
                                  ],
                                ),
                              ),
                              MockBottomBar(
                                currentIndex: _currentIndex,
                                onSelected: _selectTab,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ChatMockScreen extends StatefulWidget {
  const ChatMockScreen({super.key});

  @override
  State<ChatMockScreen> createState() => _ChatMockScreenState();
}

class _ChatMockScreenState extends State<ChatMockScreen> {
  late List<MockConversation> _conversations;
  late String _selectedConversationId;
  final TextEditingController _composerController = TextEditingController();
  bool _historyOpen = false;

  @override
  void initState() {
    super.initState();
    _conversations = seedConversations
        .map(
          (conversation) => conversation.copyWith(
            messages: List<MockMessage>.from(conversation.messages),
          ),
        )
        .toList(growable: false);
    _selectedConversationId = _conversations.first.id;
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  void _sendMockMessage() {
    _commitMockMessage(_composerController.text.trim());
  }

  void _commitMockMessage(String text) {
    if (text.isEmpty) {
      return;
    }

    _composerController.clear();
    final selected = _conversationById(_selectedConversationId);
    final updatedMessages = [
      ...selected.messages,
      MockMessage(text: text, timeLabel: 'now', isUser: true),
      const MockMessage(
        text:
            'Mockup reply: this stays frontend-only for now, but the layout is already shaped for an LLM-style assistant response.',
        timeLabel: 'preview',
        isUser: false,
      ),
    ];
    final updatedConversation = selected.copyWith(
      label: _updatedConversationLabel(selected.label, text),
      preview: text,
      updatedLabel: 'now',
      messages: updatedMessages,
    );

    setState(() {
      _conversations = [
        updatedConversation,
        ..._conversations
            .where((conversation) => conversation.id != selected.id),
      ];
    });
  }

  void _toggleHistory() {
    setState(() {
      _historyOpen = !_historyOpen;
    });
  }

  void _selectConversation(String id) {
    setState(() {
      _selectedConversationId = id;
      _historyOpen = false;
    });
  }

  void _startNewChat() {
    final newConversation = MockConversation(
      id: 'new_${DateTime.now().microsecondsSinceEpoch}',
      label: 'New chat',
      preview: 'Start a new thread',
      updatedLabel: 'now',
      messages: const [
        MockMessage(
          text:
              'This is a fresh mock conversation. Later, this panel can become the real chat history and assistant session list.',
          timeLabel: 'now',
          isUser: false,
        ),
      ],
    );

    setState(() {
      _conversations = [newConversation, ..._conversations];
      _selectedConversationId = newConversation.id;
      _historyOpen = false;
    });
  }

  MockConversation _conversationById(String id) {
    return _conversations.firstWhere((conversation) => conversation.id == id);
  }

  String _updatedConversationLabel(String currentLabel, String message) {
    if (currentLabel != 'New chat') {
      return currentLabel;
    }

    final compact = message.replaceAll('\n', ' ').trim();
    if (compact.length <= 22) {
      return compact;
    }

    return '${compact.substring(0, 22).trimRight()}...';
  }

  bool _isTodayConversation(MockConversation conversation) {
    final label = conversation.updatedLabel.toLowerCase();
    return label == 'now' ||
        label.contains('m ago') ||
        label.contains('h ago') ||
        label == 'yesterday';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _conversationById(_selectedConversationId);
    final todayConversations =
        _conversations.where(_isTodayConversation).toList(growable: false);
    final earlierConversations = _conversations
        .where((conversation) => !_isTodayConversation(conversation))
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final historyWidth = (constraints.maxWidth * 0.9).clamp(300.0, 390.0);

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                children: [
                  _ChatTopBar(
                    label: selected.label,
                    updatedLabel: selected.updatedLabel,
                    onOpenHistory: _toggleHistory,
                    onNewChat: _startNewChat,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: MockGlassCard(
                      radius: 34,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      color: Colors.white.withValues(alpha: 0.8),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _ChatIntroCard(conversation: selected),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final prompt in const [
                                      'Why is sleep still lagging?',
                                      'What should I do this week?',
                                      'Show me the next strongest lever',
                                    ])
                                      _ChatPromptChip(
                                        label: prompt,
                                        onTap: () => _commitMockMessage(prompt),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                for (var index = 0;
                                    index < selected.messages.length;
                                    index++) ...[
                                  Align(
                                    alignment: selected.messages[index].isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: MessageBubble(
                                      message: selected.messages[index],
                                    ),
                                  ),
                                  if (index < selected.messages.length - 1)
                                    const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
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
                                  child: TextField(
                                    controller: _composerController,
                                    minLines: 1,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText: 'Message the mock companion...',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _sendMockMessage(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: _sendMockMessage,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppPalette.ink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                    shape: const CircleBorder(),
                                  ),
                                  child: const Icon(Icons.north_east_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_historyOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleHistory,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    color: const Color(0xFFF1EADF),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: 10,
              bottom: 10,
              left: _historyOpen ? 10 : -(historyWidth + 24),
              width: historyWidth,
              child: _ChatHistoryPanel(
                todayConversations: todayConversations,
                earlierConversations: earlierConversations,
                selectedConversationId: _selectedConversationId,
                onClose: _toggleHistory,
                onNewChat: _startNewChat,
                onSelectConversation: _selectConversation,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.label,
    required this.updatedLabel,
    required this.onOpenHistory,
    required this.onNewChat,
  });

  final String label;
  final String updatedLabel;
  final VoidCallback onOpenHistory;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChatIconButton(
          icon: Icons.menu_rounded,
          onTap: onOpenHistory,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<String>(label),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    updatedLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.ink.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _ChatIconButton(
          icon: Icons.edit_note_rounded,
          onTap: onNewChat,
        ),
      ],
    );
  }
}

class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: AppPalette.ink,
          ),
        ),
      ),
    );
  }
}

class _ChatHistoryPanel extends StatelessWidget {
  const _ChatHistoryPanel({
    required this.todayConversations,
    required this.earlierConversations,
    required this.selectedConversationId,
    required this.onClose,
    required this.onNewChat,
    required this.onSelectConversation,
  });

  final List<MockConversation> todayConversations;
  final List<MockConversation> earlierConversations;
  final String selectedConversationId;
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context) {
    return MockGlassCard(
      radius: 34,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFF8F3EB),
          Color(0xFFF2EBE0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New chat'),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppPalette.ink,
                    backgroundColor: const Color(0xFFD7EBE3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ChatIconButton(
                icon: Icons.close_rounded,
                onTap: onClose,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppPalette.ink.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppPalette.ink.withValues(alpha: 0.44),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search chats',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.ink.withValues(alpha: 0.46),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (todayConversations.isNotEmpty)
                  _ChatHistorySection(
                    label: 'Today',
                    conversations: todayConversations,
                    selectedConversationId: selectedConversationId,
                    onSelectConversation: onSelectConversation,
                  ),
                if (earlierConversations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ChatHistorySection(
                    label: 'Previous 7 Days',
                    conversations: earlierConversations,
                    selectedConversationId: selectedConversationId,
                    onSelectConversation: onSelectConversation,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistorySection extends StatelessWidget {
  const _ChatHistorySection({
    required this.label,
    required this.conversations,
    required this.selectedConversationId,
    required this.onSelectConversation,
  });

  final String label;
  final List<MockConversation> conversations;
  final String selectedConversationId;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < conversations.length; index++) ...[
          _ChatHistoryTile(
            conversation: conversations[index],
            selected: conversations[index].id == selectedConversationId,
            onTap: () => onSelectConversation(conversations[index].id),
          ),
          if (index < conversations.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final MockConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.ink : const Color(0xFFFFFCF8),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? Colors.white : AppPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                conversation.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppPalette.ink.withValues(alpha: 0.58),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                conversation.updatedLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.56)
                          : AppPalette.ink.withValues(alpha: 0.46),
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

class _ChatIntroCard extends StatelessWidget {
  const _ChatIntroCard({
    required this.conversation,
  });

  final MockConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.ink.withValues(alpha: 0.96),
            AppPalette.forest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Mock companion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            conversation.preview,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The interface now behaves more like a real assistant thread: conversation history sits behind the menu, and the active thread gets the full screen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChatPromptChip extends StatelessWidget {
  const _ChatPromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.74),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class DashboardMockScreen extends StatefulWidget {
  const DashboardMockScreen({super.key});

  @override
  State<DashboardMockScreen> createState() => _DashboardMockScreenState();
}

class _DashboardMockScreenState extends State<DashboardMockScreen> {
  String? _selectedMetricId;

  CompassMetric get _selectedMetric =>
      metricById(_selectedMetricId ?? compassMetrics.first.id);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = constraints.maxWidth.clamp(280.0, 380.0);
        final collapsedVisibleHeight = 92.0;
        final expandedHeight = (chartSize + 150).clamp(340.0, 470.0);
        final expandedTop =
            ((constraints.maxHeight - expandedHeight) / 2).clamp(24.0, 84.0);
        final collapsedTop = constraints.maxHeight - collapsedVisibleHeight;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: _selectedMetricId == null ? constraints.maxHeight : 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: _selectedMetricId == null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: _selectedMetricId == null ? 0 : 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 124),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MetricTrendCard(
                            metric: _selectedMetric,
                            onCollapse: () {
                              setState(() {
                                _selectedMetricId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          for (var index = 0;
                              index < _selectedMetric.impacts.length;
                              index++) ...[
                            MetricImpactTile(
                              impact: _selectedMetric.impacts[index],
                            ),
                            if (index < _selectedMetric.impacts.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: _selectedMetricId == null ? expandedTop : collapsedTop,
                height: expandedHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _selectedMetricId == null
                      ? null
                      : () {
                          setState(() {
                            _selectedMetricId = null;
                          });
                        },
                  child: RadarSnapshotCard(
                    metrics: compassMetrics,
                    selectedMetricId: _selectedMetricId,
                    collapsed: _selectedMetricId != null,
                    onMetricTap: (metricId) {
                      setState(() {
                        _selectedMetricId = metricId;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GoalsFutureMockScreen extends StatelessWidget {
  const GoalsFutureMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
      children: [
        for (var index = 0; index < futureTimeline.length; index++)
          TimelineEntryTile(
            entry: futureTimeline[index],
            isLast: index == futureTimeline.length - 1,
          ),
        const SizedBox(height: 10),
        const FutureProjectionCard(
          projection: futureProjection,
        ),
      ],
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
            top: 140,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.amber.withValues(alpha: 0.08),
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
