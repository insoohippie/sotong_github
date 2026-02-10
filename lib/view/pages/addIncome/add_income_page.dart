import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../model/addIncome/income_entry.dart';
import '../../../view_model/addIncome/add_income_view_model.dart';
import '../plan/plan_widgets/plan_input_modal/category_utils.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _contentControllers = {};

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    for (final c in _contentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddIncomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: '추가 입금',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(vm.entries.length, (index) {
                      return _buildIncomeEntry(context, vm, index);
                    }),
                    const SizedBox(height: AppSpacing.sectionSpacing),

                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.greyBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: vm.addEntry,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColors.subText,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '입금내역 추가',
                                  style: TextStyle(
                                    color: AppColors.subText,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: '다음',
                enabled: true,
                onPressed: () => _onNextPressed(context, vm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeEntry(BuildContext context, AddIncomeViewModel vm, int index) {
    final entry = vm.entries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.fieldSpacing),
      child: GestureDetector(
        onLongPress: () => _showItemOptions(context, vm, index),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCategoryField(context, vm, index, entry),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildAmountField(vm, index, entry),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildContentField(vm, index, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField(
      BuildContext context,
      AddIncomeViewModel vm,
      int index,
      IncomeEntry entry,
      ) {
    final name = entry.category.trim();
    final emoji = name.isEmpty ? '💰' : (vm.categoryEmojis[name] ?? '💰');

    return CategoryPill(
      text: entry.category,
      emoji: emoji,
      onTap: () => _showCategorySheet(context, vm, index, entry),
      onClear: () => vm.updateEntry(index, category: ''),
    );
  }

  Widget _buildContentField(AddIncomeViewModel vm, int index, IncomeEntry entry) {
    final controller =
    _contentControllers[index] ??= TextEditingController(text: entry.content ?? '');

    return CustomTextField(
      controller: controller,
      hintText: '내용을 입력하세요',
      onChanged: (value) {
        vm.updateEntry(
          index,
          content: value.isEmpty ? null : value,
        );
      },
      height: 60,
    );
  }

  Widget _buildAmountField(AddIncomeViewModel vm, int index, IncomeEntry entry) {
    final controller =
    _amountControllers[index] ??= TextEditingController(text: entry.amount ?? '');

    return CustomTextField(
      controller: controller,
      hintText: '(예: 10,000)',
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final un = _unformatNumber(value);

        vm.updateEntry(
          index,
          amount: un.isEmpty ? null : un,
        );

        final formatted = _formatNumber(un);
        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
      height: 60,
    );
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

  void _showCategorySheet(
      BuildContext context,
      AddIncomeViewModel vm,
      int index,
      IncomeEntry entry,
      ) {
    final categoryController = TextEditingController(text: entry.category);

    final alreadySelectedNames = vm.entries
        .map((e) => e.category.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    openCategorySheet(
      context,
      categoryController,
          (value) {
        vm.updateEntry(index, category: value);
      },
      categories: vm.categories,          // ✅ 기본4개+커스텀 전체
      categoryEmojis: vm.categoryEmojis,  // ✅ 이모지 맵

      alreadySelectedNames: alreadySelectedNames,
      currentSelectedName: entry.category.trim(),

      onSelectedWithEmoji: (name, emoji) {
        vm.setCategoryEmoji(name, emoji);
      },

      onCategoryAdded: (name, emoji) {
        vm.addCategoryWithEmoji(name, emoji);
      },
      onCategoryRemoved: (name) {
        vm.removeCategory(name);
      },
      onReorder: (newOrder) {
        // ✅ 필요하면 여기서 vm 쪽에 순서 저장 로직 붙이면 됨
      },
    );
  }

  void _showItemOptions(BuildContext context, AddIncomeViewModel vm, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.pop(context);
                  final ok = vm.removeEntry(index);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('최소 하나의 항목은 유지해야 합니다')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onNextPressed(BuildContext context, AddIncomeViewModel vm) {
    if (vm.totalAmount == 0) {
      _showSnackBar(context, '최소 하나의 입금 내역을 입력해주세요');
      return;
    }

    vm.appliedAmountText = vm.totalFormatted;
    Navigator.of(context).pushNamed('/apply_income_option');
  }
}
