import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

/// 대화 한 줄. 서버 없이 화면만 만들기 위한 최소 모델.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// 실습용 가짜 AI — 프록시(w12/ai)를 붙이기 전까지 이것으로 응답을 흉내 낸다.
class FakeAiClient {
  FakeAiClient({this.delay = const Duration(milliseconds: 1500)});

  /// 답변이 오기까지 걸리는 시간. 이 동안 타이핑 말풍선이 보인다.
  final Duration delay;

  Future<String> chat(String text) async {
    await Future<void>.delayed(delay);
    return '"$text"에 대한 답변입니다.';
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.initialMessages, this.client});

  /// 처음에 보여 줄 대화. 생략하면 실습용 가짜 대화가 들어간다.
  /// 빈 목록을 넘기면 빈 상태 화면을 확인할 수 있다.
  final List<ChatMessage>? initialMessages;

  /// 답변을 주는 AI. 생략하면 [FakeAiClient]를 쓴다.
  /// 테스트에서는 답변이 빨리 오는 클라이언트를 넘긴다.
  final FakeAiClient? client;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// 실습용 가짜 대화 — API를 붙이기 전까지 이 목록으로 화면을 만든다.
  /// 보낸 글을 추가해야 하므로 const 목록이 아니라 늘어나는 목록이다.
  late final List<ChatMessage> _messages = [
    ...widget.initialMessages ??
        const [
          ChatMessage(text: '오늘 뭐 배워?', isUser: true),
          ChatMessage(text: 'AI 챗봇에 움직이는 응답을 붙입니다.', isUser: false),
          ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
          ChatMessage(text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.', isUser: false),
        ],
  ];

  late final FakeAiClient _ai = widget.client ?? FakeAiClient();

  final _controller = TextEditingController();

  /// 답변을 기다리는 중인지. true면 타이핑 말풍선을 띄우고 전송을 막는다.
  bool _waiting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 입력창의 글을 목록에 추가하고 AI에 묻는다.
  /// 공백뿐이거나 이미 답변을 기다리는 중이면 보내지 않는다.
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _waiting) return;
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _controller.clear();
    _request(text);
  }

  /// AI에 묻고 답을 기다린다. 기다리는 동안 타이핑 말풍선이 보인다.
  Future<void> _request(String text) async {
    setState(() => _waiting = true);
    final answer = await _ai.chat(text);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: answer, isUser: false));
      _waiting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 기다리는 동안에는 타이핑 말풍선이 목록 맨 아래(index 0)에 한 칸 더 붙는다.
    final extra = _waiting ? 1 : 0;

    return Scaffold(
      // ✅ 할 일 5 — 키보드가 입력창을 가리지 않게
      //    · resizeToAvoidBottomInset(기본값 true)이 키보드 높이만큼 body를 줄인다.
      //    · 입력창이 Column 맨 아래에 있으므로 키보드 바로 위로 따라 올라온다.
      //    · SafeArea가 홈 인디케이터와 노치를 피한다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Chat — 실습 4')),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────
            // ✅ 할 일 1 — ListView.builder + reverse: true
            //    · reverse:true면 index 0이 화면 맨 아래(최신)다.
            //    · 그래서 _messages[length - 1 - i]로 거꾸로 꺼낸다.
            // ✅ 할 일 4 — 빈 상태
            //    ListView를 Stack으로 감싸고, 목록이 비었을 때만
            //    안내 문구를 위에 겹친다.
            // ─────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length + extra,
                    itemBuilder: (context, index) {
                      if (_waiting && index == 0) return const _TypingBubble();
                      final message =
                          _messages[_messages.length - 1 - (index - extra)];
                      return _Bubble(message: message);
                    },
                  ),
                  if (_messages.isEmpty)
                    Center(
                      child: Text(
                        '무엇이든 물어보세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────────────
            // ✅ 할 일 3 — 입력창 (TextField + 전송 버튼)
            //    키보드의 전송 키와 버튼이 같은 _send()를 부른다.
            //    답변을 기다리는 동안에는 버튼이 회색으로 꺼진다.
            // ─────────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _waiting ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: '전송',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI 말풍선과 사용자 말풍선이 같은 모양을 쓰도록 묶어 둔 상자.
class _BubbleBox extends StatelessWidget {
  const _BubbleBox({super.key, required this.isUser, required this.child});

  final bool isUser;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────
/// ✅ 할 일 2 — 말풍선 2종 (사용자 오른쪽 / AI 왼쪽)
///
///  · Align으로 좌우를 나누고, 색은 colorScheme에서 꺼낸다.
///  · maxWidth를 잡아 두면 긴 글은 자동으로 줄바꿈된다.
/// ───────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return _BubbleBox(
      isUser: isUser,
      child: Text(
        message.text,
        style: TextStyle(
          color: isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 답변을 기다리는 동안 AI 쪽에 뜨는 ●●● 말풍선.
/// 점 세 개가 차례로 밝아졌다 어두워지며 앱이 멈추지 않았음을 보여 준다.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return _BubbleBox(
      key: const Key('typing-bubble'),
      isUser: false,
      child: Semantics(
        label: '답변을 기다리는 중',
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // 점마다 0.2씩 늦게 출발하는 삼각파: 0 → 1 → 0
              final t = (_anim.value - i * 0.2) % 1.0;
              final wave = t < 0.5 ? t * 2 : (1 - t) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.3 + 0.7 * wave,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
