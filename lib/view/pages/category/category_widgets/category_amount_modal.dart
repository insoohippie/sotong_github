import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../component/buttons/custom_button.dart';
import '../../../../component/inputs/custom_text_field.dart';

/// ✅ UI-only CategoryAmountModal
/// - 애니메이션/스크림/오픈상태(isOpen) 제거
/// - 뒤 배경(scrim) + SlideTransition은 CategoryEditPage에서 관리
/// - 여기서는 "시트 내용 UI"만 그린다
class CategoryAmountModal extends StatefulWidget {
  final int initialAmount;

  /// CategoryEditPage에서 scrim 탭/뒤로가기 처리 시 호출
  final VoidCallback onClose;

  /// 완료 버튼 눌렀을 때 호출
  final void Function(int amount) onComplete;

  const CategoryAmountModal({
    super.key,
    required this.initialAmount,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<CategoryAmountModal> createState() => _CategoryAmountModalState();
}

class _CategoryAmountModalState extends State<CategoryAmountModal> {
  late final TextEditingController _amountCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _amountCtrl = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '',
    );
    _focusNode = FocusNode();

    // ✅ 시트가 올라온 뒤(부모 애니메이션 이후)에 포커스 주고 싶으면
    // CategoryEditPage에서 forward() 직후에 requestFocus 해주는 게 가장 깔끔함.
    // 그래도 여기서 기본 포커스 원하는 경우:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant CategoryAmountModal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialAmount != widget.initialAmount) {
      _amountCtrl.text =
      widget.initialAmount > 0 ? widget.initialAmount.toString() : '';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  int _parseAmount(String text) {
    final raw = text.replaceAll(',', '').trim();
    return int.tryParse(raw) ?? -1;
  }

  void _submit() {
    final v = _parseAmount(_amountCtrl.text);
    if (v < 0) return;
    widget.onComplete(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? theme.colorScheme.surface : Colors.white;

    return GestureDetector(
      // ✅ 시트 내부 탭이 scrim으로 새지 않게
      behavior: HitTestBehavior.translucent,
      onTap: () {},

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
              offset: const Offset(0, -4),
              blurRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ 버튼 폭과 동일하게 넓게(양옆 줄어드는 문제 방지)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomTextField(
                  controller: _amountCtrl,
                  focusNode: _focusNode, // ✅ CustomTextField가 받는 구조라면
                  hintText: '일일 소비 한도 금액을 입력하세요',
                  keyboardType: TextInputType.number,
                  onChanged: (_) {},
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ 입력 버벅임 방지: 버튼 활성/텍스트만 리스너로 갱신
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountCtrl,
                builder: (context, value, _) {
                  final raw = value.text.replaceAll(',', '').trim();
                  final amount = _parseAmount(value.text);
                  final isValid = raw.isNotEmpty && amount >= 0;

                  final buttonText = raw.isEmpty
                      ? '일일 금액을 입력해주세요!'
                      : (amount < 0 ? '올바른 금액을 입력해주세요!' : '제 일일 금액이에요!');

                  return CustomButton(
                    text: buttonText,
                    enabled: isValid,
                    onPressed: isValid ? _submit : () {},
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
