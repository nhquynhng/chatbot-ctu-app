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
  });

  final String answer;
  final List<SourceRef> sources;

  /// `false` khi backend trả lời trực tiếp mà không tra cứu tài liệu.
  final bool shouldSearch;

  factory RagAnswer.fromJson(Map<String, dynamic> json) {
    final citations = json['citations'] as List<dynamic>? ?? const [];
    return RagAnswer(
      answer: json['answer'] as String? ?? '',
      sources: citations
          .whereType<Map<String, dynamic>>()
          .map(SourceRef.fromCitationJson)
          .toList(growable: false),
      shouldSearch: json['should_search'] as bool? ?? true,
    );
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

  Future<RagAnswer> answer(String question, {int topK = 5}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rag/answer');
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'top_k': topK}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RagApiException(
          'Backend trả về lỗi HTTP ${response.statusCode}.',
        );
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const RagApiException('Phản hồi backend không đúng định dạng.');
      }
      return RagAnswer.fromJson(json);
    } on TimeoutException {
      throw const RagApiException('Backend phản hồi quá thời gian cho phép.');
    } on RagApiException {
      rethrow;
    } catch (_) {
      throw RagApiException(
        'Không thể kết nối backend tại ${ApiConfig.baseUrl}.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
