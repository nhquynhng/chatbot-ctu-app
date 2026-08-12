import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/chat/chat_controller.dart';
import 'package:myapp/features/chat/data/rag_api_client.dart';

class _PendingRagApiClient extends RagApiClient {
  final calls = <({String question, String? recentTopic})>[];
  final responses = <Completer<RagAnswer>>[];

  @override
  Future<RagAnswer> answer(
    String question, {
    int topK = 5,
    String? recentTopic,
  }) {
    calls.add((question: question, recentTopic: recentTopic));
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
        recentTopic: 'chủ đề đầu',
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
        recentTopic: 'chủ đề cũ',
      ),
    );
    await oldRequest;

    expect(controller.state, hasLength(1));
    expect(controller.state.single.id, 'welcome');

    final newRequest = controller.send('Câu hỏi mới');
    expect(api.calls.last.recentTopic, isNull);
    api.responses.last.complete(
      const RagAnswer(
        answer: 'Câu trả lời mới',
        sources: [],
        shouldSearch: true,
        recentTopic: 'chủ đề mới',
      ),
    );
    await newRequest;

    expect(controller.state.last.text, 'Câu trả lời mới');
  });
}
