import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/source_ref.dart';
import '../document/document_detail_screen.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/source_card.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    ref.read(chatControllerProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    final isFirstChat = messages.every((m) => !m.isUser);

    return Scaffold(
      body: Column(
        children: [
          _ChatHeader(
            onNewChat: () =>
                ref.read(chatControllerProvider.notifier).newChat(),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: messages.length,
              itemBuilder: (context, i) => _MessageItem(message: messages[i]),
            ),
          ),
          if (isFirstChat)
            _QuickTopics(
              onSelected: (topic) {
                _inputController.text = topic;
                _send();
              },
            ),
          _InputBar(controller: _inputController, onSend: _send),
        ],
      ),
    );
  }
}

class _QuickTopics extends StatefulWidget {
  const _QuickTopics({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<_QuickTopics> createState() => _QuickTopicsState();
}

class _QuickTopicsState extends State<_QuickTopics> {
  final _scrollController = ScrollController();

  static const _topics = <String>[
    'Học vụ',
    'Học phí',
    'Điểm rèn luyện',
    'Học bổng',
    'Ký túc xá',
    'Bảo hiểm y tế',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          itemCount: _topics.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) => Center(
            child: ActionChip(
              label: Text(_topics[i]),
              labelStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.chipBg,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => widget.onSelected(_topics[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              'CTU',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý sinh viên CTU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.online, size: 9),
                    SizedBox(width: 6),
                    Text(
                      'Đang sẵn sàng hỗ trợ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onSelected: (value) {
              if (value == 'new') onNewChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_comment_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Tạo đoạn chat mới'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message});

  final ChatMessage message;

  void _openDetail(BuildContext context, List<SourceRef> sources) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(sources: sources),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) return const TypingIndicator();

    final timeLabel = message.timeLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageBubble(text: message.text, isUser: message.isUser),
        if (timeLabel != null) ...[
          const SizedBox(height: 3),
          Align(
            alignment:
                message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              timeLabel,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
        if (message.sources.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SourcesHeader(),
          const SizedBox(height: 10),
          for (final source in message.sources)
            SourceCard(
              source: source,
              onTap: () => _openDetail(context, message.sources),
            ),
          const SizedBox(height: 4),
          _DocumentDetailButton(
            onTap: () => _openDetail(context, message.sources),
          ),
        ] else if (message.fromSearch) ...[
          const SizedBox(height: 8),
          const _SearchedBadge(),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _DocumentDetailButton extends StatelessWidget {
  const _DocumentDetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.info_outline, size: 18),
        label: const Text('Chi tiết tài liệu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _SourcesHeader extends StatelessWidget {
  const _SourcesHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text(
          'Nguồn tham khảo',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SearchedBadge extends StatelessWidget {
  const _SearchedBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.travel_explore, color: Theme.of(context).hintColor, size: 16),
        const SizedBox(width: 6),
        Text(
          'Đã tra cứu tài liệu nhưng không tìm thấy nguồn phù hợp',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? AppColors.cardDark
                    : Colors.grey.shade200,
                prefixIcon: Icon(
                  Icons.attach_file,
                  color: theme.hintColor,
                  size: 20,
                ),
                suffixIcon: Icon(
                  Icons.mic_none,
                  color: theme.hintColor,
                  size: 22,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
