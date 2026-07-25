import 'source_ref.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<SourceRef> sources;
  final bool isTyping;

  /// `true` khi câu trả lời được tổng hợp từ tra cứu tài liệu (có nguồn),
  /// `false` khi backend trả lời trực tiếp.
  final bool fromSearch;

  /// Thời điểm tin nhắn được gửi. `null` cho tin hệ thống (lời chào) hoặc
  /// trạng thái đang gõ — những tin không cần mốc thời gian.
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    required this.isUser,
    this.text = '',
    this.sources = const [],
    this.isTyping = false,
    this.fromSearch = false,
    this.sentAt,
  });

  /// Nhãn thời gian kiểu Messenger:
  /// - Cùng ngày: `HH:mm`
  /// - Cùng năm nhưng khác ngày: `dd/MM HH:mm`
  /// - Khác năm: `dd/MM/yyyy HH:mm`
  /// Trả `null` khi tin không có `sentAt`.
  String? get timeLabel {
    final t = sentAt;
    if (t == null) return null;

    final now = DateTime.now();
    final hm = '${_two(t.hour)}:${_two(t.minute)}';
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) return hm;

    final datePart = t.year == now.year
        ? '${_two(t.day)}/${_two(t.month)}'
        : '${_two(t.day)}/${_two(t.month)}/${t.year}';
    return '$datePart $hm';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
