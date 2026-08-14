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
  int _generation = 0;
  bool _isSending = false;
  ConversationContext? _conversationContext;

  bool get isResponding => _isSending;

  void newChat() {
    stopResponse();
    _generation++;
    _counter = 0;
    _conversationContext = null;
    state = const [_welcomeMessage];
  }

  void stopResponse() {
    if (!_isSending) return;

    _generation++;
    _isSending = false;
    _activeRequestId = null;
    _apiClient.cancelActiveAnswer();
    state = [for (final message in state) if (!message.isTyping) message];
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

    final requestId = _counter++;
    _activeRequestId = requestId;

    try {
      final response = await _apiClient.answer(
        trimmed,
        conversationContext: _conversationContext,
      );
      if (requestGeneration != _generation || _activeRequestId != requestId) {
        return;
      }

      _activeRequestId = null;
      _isSending = false;
      _conversationContext = response.conversationContext ?? _conversationContext;
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
      if (requestGeneration != _generation || _activeRequestId != requestId) {
        return;
      }

      _activeRequestId = null;
      _isSending = false;
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
      if (requestGeneration == _generation && _activeRequestId == requestId) {
        _activeRequestId = null;
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
