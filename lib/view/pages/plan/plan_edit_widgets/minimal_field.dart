import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/texts/subtext.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';

class MinimalField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool isNumber;
  final String? hint;
  final ValueChanged<String>? onChanged;

  final List<String>? dropdownOptions;
  final String? selectedValue;
  final ValueChanged<String?>? onDropdownChanged;

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
  }) : super(key: key);

  String _unformat(String v) => v.replaceAll(',', '');
  String _format(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_unformat(v));
    if (n == null) return '';
    return NumberFormat('#,###').format(n);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubText(text: label, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),

          if (dropdownOptions != null)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: selectedValue != null
                    ? AppColors.lightBlue
                    : AppColors.greyBackground,
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
                  style: AppTextStyles.paragraph,
                  dropdownColor: Colors.white,
                ),
              ),
            )
          else
            CustomTextField(
              controller: controller!,
              hintText: hint ?? '',
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              onChanged: (value) {
                if (isNumber) {
                  final formatted = _format(value);
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
        ],
      ),
    );
  }
}
