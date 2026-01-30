import 'package:flutter/material.dart';

/// ✅ 이름 + 이모지 모달 (바텀시트 UI + 슬라이드 애니메이션 + 이모지 그리드)
class CategoryNameModal extends StatefulWidget {
  final bool isOpen;
  final String? initialName;
  final String? initialEmoji;

  final VoidCallback onClose;
  final void Function(String name, String emoji) onComplete;

  const CategoryNameModal({
    super.key,
    required this.isOpen,
    this.initialName,
    this.initialEmoji,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<CategoryNameModal> createState() => _CategoryNameModalState();
}

class _CategoryNameModalState extends State<CategoryNameModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _scrimFade;

  late final TextEditingController _nameCtrl;
  late final FocusNode _focusNode;

  String _selectedEmoji = '💰';
  bool _showEmojiPicker = false;

  static const int _kSlideMs = 500;

  // 기존 코드에서 가져온 이모지 리스트 (필요하면 줄여도 됨)
  static const List<String> _expenseEmojis = [
    '💰','💸','💳','🏦','💵','💶','💷','💴','🪙','💎',
    '🍕','🍔','🍟','🌭','🥪','🌮','🌯','🥙','🍱','🍜',
    '☕','🥤','🧋','🍵','🍶','🍷','🍸','🍹','🍺','🍻',
    '🛍️','🛒','💍','👕','👖','👗','👠','👟','🎒','👜',
    '🎬','🎮','🎯','🎲','🎪','🎨','🎭','🎡','🎠',
    '🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐',
    '✈️','🚁','🚀','🛸','🚢','⛵','🚤','🛥️','🚂',
    '🏠','🏡','🏢','🏬','🏪','🏫','🏩','🏨','🏦','🏛️',
    '💊','🏥','⚕️','🩺','💉','🧬','🦠','🧪','🧫','🧼',
    '📱','💻','⌨️','🖥️','🖨️','📠','📞','☎️','📺','📻',
    '🏋️','🤸','🧘','🏊','🚴','🏃','⚽','🏀','🏈','🎾',
    '📚','✏️','📝','📋','📊','📈','📉','💼','🗂️','📁',
    '🎁','🎂','🍰','🧁','🍭','🍬','🍫','🍩','🍪','🥧',
    '🌱','🌿','🌾','🌻','🌺','🌸','🌼','🌷','🌹','🥀',
    '🐕','🐈','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯',
  ];

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _focusNode = FocusNode();
    _selectedEmoji = widget.initialEmoji ?? '💰';

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSlideMs),
      reverseDuration: const Duration(milliseconds: _kSlideMs),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrimFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _ctrl.forward();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CategoryNameModal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _ctrl.forward().then((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) _focusNode.requestFocus();
        });
      } else {
        _focusNode.unfocus();
        _ctrl.reverse().whenComplete(() {
          if (mounted) widget.onClose();
        });
      }
    }

    if (oldWidget.initialName != widget.initialName) {
      _nameCtrl.text = widget.initialName ?? '';
    }
    if (oldWidget.initialEmoji != widget.initialEmoji) {
      _selectedEmoji = widget.initialEmoji ?? '💰';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _nameCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    if (_ctrl.status == AnimationStatus.dismissed ||
        _ctrl.status == AnimationStatus.reverse) return;
    await _ctrl.reverse();
    if (mounted) widget.onClose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onComplete(name, _selectedEmoji);
    _closeWithAnimation();
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // 닫힌 상태면 완전 제거
    if (!widget.isOpen && _ctrl.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: _ctrl.status == AnimationStatus.dismissed,
      child: Stack(
        children: [
          // 스크림
          FadeTransition(
            opacity: _scrimFade,
            child: GestureDetector(
              onTap: _closeWithAnimation,
              child: Container(color: Colors.black54),
            ),
          ),

          // 바텀시트
          Positioned.fill(
            child: SlideTransition(
              position: _slide,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, -4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // 이모지 버튼
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showEmojiPicker = !_showEmojiPicker;
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _selectedEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 이름 입력
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: TextField(
                                    controller: _nameCtrl,
                                    focusNode: _focusNode,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: widget.initialName == null
                                          ? '새 카테고리 이름'
                                          : '카테고리 이름',
                                      filled: true,
                                      fillColor: const Color(0xFFF3F4F6),
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF3B82F6),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 이모지 그리드
                          if (_showEmojiPicker) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: GridView.builder(
                                gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: _expenseEmojis.length,
                                itemBuilder: (context, index) {
                                  final emoji = _expenseEmojis[index];
                                  final isSelected = _selectedEmoji == emoji;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = emoji;
                                        _showEmojiPicker = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF3B82F6)
                                            .withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected
                                                ? const Color(0xFF3B82F6)
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // 완료 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isValid ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isValid
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF9CA3AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.initialName == null ? '추가' : '수정',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
