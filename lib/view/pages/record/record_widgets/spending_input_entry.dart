import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../component/inputs/custom_text_field.dart';

import '../../../../view_model/category/category_edit_view_model.dart';
import '../../../../model/category/category_snapshot_item.dart';

import 'spending_category_sheet.dart'; // ✅ openSpendingCategorySheetWithKey, SpendingCategoryPick
import '../../plan/plan_widgets/plan_input_modal/category_utils.dart'; // CategoryPill, dailyPresets

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
  void didUpdateWidget(covariant SpendingInputEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = (widget.entry['category'] as String?) ?? '';
    if (newText != _categoryController.text) {
      _categoryController.text = newText;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  // ---------- 금액 포맷 ----------
  String _unformatNumber(String v) => v.replaceAll(',', '');
  String _formatNumber(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_unformatNumber(v));
    if (n == null) return '';
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    final amountController =
    widget.entry['amountController'] as TextEditingController;
    final noteController =
    widget.entry['noteController'] as TextEditingController;

    final vm = context.watch<CategoryEditViewModel>();

    // ✅ plan/ref 전체 목록
    final planCats = vm.draftPlan;
    final refCats = vm.draftRef;

    // ✅ 선택 상태: source / key / name
    final String? selectedSource = widget.entry['categorySource'] as String?;
    final String? selectedKey = widget.entry['categoryKey'] as String?;
    final String selectedName = (widget.entry['category'] as String?) ?? '';

    final bool isPlanSelected = selectedSource == 'plan';

    // ✅ 현재 표시할 이모지(선택된 key 우선)
    String? currentEmoji;
    if (selectedKey != null && selectedKey.isNotEmpty) {
      final foundInPlan =
      planCats.where((c) => c.categoryId == selectedKey).toList();
      final foundInRef = refCats.where((c) => c.categoryId == selectedKey).toList();
      currentEmoji = foundInPlan.isNotEmpty
          ? (foundInPlan.first.emoji ?? '💰')
          : (foundInRef.isNotEmpty ? (foundInRef.first.emoji ?? '💰') : null);
    }
    // key 없으면 name 기반 fallback
    currentEmoji ??= (() {
      final p = planCats.where((c) => c.name == selectedName).toList();
      if (p.isNotEmpty) return p.first.emoji ?? '💰';
      final r = refCats.where((c) => c.name == selectedName).toList();
      if (r.isNotEmpty) return r.first.emoji ?? '💰';
      return null;
    })();

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
                        final picked = await openSpendingCategorySheetWithKey(
                          context,
                          planItems: planCats,
                          refItems: refCats,

                          // ✅ ref 편집 허용
                          onAddRef: (name, emoji) {
                            vm.draftAddRefCategoryByName(name: name, emoji: emoji);
                          },
                          onRemoveRef: (name) {
                            vm.draftDeleteRefByName(name);
                          },
                          onReorderRef: (newOrderNames) {
                            vm.draftReorderRefByNames(newOrderNames);
                          },

                          selectedName: widget.entry['category'] as String?,
                          selectedKey: widget.entry['categoryKey'] as String?,
                        );

                        if (picked == null) return;

                        setState(() {
                          _categoryController.text = picked.name;
                          widget.entry['category'] = picked.name;

                          widget.entry['categoryKey'] = picked.key;
                          widget.entry['categorySource'] = picked.source;      // 'plan' | 'ref'
                          widget.entry['categoryEmoji'] = picked.emoji;        // (선택)
                        });
                      },
                      onClear: () {
                        setState(() {
                          _categoryController.clear();
                          widget.entry['category'] = '';
                          widget.entry.remove('categoryKey');
                          widget.entry.remove('categorySource');
                          widget.entry.remove('categoryEmoji');
                        });
                      },
                      customEmoji: currentEmoji,
                      highlight: true,
                      highlightColor: isPlanSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : const Color(0xFF6B7280).withOpacity(0.08),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 금액 입력
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: amountController,
                      hintText: '예) 10,000',
                      keyboardType: TextInputType.number,
                      borderRadius: 12,
                      height: 60,
                      onChanged: (value) {
                        final un = _unformatNumber(value);
                        final amt = double.tryParse(un) ?? 0;
                        widget.entry['amount'] = amt;

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

              // 출처 표시 뱃지
              if ((_categoryController.text).trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPlanSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : const Color(0xFF6B7280).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPlanSelected ? '플랜 카테고리' : '참고 카테고리',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPlanSelected
                              ? AppColors.primary
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
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
