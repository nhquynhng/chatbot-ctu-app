import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/chat_message.dart';
import 'data/rag_api_client.dart';

const _welcomeMessage = ChatMessage(
  id: 'welcome',
  isUser: false,
  text: 'Xin chào! Tôi có thể giúp gì cho bạn?',
);

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._apiClient) : super(const [_welcomeMessage]);

  final RagApiClient _apiClient;

  int _counter = 0;
  int _generation = 0;
  bool _isSending = false;
  String? _recentTopic;

  void newChat() {
    _generation++;
    _counter = 0;
    _isSending = false;
    _recentTopic = null;
    state = const [_welcomeMessage];
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _isSending = true;
    final requestGeneration = _generation;

    final userId = 'u${_counter++}';
    state = [
      ...state,
      ChatMessage(
        id: userId,
        isUser: true,
        text: trimmed,
        sentAt: DateTime.now(),
      ),
    ];

    final typingId = 't${_counter++}';
    state = [
      ...state,
      ChatMessage(id: typingId, isUser: false, isTyping: true),
    ];

    try {
      final response = await _apiClient.answer(
        trimmed,
        recentTopic: _recentTopic,
      );
      if (requestGeneration != _generation) return;

      _recentTopic = response.recentTopic ?? _recentTopic;
      state = [
        for (final m in state)
          if (m.id != typingId) m,
        ChatMessage(
          id: 'a${_counter++}',
          isUser: false,
          text: response.answer,
          sources: response.sources,
          fromSearch: response.shouldSearch,
          sentAt: DateTime.now(),
        ),
      ];
    } on RagApiException catch (error) {
      if (requestGeneration != _generation) return;

      state = [
        for (final m in state)
          if (m.id != typingId) m,
        ChatMessage(
          id: 'e${_counter++}',
          isUser: false,
          text: error.message,
          sentAt: DateTime.now(),
        ),
      ];
    } finally {
      if (requestGeneration == _generation) {
        _isSending = false;
      }
    }
  }
}

final ragApiClientProvider = Provider<RagApiClient>((ref) => RagApiClient());

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>(
      (ref) => ChatController(ref.watch(ragApiClientProvider)),
    );
