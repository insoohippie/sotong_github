import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color? backgroundColor;
  final double borderRadius;
  final double height;
  final String? suffix;

  const CustomNumberField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.height = 60.0,
    this.suffix = '원',
  }) : super(key: key);

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField> {
  late FocusNode _focusNode;
  late Color _currentBgColor;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _currentBgColor = _determineBackgroundColor();
    widget.controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    final newColor = _determineBackgroundColor();
    if (newColor != _currentBgColor) {
      setState(() => _currentBgColor = newColor);
    }
  }

  Color _determineBackgroundColor() {
    return widget.backgroundColor ??
        (widget.controller.text.isEmpty
            ? AppColors.greyBackground
            : AppColors.lightBlue);
  }

  String _formatNumber(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final number = int.parse(digits);
    return NumberFormat.decimalPattern().format(number);
  }

  void _onTextChanged(String value) {
    final oldText = widget.controller.text;
    final oldCursorPos = widget.controller.selection.baseOffset;

    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      widget.controller.text = '';
      widget.controller.selection = const TextSelection.collapsed(offset: 0);
      widget.onChanged?.call('');
      return;
    }

    final number = int.parse(digits);
    final formatted = NumberFormat.decimalPattern().format(number);

    // 커서 위치 보정
    final diff = formatted.length - oldText.length;
    final newCursorPos = (oldCursorPos + diff).clamp(0, formatted.length);

    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    widget.onChanged?.call(formatted);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: _currentBgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: AppTextStyles.paragraph,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: false,
          isDense: true,
          hintText: widget.hintText,
          hintStyle: AppTextStyles.paragraph.copyWith(color: Colors.grey),
          border: InputBorder.none,
          suffixText: widget.suffix,
          suffixStyle: AppTextStyles.paragraph.copyWith(color: AppColors.text),
        ),
        onChanged: _onTextChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }
}
