import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../shared/models/source_ref.dart';

class RagAnswer {
  const RagAnswer({
    required this.answer,
    required this.sources,
    required this.shouldSearch,
    this.conversationContext,
  });

  final String answer;
  final List<SourceRef> sources;

  /// `false` khi backend trả lời trực tiếp mà không tra cứu tài liệu.
  final bool shouldSearch;
  final ConversationContext? conversationContext;

  factory RagAnswer.fromJson(Map<String, dynamic> json) {
    final citations = json['citations'] as List<dynamic>? ?? const [];

    return RagAnswer(
      answer: json['answer'] as String? ?? '',
      sources: citations
          .whereType<Map<String, dynamic>>()
          .map(SourceRef.fromCitationJson)
          .toList(growable: false),
      shouldSearch: json['should_search'] as bool? ?? true,
      conversationContext: ConversationContext.tryFromResponseJson(json),
    );
  }
}

class ConversationContext {
  const ConversationContext({
    this.recentTopic,
    this.documentKey,
    this.versionKey,
    this.usedChunkKeys = const [],
  });

  final String? recentTopic;
  final String? documentKey;
  final String? versionKey;
  final List<String> usedChunkKeys;

  static ConversationContext? tryFromResponseJson(Map<String, dynamic> json) {
    final context = json['conversation_context'];
    final values = context is Map<String, dynamic>
        ? context
        : <String, dynamic>{
            'recent_topic': json['recent_topic'],
          };
    final rawChunkKeys = values['used_chunk_keys'];

    final recentTopic = _emptyToNull(values['recent_topic']);
    final documentKey = _emptyToNull(values['document_key']);
    final versionKey = _emptyToNull(values['version_key']);
    final usedChunkKeys = rawChunkKeys is List
        ? rawChunkKeys.whereType<String>().toList(growable: false)
        : const <String>[];

    if (recentTopic == null && documentKey == null && versionKey == null) {
      return null;
    }

    return ConversationContext(
      recentTopic: recentTopic,
      documentKey: documentKey,
      versionKey: versionKey,
      usedChunkKeys: usedChunkKeys,
    );
  }

  Map<String, dynamic>? toRequestJson() {
    if (recentTopic == null && documentKey == null && versionKey == null) {
      return null;
    }

    return {
      if (recentTopic != null) 'recent_topic': recentTopic,
      if (documentKey != null) 'document_key': documentKey,
      if (versionKey != null) 'version_key': versionKey,
      if (usedChunkKeys.isNotEmpty) 'used_chunk_keys': usedChunkKeys,
    };
  }

  static String? _emptyToNull(dynamic value) {
    if (value is! String) return null;

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum DocumentPreviewType {
  source('source'),
  canonicalMarkdown('canonical_markdown');

  const DocumentPreviewType(this.apiValue);

  final String apiValue;
}

class DocumentPreviewUrl {
  const DocumentPreviewUrl({
    required this.versionKey,
    required this.fileType,
    required this.url,
    required this.expiresMinutes,
  });

  final String versionKey;
  final String fileType;
  final Uri url;
  final int expiresMinutes;

  factory DocumentPreviewUrl.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String? ?? '';
    final parsedUrl = Uri.tryParse(rawUrl);

    if (parsedUrl == null || rawUrl.trim().isEmpty) {
      throw const RagApiException(
        'Backend không trả về đường dẫn xem tài liệu hợp lệ.',
      );
    }

    return DocumentPreviewUrl(
      versionKey: json['version_key'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      url: parsedUrl,
      expiresMinutes: _toInt(json['expires_minutes']) ?? 5,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class RagApiException implements Exception {
  const RagApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RagApiClient {
  RagApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;
  http.Client? _activeAnswerClient;

  /// Hủy yêu cầu trả lời đang chạy. Lần gọi sau sẽ tạo kết nối mới.
  void cancelActiveAnswer() {
    _activeAnswerClient?.close();
    _activeAnswerClient = null;
  }

  Future<RagAnswer> answer(
    String question, {
    int topK = 5,
    ConversationContext? conversationContext,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rag/answer');

    final client = _client ?? http.Client();
    if (_client == null) {
      _activeAnswerClient = client;
    }

    try {
      final response = await client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              'top_k': topK,
              if (conversationContext?.toRequestJson() case final context?)
                'conversation_context': context,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RagApiException(
          _extractErrorMessage(
            response,
            fallback: 'Backend trả về lỗi HTTP ${response.statusCode}.',
          ),
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const RagApiException('Phản hồi backend không đúng định dạng.');
      }

      return RagAnswer.fromJson(decoded);
    } on TimeoutException {
      throw const RagApiException('Backend phản hồi quá thời gian cho phép.');
    } on RagApiException {
      rethrow;
    } catch (_) {
      throw RagApiException(
        'Không thể kết nối backend tại ${ApiConfig.baseUrl}.',
      );
    } finally {
      if (_client == null) {
        client.close();
        if (identical(_activeAnswerClient, client)) {
          _activeAnswerClient = null;
        }
      }
    }
  }

  /// Lấy URL tạm thời để xem PDF hoặc file nguồn gốc.
  Future<DocumentPreviewUrl> getSourcePreviewUrl(String versionKey) {
    return getDocumentPreviewUrl(
      versionKey: versionKey,
      fileType: DocumentPreviewType.source,
    );
  }

  /// Lấy URL tạm thời để xem file Markdown OCR.
  Future<DocumentPreviewUrl> getCanonicalMarkdownPreviewUrl(String versionKey) {
    return getDocumentPreviewUrl(
      versionKey: versionKey,
      fileType: DocumentPreviewType.canonicalMarkdown,
    );
  }

  Future<DocumentPreviewUrl> getDocumentPreviewUrl({
    required String versionKey,
    required DocumentPreviewType fileType,
  }) async {
    final normalizedVersionKey = versionKey.trim();

    if (normalizedVersionKey.isEmpty) {
      throw const RagApiException('Không có mã phiên bản tài liệu.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/versions/preview-url/'
      '${Uri.encodeComponent(normalizedVersionKey)}',
    ).replace(queryParameters: {'file_type': fileType.apiValue});

    final client = _client ?? http.Client();

    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RagApiException(
          _extractErrorMessage(
            response,
            fallback:
                'Không thể lấy đường dẫn tài liệu '
                '(HTTP ${response.statusCode}).',
          ),
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const RagApiException(
          'Phản hồi đường dẫn tài liệu không đúng định dạng.',
        );
      }

      return DocumentPreviewUrl.fromJson(decoded);
    } on TimeoutException {
      throw const RagApiException('Quá thời gian lấy đường dẫn tài liệu.');
    } on RagApiException {
      rethrow;
    } catch (_) {
      throw RagApiException(
        'Không thể kết nối backend tại ${ApiConfig.baseUrl}.',
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  static String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        if (detail is List) {
          final messages = detail
              .whereType<Map<String, dynamic>>()
              .map((item) => item['msg'])
              .whereType<String>()
              .map((message) => message.trim())
              .where((message) => message.isNotEmpty)
              .toSet()
              .toList(growable: false);

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }
    } catch (_) {
      // Dùng thông báo mặc định khi body không phải JSON.
    }

    return fallback;
  }
}
