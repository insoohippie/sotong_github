import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/input_modal/category_utils.dart';
import 'package:sotong_local/view/pages/category/category_state_manager.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../component/inputs/custom_text_field.dart';

class SpendingInputEntry extends StatefulWidget {
  final Map<String, dynamic> entry;
  final List<String> categoryItems; // (호환성 유지용, 미사용)
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
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text: (widget.entry['category'] as String?) ?? '',
    );
    _categoryController.addListener(() {
      widget.entry['category'] = _categoryController.text;
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  // ---------- 금액 포맷 유틸 ----------
  String _unformatNumber(String v) => v.replaceAll(',', '');
  String _formatNumber(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_unformatNumber(v));
    if (n == null) return '';
    // 천단위 콤마
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    final amountController =
        widget.entry['amountController'] as TextEditingController;
    final noteController =
        widget.entry['noteController'] as TextEditingController;

    return Column(
      children: [
        Dismissible(
          key: ObjectKey(widget.entry),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDelete(),
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
                  // 카테고리 Pill
                  Expanded(
                    flex: 2,
                    child: CategoryPill(
                      text: _categoryController.text,
                      presets: dailyPresets,
                      onTap: () async {
                        await openCategorySheet(
                          context,
                          _categoryController,
                          (val) {
                            setState(() {
                              _categoryController.text = val;
                              widget.entry['category'] = val;
                            });
                          },
                          presets: dailyPresets,
                          enabledStates:
                              CategoryStateManager.dailyExpenseEnabledStates,
                          customCategories:
                              CategoryStateManager.customDailyExpenseCategories,
                          categoryEmojis:
                              CategoryStateManager.dailyExpenseCategoryEmojis,
                        );
                      },
                      onClear: () {
                        setState(() {
                          _categoryController.clear();
                          widget.entry['category'] = '';
                        });
                      },
                      customEmoji: CategoryStateManager
                          .dailyExpenseCategoryEmojis[_categoryController.text],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 금액 입력 (CustomTextField + 콤마 포맷)
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: amountController,
                      hintText: '(예: 10,000)',
                      keyboardType: TextInputType.number,
                      borderRadius: 12,
                      height: 60,
                      onChanged: (value) {
                        final un = _unformatNumber(value);
                        final amt = double.tryParse(un) ?? 0;

                        // entry에 실수 값으로 저장
                        widget.entry['amount'] = amt;

                        // 표시용 포맷(콤마)
                        final formatted = _formatNumber(un);
                        if (formatted != value) {
                          amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 노트 입력
              CustomTextField(
                controller: noteController,
                hintText: '노트 작성 (20자 이내)',
                onChanged: (text) {
                  setState(() {});

                  if (text.length > 20) {
                    noteController.text = text.substring(0, 20);
                    noteController.selection = TextSelection.fromPosition(
                      TextPosition(offset: noteController.text.length),
                    );
                  }
                  widget.entry['note'] = noteController.text;
                },
                height: 60,
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
