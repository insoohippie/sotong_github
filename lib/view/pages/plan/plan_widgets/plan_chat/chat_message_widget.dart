import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../../component/theme/app_colors.dart';
import '../../../../../model/plan/chat_message.dart';
import '../../../../../view_model/plan/chat_plan_viewmodel.dart';
import '../plan_summary/summary_section_widget.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onComplete;
  final VoidCallback? onTextUpdate;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.onComplete,
    this.onTextUpdate,
  }) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();

  static Set<String> get completedMessageIds =>
      _ChatMessageWidgetState._completedMessageIds;
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  String _displayText = '';
  bool _isComplete = false;
  AnimationController? _animationController;
  Timer? _typingTimer;

  static final Set<String> _completedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();

    // summary는 애니메이션/로딩 불필요
    if (widget.message.type == MessageType.summary) {
      _displayText = widget.message.content; // 필요 없지만 일관성 유지
      _isComplete = true;
      _completedMessageIds.add(widget.message.id);
      // 요약도 등장 시점 스크롤 보정이 필요하면 onComplete 콜백 호출
      if (widget.onComplete != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete!();
        });
      }
      return; // ← 더 이상 진행하지 않음
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();

    if (_completedMessageIds.contains(widget.message.id)) {
      _displayText = widget.message.content;
      _isComplete = true;
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

    if (widget.message.id != oldWidget.message.id) {
      if (widget.message.type == MessageType.summary) {
        _displayText = widget.message.content;
        _isComplete = true;
        _completedMessageIds.add(widget.message.id);
        setState(() {});
        return;
      }

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
    _animationController?.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTypingAnimation() {
    if (_isComplete) return;
    int currentIndex = 0;
    final text = widget.message.content;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentIndex < text.runes.length) {
        setState(() {
          final runes = text.runes.toList();
          final partialRunes = runes.take(currentIndex + 1).toList();
          _displayText = String.fromCharCodes(partialRunes);
        });
        widget.onTextUpdate?.call();
        currentIndex++;
      } else {
        setState(() => _isComplete = true);
        _completedMessageIds.add(widget.message.id);
        widget.onComplete?.call();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.type == MessageType.summary) {
      final viewModel = context.watch<ChatPlanViewModel>();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: buildSummarySection(context, viewModel),
      );
    }

    // ② 기존 bot/user 말풍선
    final isBot = widget.message.type == MessageType.bot;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFBFD8FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white, // 흰색 보더
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/bot_profile.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFBFD8FF),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isBot ? const Color(0xFFF4F4F4) : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // 은은한 그림자
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _displayText,
                  style: TextStyle(
                    color: isBot ? const Color(0xFF333333): AppColors.whiteText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
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
