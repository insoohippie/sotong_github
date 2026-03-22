import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../component/inputs/custom_text_field.dart';
import '../../../../../component/theme/app_colors.dart';

class MinimalField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool isNumber;
  final String? hint;
  final ValueChanged<String>? onChanged;

  final List<String>? dropdownOptions;
  final String? selectedValue;
  final ValueChanged<String?>? onDropdownChanged;
  final bool showDivider;

  const MinimalField({
    Key? key,
    required this.label,
    this.controller,
    this.isNumber = false,
    this.hint,
    this.onChanged,
    this.dropdownOptions,
    this.selectedValue,
    this.onDropdownChanged,
    this.showDivider = true,
  }) : super(key: key);

  String _unformat(String v) => v.replaceAll(',', '');
  String _format(String v) {
    if (v.isEmpty) return '';
    final isNegative = v.startsWith('-');
    final digits = _unformat(v).replaceAll('-', '');
    if (digits.isEmpty) return isNegative ? '-' : '';
    final n = int.tryParse(digits);
    if (n == null) return '';
    final formatted = NumberFormat('#,###').format(n);
    return isNegative ? '-$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard Variable',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          if (dropdownOptions != null)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.greyBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                  items: dropdownOptions!
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: onDropdownChanged,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Pretendard Variable',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                ),
              ),
            )
          else
            CustomTextField(
              controller: controller!,
              hintText: hint ?? '',
              backgroundColor: AppColors.greyBackground,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              onChanged: (value) {
                if (isNumber) {
                  final raw = (label == "보유 자산")
                      ? value.replaceAll(RegExp(r'[^0-9-]'), '')
                      : value.replaceAll(RegExp(r'[^0-9]'), '');

                  String sanitized = raw;
                  if (label == "보유 자산") {
                    final hasMinus = raw.startsWith('-');
                    sanitized = raw.replaceAll('-', '');
                    if (hasMinus) sanitized = '-$sanitized';
                  }
                  final formatted = _format(sanitized);
                  if (formatted != value) {
                    controller!.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                }
                if (onChanged != null) onChanged!(controller!.text);
              },
            ),
          const SizedBox(height: 16),
          if (showDivider) Divider(height: 5, color: AppColors.greyBackground),
        ],
      ),
    );
  }
}
