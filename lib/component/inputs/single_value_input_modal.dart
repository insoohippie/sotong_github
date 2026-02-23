import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../component/buttons/custom_button.dart';
import '../../../../../component/inputs/custom_text_field.dart';

/// 플랜챗 입력창 스타일의 단일값 입력 모달 (플랜 이름, 목표 금액, 보유 자산용)
/// ChatBottomInputArea와 동일한 UI 스타일 사용
class SingleValueInputModal extends StatefulWidget {
  final String hintText;
  final String buttonTextEmpty;
  final String buttonTextFilled;
  final String initialValue;
  final bool isNumber;
  final bool allowNegative;
  final void Function(String value) onComplete;
  final VoidCallback onClose;

  const SingleValueInputModal({
    Key? key,
    required this.hintText,
    required this.buttonTextEmpty,
    required this.buttonTextFilled,
    required this.initialValue,
    required this.onComplete,
    required this.onClose,
    this.isNumber = false,
    this.allowNegative = false,
  }) : super(key: key);

  @override
  State<SingleValueInputModal> createState() => _SingleValueInputModalState();
}

class _SingleValueInputModalState extends State<SingleValueInputModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNum(String v, {bool allowNegative = false}) {
    if (v.isEmpty) return '';
    final isNegative = allowNegative && v.startsWith('-');
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return isNegative ? '-' : '';
    final n = int.tryParse(digits);
    if (n == null) return v;
    final formatted = NumberFormat('#,###').format(n);
    return isNegative ? '-$formatted' : formatted;
  }

  void _onChanged(String value) {
    if (widget.isNumber) {
      if (widget.allowNegative) {
        final hasMinus = value.startsWith('-');
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        final combined = digits.isEmpty
            ? (hasMinus ? '-' : '')
            : (hasMinus ? '-$digits' : digits);
        final f = _formatNum(combined, allowNegative: true);
        if (f != _controller.text) {
          _controller.text = f;
          _controller.selection = TextSelection.collapsed(offset: f.length);
        }
      } else {
        final f = _formatNum(value);
        if (f != _controller.text) {
          _controller.text = f;
          _controller.selection = TextSelection.collapsed(offset: f.length);
        }
      }
    }
  }

  bool _isValid() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return false;
    if (widget.isNumber) {
      final amountStr = trimmed.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount == null) return false;
      if (!widget.allowNegative && amount <= 0) return false;
      return true;
    }
    return trimmed.length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    // 하단 패딩: 화면 높이의 약 4.5%로 통일 (어떤 폰이든 비율로 동일). SafeArea보다 작으면 SafeArea 사용
    final ratioBottom = (screenHeight * 0.045).clamp(24.0, 48.0);
    final totalBottom = ratioBottom > media.padding.bottom
        ? ratioBottom
        : media.padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 30,
        left: 20,
        right: 20,
        bottom: totalBottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                controller: _controller,
                hintText: widget.hintText,
                keyboardType: widget.isNumber
                    ? (widget.allowNegative
                          ? const TextInputType.numberWithOptions(signed: true)
                          : TextInputType.number)
                    : TextInputType.text,
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: _controller.text.trim().isEmpty
                  ? widget.buttonTextEmpty
                  : widget.buttonTextFilled,
              onPressed: _isValid()
                  ? () {
                      widget.onComplete(_controller.text.trim());
                      widget.onClose();
                    }
                  : () {},
              enabled: _isValid(),
            ),
          ],
        ),
      ),
    );
  }
}
