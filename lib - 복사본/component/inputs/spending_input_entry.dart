import 'package:flutter/material.dart';
import '../buttons/select_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'custom_number_field.dart';
import 'custom_text_field.dart';

class SpendingInputEntry extends StatefulWidget {
  final Map<String, dynamic> entry;
  final List<String> categoryItems;
  final VoidCallback onDelete;

  const SpendingInputEntry({
    super.key,
    required this.entry,
    required this.categoryItems,
    required this.onDelete,
  });

  @override
  State<SpendingInputEntry> createState() => _SpendingInputEntryState();
}

class _SpendingInputEntryState extends State<SpendingInputEntry> {
  bool _isValidInput = true;

  @override
  Widget build(BuildContext context) {
    final category = widget.entry['category'] as String?;
    final amountController =
        widget.entry['amountController'] as TextEditingController;
    final noteController =
        widget.entry['noteController'] as TextEditingController;

    return Column(
      children: [
        Dismissible(
          key: ObjectKey(widget.entry),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            widget.onDelete();
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SelectButton(
                      value: category,
                      items: widget.categoryItems,
                      onChanged: (val) {
                        setState(() {
                          widget.entry['category'] = val;
                        });
                      },
                      hintText: '선택',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: CustomNumberField(
                      controller: amountController,
                      hintText: '예: 20,000',
                      backgroundColor: const Color(0xFFF3F4F6),
                      borderRadius: 12,
                      height: 56,
                      suffix: '₩',
                      onChanged: (value) {
                        setState(() {
                          final text = value.replaceAll(',', '');
                          _isValidInput =
                              text.isNotEmpty && int.tryParse(text) != null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: noteController,
                hintText: '노트 작성 (20자 이내)',
                onChanged: (text) {
                  if (text.length > 20) {
                    noteController.text = text.substring(0, 20);
                    noteController.selection = TextSelection.fromPosition(
                      TextPosition(offset: noteController.text.length),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.fieldSpacing),
        const Divider(
          color: AppColors.greyBackground,
          thickness: 1.0,
          height: 10,
        ),
        const SizedBox(height: AppSpacing.fieldSpacing),
      ],
    );
  }
}
