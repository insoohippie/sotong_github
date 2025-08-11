import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../model/chat_message.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onComplete;
  final VoidCallback? onTextUpdate; // 텍스트 업데이트 시 호출될 콜백

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.onComplete,
    this.onTextUpdate,
  }) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();

  // 공개 static getter 추가
  static Set<String> get completedMessageIds =>
      _ChatMessageWidgetState._completedMessageIds;
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  String _displayText = '';
  bool _isComplete = false;
  late AnimationController _animationController;
  Timer? _typingTimer;

  // 메시지별로 애니메이션 완료 여부를 기억하는 static Set
  static final Set<String> _completedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();

    if (_completedMessageIds.contains(widget.message.id)) {
      _displayText = widget.message.content;
      _isComplete = true;

      // ✅ onComplete 강제 호출
      if (widget.onComplete != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete!();
        });
      }
    } else if (widget.message.type == MessageType.bot && !_isComplete) {
      _startTypingAnimation();
    } else {
      _displayText = widget.message.content;
      _isComplete = true;
    }
  }

  @override
  void didUpdateWidget(covariant ChatMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 메시지 id가 바뀌었을 때만 동작
    if (widget.message.id != oldWidget.message.id) {
      if (_completedMessageIds.contains(widget.message.id)) {
        setState(() {
          _displayText = widget.message.content;
          _isComplete = true;
        });
      } else if (!_isComplete && widget.message.type == MessageType.bot) {
        _startTypingAnimation();
      } else {
        setState(() {
          _displayText = widget.message.content;
          _isComplete = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTypingAnimation() {
    if (_isComplete) return;
    int currentIndex = 0;
    final text = widget.message.content;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentIndex < text.length) {
        setState(() {
          try {
            // UTF-16 안전한 방법으로 텍스트 처리
            if (currentIndex + 1 <= text.length) {
              // 문자열을 문자 단위로 분할하여 안전하게 처리
              final runes = text.runes.toList();
              if (currentIndex < runes.length) {
                final partialRunes = runes.take(currentIndex + 1).toList();
                _displayText = String.fromCharCodes(partialRunes);
              } else {
                _displayText = text;
              }
            } else {
              _displayText = text;
            }
          } catch (e) {
            // 에러 발생 시 전체 텍스트 표시
            _displayText = text;
            _isComplete = true;
            _completedMessageIds.add(widget.message.id);
            if (widget.onComplete != null) widget.onComplete!();
            timer.cancel();
            return;
          }
        });
        // 텍스트 업데이트 시 스크롤 콜백 호출
        if (widget.onTextUpdate != null) {
          widget.onTextUpdate!();
        }
        currentIndex++;
      } else {
        setState(() {
          _isComplete = true;
        });
        // 애니메이션이 끝난 메시지 id를 static Set에 저장
        _completedMessageIds.add(widget.message.id);
        if (widget.onComplete != null) widget.onComplete!();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBot = widget.message.type == MessageType.bot;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFBFD8FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🧾', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Color(0xFFF4F4F4) : Color(0xFF0062FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _displayText,
                style: TextStyle(
                  color: isBot ? Color(0xFF333333) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
