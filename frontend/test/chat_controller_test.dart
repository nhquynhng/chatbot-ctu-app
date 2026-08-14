import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/chat/chat_controller.dart';
import 'package:myapp/features/chat/data/rag_api_client.dart';

class _PendingRagApiClient extends RagApiClient {
  final calls = <({String question, ConversationContext? context})>[];
  final responses = <Completer<RagAnswer>>[];

  @override
  Future<RagAnswer> answer(
    String question, {
    int topK = 5,
    ConversationContext? conversationContext,
  }) {
    calls.add((question: question, context: conversationContext));
    final response = Completer<RagAnswer>();
    responses.add(response);
    return response.future;
  }
}

void main() {
  test('ignores a second send while the first request is pending', () async {
    final api = _PendingRagApiClient();
    final controller = ChatController(api);

    final first = controller.send('Câu đầu');
    await controller.send('Câu thứ hai');

    expect(api.calls, hasLength(1));
    expect(api.calls.single.question, 'Câu đầu');

    api.responses.single.complete(
      const RagAnswer(
        answer: 'Trả lời đầu',
        sources: [],
        shouldSearch: true,
        conversationContext: ConversationContext(
          recentTopic: 'chủ đề đầu',
          documentKey: 'doc-dau',
          versionKey: 'v1',
        ),
      ),
    );
    await first;
  });

  test('ignores an old response after starting a new chat', () async {
    final api = _PendingRagApiClient();
    final controller = ChatController(api);

    final oldRequest = controller.send('Câu hỏi cũ');
    controller.newChat();

    api.responses.single.complete(
      const RagAnswer(
        answer: 'Câu trả lời cũ',
        sources: [],
        shouldSearch: true,
        conversationContext: ConversationContext(recentTopic: 'chủ đề cũ'),
      ),
    );
    await oldRequest;

    expect(controller.state, hasLength(1));
    expect(controller.state.single.id, 'welcome');

    final newRequest = controller.send('Câu hỏi mới');
    expect(api.calls.last.context, isNull);
    api.responses.last.complete(
      const RagAnswer(
        answer: 'Câu trả lời mới',
        sources: [],
        shouldSearch: true,
        conversationContext: ConversationContext(recentTopic: 'chủ đề mới'),
      ),
    );
    await newRequest;

    expect(controller.state.last.text, 'Câu trả lời mới');
  });

  test('sends the previous response context with a follow-up question',
      () async {
    final api = _PendingRagApiClient();
    final controller = ChatController(api);

    final first = controller.send('Đóng học phí KTX như thế nào?');
    api.responses.single.complete(
      const RagAnswer(
        answer: 'Bạn thanh toán theo thông báo.',
        sources: [],
        shouldSearch: true,
        conversationContext: ConversationContext(
          recentTopic: 'đóng học phí KTX học kỳ 3 năm học 2025-2026',
          documentKey: 'ctu-ctsv-tbdk-hk32526',
          versionKey: 'ctu-ctsv-tbdk-hk32526-a42b92f1401a',
          usedChunkKeys: ['ctu-ctsv-tbdk-hk32526-a42b92f1401a::c::0006'],
        ),
      ),
    );
    await first;

    final followUp = controller.send('Còn gì không?');
    final followUpContext = api.calls.last.context;
    expect(
      followUpContext?.recentTopic,
      'đóng học phí KTX học kỳ 3 năm học 2025-2026',
    );
    expect(followUpContext?.documentKey, 'ctu-ctsv-tbdk-hk32526');
    expect(
      followUpContext?.versionKey,
      'ctu-ctsv-tbdk-hk32526-a42b92f1401a',
    );
    expect(
      followUpContext?.usedChunkKeys,
      ['ctu-ctsv-tbdk-hk32526-a42b92f1401a::c::0006'],
    );

    api.responses.last.complete(
      const RagAnswer(answer: 'Không có thông tin bổ sung.', sources: [], shouldSearch: false),
    );
    await followUp;
  });
}
