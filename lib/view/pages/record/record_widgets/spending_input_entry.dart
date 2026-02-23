import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../component/inputs/custom_text_field.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';
import '../../../../view_model/category/spending_category_view_model.dart';

import 'record_category_pill.dart';
import 'record_category_sheet.dart';

class SpendingInputEntry extends StatefulWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;

  const SpendingInputEntry({
    super.key,
    required this.entry,
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

  String? _emojiByKeyOrName({
    required String? key,
    required String name,
    required List<CategoryEditItem> planItems,
    required List<RefCategoryItem> refItems,
  }) {
    if (key != null && key.isNotEmpty) {
      final p = planItems.where((e) => e.categoryKey == key).toList();
      if (p.isNotEmpty) return p.first.emoji;
      final r = refItems.where((e) => e.categoryKey == key).toList();
      if (r.isNotEmpty) return r.first.emoji;
    }

    final p2 = planItems.where((e) => e.name == name).toList();
    if (p2.isNotEmpty) return p2.first.emoji;

    final r2 = refItems.where((e) => e.name == name).toList();
    if (r2.isNotEmpty) return r2.first.emoji;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final catVM = context.watch<SpendingCategoryViewModel>();
    final planItems = catVM.planItems;
    final refItems = catVM.refItems;

    final amountController = widget.entry['amountController'] as TextEditingController;
    final noteController = widget.entry['noteController'] as TextEditingController;

    final String? selectedKey = widget.entry['categoryKey'] as String?;
    final String selectedName = (widget.entry['category'] as String?) ?? '';

    final currentEmoji = _emojiByKeyOrName(
      key: selectedKey,
      name: selectedName,
      planItems: planItems,
      refItems: refItems,
    ) ??
        '💰';

    final bool canInteract = !catVM.loading;

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
                    child: AbsorbPointer(
                      absorbing: !canInteract,
                      child: Opacity(
                        opacity: canInteract ? 1 : 0.6,
                        child: RecordCategoryPill(
                          text: _categoryController.text,
                          emoji: currentEmoji,
                          onTap: () async {
                            final picked = await openRecordCategorySheetWithKey(
                              context,
                              planItems: planItems,
                              refItems: refItems,
                              onAddRef: (name, emoji) => context
                                  .read<SpendingCategoryViewModel>()
                                  .addRef(name: name, emoji: emoji),
                              onRemoveRef: (key) => context
                                  .read<SpendingCategoryViewModel>()
                                  .removeRefByKey(key),
                              onReorderRef: (keys) => context
                                  .read<SpendingCategoryViewModel>()
                                  .reorderRefByKeys(keys),
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
                          highlightColor: AppColors.primary.withOpacity(0.06),
                        ),
                      ),
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
