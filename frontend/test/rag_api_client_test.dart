import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myapp/features/chat/data/rag_api_client.dart';

void main() {
  test('sends the backend contract and maps citations', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/rag/answer');
      expect(jsonDecode(request.body), {
        'question': 'Cách xin giấy xác nhận?',
        'top_k': 5,
      });

      return http.Response(
        jsonEncode({
          'answer': 'Bạn thực hiện theo hướng dẫn.',
          'should_search': true,
          'citations': [
            {
              'document_key': 'QT-SV-001',
              'version_key': 'QT-SV-001@v2',
              'chunk_key': 'QT-SV-001@v2#c3',
              'title': 'Quy trình sinh viên',
              'citation': 'Mục 2',
              'page_start': 4,
              'page_end': 6,
              'source_file':
                  '../Dataset/PDFs/QT_SV_001_quy_trinh_sinh_vien.pdf',
              'issued_date': '2020-08-14',
              'issuing_authority': 'Phòng Công tác Sinh viên',
              'document_type': 'Quyết định',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await RagApiClient(
      client: client,
    ).answer('Cách xin giấy xác nhận?');

    expect(result.answer, 'Bạn thực hiện theo hướng dẫn.');
    expect(result.sources, hasLength(1));
    final source = result.sources.single;
    expect(source.documentKey, 'QT-SV-001');
    expect(source.versionKey, 'QT-SV-001@v2');
    expect(source.chunkKey, 'QT-SV-001@v2#c3');
    expect(source.page, 4);
    expect(source.pageEnd, 6);
    expect(source.pageLabel, 'Trang 4–6');
    expect(source.sourceFileNameLabel, 'QT_SV_001_quy_trinh_sinh_vien.pdf');
    expect(source.issuedDateLabel, '14/08/2020');
    expect(source.issuingAuthorityLabel, 'Phòng Công tác Sinh viên');
    expect(source.documentTypeLabel, 'Quyết định');
  });

  test('shows "Chưa cập nhật" when document metadata is missing', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'answer': 'Nội dung trả lời.',
          'should_search': true,
          'citations': [
            {
              'document_key': 'QT-SV-002',
              'version_key': 'QT-SV-002@v1',
              'chunk_key': 'QT-SV-002@v1#c1',
              'title': 'Tài liệu thiếu metadata',
              'citation': 'Mục 1',
              'page_start': 1,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await RagApiClient(client: client).answer('Câu hỏi.');

    final source = result.sources.single;
    expect(source.sourceFileNameLabel, 'Chưa cập nhật');
    expect(source.issuedDateLabel, 'Chưa cập nhật');
    expect(source.issuingAuthorityLabel, 'Chưa cập nhật');
    expect(source.documentTypeLabel, 'Chưa cập nhật');
  });
}
