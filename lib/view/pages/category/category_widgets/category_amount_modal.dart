import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ✅ 금액 모달 (바텀시트 UI + 슬라이드 애니메이션)
class CategoryAmountModal extends StatefulWidget {
  final bool isOpen;
  final int initialAmount;

  final VoidCallback onClose;
  final void Function(int amount) onComplete;

  const CategoryAmountModal({
    super.key,
    required this.isOpen,
    required this.initialAmount,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<CategoryAmountModal> createState() => _CategoryAmountModalState();
}

class _CategoryAmountModalState extends State<CategoryAmountModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _scrimFade;

  late final TextEditingController _amountCtrl;
  late final FocusNode _focusNode;

  static const int _kSlideMs = 500;

  @override
  void initState() {
    super.initState();

    _amountCtrl = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '',
    );
    _focusNode = FocusNode();

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
  void didUpdateWidget(covariant CategoryAmountModal oldWidget) {
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

    if (oldWidget.initialAmount != widget.initialAmount) {
      _amountCtrl.text =
      widget.initialAmount > 0 ? widget.initialAmount.toString() : '';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _amountCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    if (_ctrl.status == AnimationStatus.dismissed ||
        _ctrl.status == AnimationStatus.reverse) return;
    await _ctrl.reverse();
    if (mounted) widget.onClose();
  }

  bool get _isValid {
    final text = _amountCtrl.text.replaceAll(',', '').trim();
    if (text.isEmpty) return false;
    final amount = int.tryParse(text);
    return amount != null && amount >= 0;
  }

  String get _buttonText {
    final text = _amountCtrl.text.replaceAll(',', '').trim();
    if (text.isEmpty) return '일일 금액을 입력해주세요!';
    final amount = int.tryParse(text);
    if (amount == null || amount < 0) return '올바른 금액을 입력해주세요!';
    return '제 일일 금액이에요!';
  }

  void _submit() {
    final value = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (value < 0) return;
    widget.onComplete(value);
    _closeWithAnimation();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            controller: _amountCtrl,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '일일 소비 한도 금액을 입력하세요',
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
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isValid ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isValid
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF9CA3AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _buttonText,
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
        ],
      ),
    );
  }
}
