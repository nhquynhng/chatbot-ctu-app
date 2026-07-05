import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/mock/mock_data.dart';
import '../../shared/models/chat_message.dart';

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController() : super(const [kWelcomeMessage]);

  int _counter = 0;

  void newChat() {
    _counter = 0;
    state = const [kWelcomeMessage];
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userId = 'u${_counter++}';
    state = [
      ...state,
      ChatMessage(id: userId, isUser: true, text: trimmed),
    ];

    final typingId = 't${_counter++}';
    state = [
      ...state,
      ChatMessage(id: typingId, isUser: false, isTyping: true),
    ];

    await Future<void>.delayed(const Duration(milliseconds: 900));

    state = [
      for (final m in state)
        if (m.id != typingId) m,
      buildMockAnswer('a${_counter++}'),
    ];
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>(
  (ref) => ChatController(),
);
