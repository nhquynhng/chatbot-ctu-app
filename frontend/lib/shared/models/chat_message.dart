import 'source_ref.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<SourceRef> sources;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.isUser,
    this.text = '',
    this.sources = const [],
    this.isTyping = false,
  });
}
