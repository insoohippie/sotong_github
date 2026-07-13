import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'custom_text_field.dart';

class SignedAmountTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SignedAmountTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  State<SignedAmountTextField> createState() => _SignedAmountTextFieldState();
}

class _SignedAmountTextFieldState extends State<SignedAmountTextField> {
  String _sign = '+';
  late final TextEditingController _amountController;
  bool _isFormattingAmount = false;

  @override
  void initState() {
    super.initState();

    final raw = widget.controller.text.trim().replaceAll(',', '');

    _sign = raw.startsWith('-') ? '-' : '+';

    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _amountController = TextEditingController(
      text: digitsOnly.isEmpty ? '' : _formatWithThousands(digitsOnly),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _syncParentController() {
    final amount = _amountController.text.trim();

    final signedValue = amount.isEmpty
        ? ''
        : _sign == '-'
            ? '-$amount'
            : amount;

    widget.controller.text = signedValue;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );

    widget.onChanged?.call(signedValue);
  }

  void _toggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      _sign = _sign == '+' ? '-' : '+';
    });
    _syncParentController();
  }

  String _formatWithThousands(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    final number = int.tryParse(digitsOnly);
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
  }

  void _onAmountChanged(String value) {
    if (_isFormattingAmount) return;

    _isFormattingAmount = true;
    final formatted = _formatWithThousands(value);
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _isFormattingAmount = false;
    _syncParentController();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          height: 60,
          child: Material(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleSign,
              child: Center(
                child: Text(
                  _sign,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomTextField(
            controller: _amountController,
            hintText: widget.hintText,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: _onAmountChanged,
          ),
        ),
      ],
    );
  }
}
