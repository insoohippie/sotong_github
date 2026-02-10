import 'package:flutter/material.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../component/inputs/custom_text_field.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

import 'spending_category_sheet.dart';
import '../../plan/plan_widgets/plan_input_modal/category_utils.dart'; // CategoryPill

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

  late List<CategoryEditItem> _planCats;
  late List<RefCategoryItem> _refCats;

  @override
  void initState() {
    super.initState();

    _planCats = [
      const CategoryEditItem(
        categoryKey: 'plan_food',
        name: '식비',
        emoji: '🍽️',
        order: 0,
        kind: CategoryKind.plan,
        dailyAmount: 15000,
      ),
      const CategoryEditItem(
        categoryKey: 'plan_cafe',
        name: '카페',
        emoji: '☕',
        order: 1,
        kind: CategoryKind.plan,
        dailyAmount: 5000,
      ),
      const CategoryEditItem(
        categoryKey: 'plan_transport',
        name: '교통',
        emoji: '🚌',
        order: 2,
        kind: CategoryKind.plan,
        dailyAmount: 3000,
      ),
      const CategoryEditItem(
        categoryKey: 'plan_shop',
        name: '쇼핑',
        emoji: '🛍️',
        order: 3,
        kind: CategoryKind.plan,
        dailyAmount: 10000,
      ),
    ];

    _refCats = [
      const RefCategoryItem(
        categoryKey: 'ref_gift',
        name: '선물',
        emoji: '🎁',
        order: 0,
      ),
      const RefCategoryItem(
        categoryKey: 'ref_pet',
        name: '반려동물',
        emoji: '🐕',
        order: 1,
      ),
    ];

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

  String? _emojiByKeyOrName({required String? key, required String name}) {
    if (key != null && key.isNotEmpty) {
      final p = _planCats.where((e) => e.categoryKey == key).toList();
      if (p.isNotEmpty) return p.first.emoji;
      final r = _refCats.where((e) => e.categoryKey == key).toList();
      if (r.isNotEmpty) return r.first.emoji;
    }
    final p2 = _planCats.where((e) => e.name == name).toList();
    if (p2.isNotEmpty) return p2.first.emoji;
    final r2 = _refCats.where((e) => e.name == name).toList();
    if (r2.isNotEmpty) return r2.first.emoji;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final amountController = widget.entry['amountController'] as TextEditingController;
    final noteController = widget.entry['noteController'] as TextEditingController;

    final String? selectedSource = widget.entry['categorySource'] as String?;
    final String? selectedKey = widget.entry['categoryKey'] as String?;
    final String selectedName = (widget.entry['category'] as String?) ?? '';

    final bool isPlanSelected = selectedSource == 'plan';

    final currentEmoji = _emojiByKeyOrName(key: selectedKey, name: selectedName) ?? '💰';

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
                  Expanded(
                    flex: 2,
                    child: CategoryPill(
                      text: _categoryController.text,
                      emoji: currentEmoji, // ✅ 프리셋 없이 emoji만
                      onTap: () async {
                        final picked = await openSpendingCategorySheetWithKey(
                          context,
                          planItems: _planCats,
                          refItems: _refCats,
                          onAddRef: null,
                          onRemoveRef: null,
                          onReorderRef: null,
                          selectedName: widget.entry['category'] as String?,
                          selectedKey: widget.entry['categoryKey'] as String?,
                        );
                        if (picked == null) return;

                        setState(() {
                          _categoryController.text = picked.name;
                          widget.entry['category'] = picked.name;

                          widget.entry['categoryKey'] = picked.key;
                          widget.entry['categorySource'] = picked.source;
                          widget.entry['categoryEmoji'] = picked.emoji;

                          if (picked.source == 'ref' &&
                              !_refCats.any((e) => e.categoryKey == picked.key)) {
                            _refCats = [
                              ..._refCats,
                              RefCategoryItem(
                                categoryKey: picked.key,
                                name: picked.name,
                                emoji: picked.emoji,
                                order: _refCats.length,
                              ),
                            ];
                          }
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
                      highlight: true,
                      highlightColor: isPlanSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : const Color(0xFF6B7280).withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
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
                  widget.entry['note'] = noteController.text;
                  setState(() {});
                },
                height: 60,
              ),
              if ((_categoryController.text).trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          color: isPlanSelected ? AppColors.primary : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.fieldSpacing),
        const Divider(color: AppColors.greyBackground, thickness: 1.0, height: 10),
        const SizedBox(height: AppSpacing.fieldSpacing),
      ],
    );
  }
}
