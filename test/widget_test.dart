import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

/// 테스트용 화면. 답변이 0.1초 만에 오는 가짜 AI를 쓴다.
Widget chatApp({List<ChatMessage>? initialMessages, FakeAiClient? client}) {
  return MaterialApp(
    home: ChatPage(
      initialMessages: initialMessages,
      client: client ?? FakeAiClient(delay: const Duration(milliseconds: 100)),
    ),
  );
}

/// 답변이나 오류가 나올 때까지 시간을 충분히 흘린다.
Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 10));

final typingBubble = find.byKey(const Key('typing-bubble'));

void main() {
  testWidgets('앱이 뜨고 가짜 대화가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 제목
    expect(find.text('AI Chat — 실습 4'), findsOneWidget);

    // 할 일 1 — 목록이 그려진다
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('오늘 뭐 배워?'), findsOneWidget);

    // 할 일 3 — 입력창과 전송 버튼이 있다
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // 할 일 4 — 대화가 있으면 빈 상태 문구는 안 보인다
    expect(find.text('무엇이든 물어보세요'), findsNothing);
  });

  testWidgets('말풍선이 좌우로 나뉜다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    final userAlign = tester.widget<Align>(
      find.ancestor(of: find.text('오늘 뭐 배워?'), matching: find.byType(Align)).first,
    );
    final aiAlign = tester.widget<Align>(
      find
          .ancestor(
            of: find.text('AI 챗봇에 움직이는 응답을 붙입니다.'),
            matching: find.byType(Align),
          )
          .first,
    );

    expect(userAlign.alignment, Alignment.centerRight);
    expect(aiAlign.alignment, Alignment.centerLeft);
  });

  testWidgets('보내면 타이핑 점이 뜨고, 답이 오면 AI 말풍선이 붙는다', (WidgetTester tester) async {
    await tester.pumpWidget(chatApp());

    await tester.enterText(find.byType(TextField), '안녕하세요');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // 내 말풍선이 바로 보이고, 입력창은 비워지고, 점 3개가 뜬다
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(typingBubble, findsOneWidget);

    await settle(tester);

    expect(typingBubble, findsNothing);
    expect(find.text('"안녕하세요"에 대한 답변입니다.'), findsOneWidget);
  });

  testWidgets('답을 기다리는 동안에는 다시 보낼 수 없다', (WidgetTester tester) async {
    await tester.pumpWidget(chatApp(initialMessages: []));

    await tester.enterText(find.byType(TextField), '첫 질문');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '두 번째 질문');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('두 번째 질문'), findsOneWidget); // 입력창에만 남아 있다
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('두 번째 질문')),
      findsNothing,
    );

    await settle(tester);
  });

  testWidgets('공백만 있으면 보내지 않는다', (WidgetTester tester) async {
    await tester.pumpWidget(chatApp(initialMessages: []));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('무엇이든 물어보세요'), findsOneWidget);
    expect(typingBubble, findsNothing);
  });

  testWidgets('목록이 비면 빈 상태 문구가 보이고, 보내면 사라진다', (WidgetTester tester) async {
    await tester.pumpWidget(chatApp(initialMessages: []));

    expect(find.text('무엇이든 물어보세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '첫 질문');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.text('무엇이든 물어보세요'), findsNothing);
    expect(find.text('첫 질문'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('키보드가 올라와도 입력창이 가려지지 않는다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 키보드 높이 300을 흉내 낸다
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.reset);
    await tester.pump();

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final keyboardTop = screenHeight - 300 * 3 / tester.view.devicePixelRatio;
    final fieldBottom = tester.getRect(find.byType(TextField)).bottom;

    expect(fieldBottom, lessThanOrEqualTo(keyboardTop));
  });
}
