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
  int? _activeRequestId;

  bool get isResponding => _activeRequestId != null;

  void newChat() {
    stopResponse();
    _counter = 0;
    state = const [_welcomeMessage];
  }

  void stopResponse() {
    if (_activeRequestId == null) return;

    _activeRequestId = null;
    _apiClient.cancelActiveAnswer();
    state = [for (final message in state) if (!message.isTyping) message];
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isResponding) return;

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

    final requestId = _counter++;
    _activeRequestId = requestId;

    try {
      final response = await _apiClient.answer(trimmed);
      if (_activeRequestId != requestId) return;
      _activeRequestId = null;
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
      if (_activeRequestId != requestId) return;
      _activeRequestId = null;
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
    }
  }
}

final ragApiClientProvider = Provider<RagApiClient>((ref) => RagApiClient());

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>(
      (ref) => ChatController(ref.watch(ragApiClientProvider)),
    );
