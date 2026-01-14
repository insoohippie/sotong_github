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
  // 컨트롤러는 화면에서 관리 (뷰모델은 값만)
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
                    // 입금 내역들
                    ...List.generate(vm.entries.length, (index) {
                      return _buildIncomeEntry(context, vm, index);
                    }),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // 입금내역 추가 버튼
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
                          onTap: () {
                            vm.addEntry();
                          },
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

            // 하단 버튼
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

  // ===================== 위젯 빌더들 =====================

  Widget _buildIncomeEntry(
      BuildContext context,
      AddIncomeViewModel vm,
      int index,
      ) {
    final entry = vm.entries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.fieldSpacing),
      child: GestureDetector(
        onLongPress: () => _showItemOptions(context, vm, index),
        child: Column(
          children: [
            // 첫 줄: 카테고리 + 금액
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
            // 둘째 줄: 내용
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
    return CategoryPill(
      text: entry.category,
      presets: vm.categories, // 아이콘용 (급여/사업/배당/용돈 등)
      customEmoji: vm.categoryEmojis[entry.category],
      onTap: () => _showCategorySheet(context, vm, index, entry),
      onClear: () {
        vm.updateEntry(index, category: '');
      },
    );
  }

  Widget _buildContentField(
      AddIncomeViewModel vm,
      int index,
      IncomeEntry entry,
      ) {
    final controller = _contentControllers[index] ??=
        TextEditingController(text: entry.content ?? '');

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

  Widget _buildAmountField(
      AddIncomeViewModel vm,
      int index,
      IncomeEntry entry,
      ) {
    final controller = _amountControllers[index] ??=
        TextEditingController(text: entry.amount ?? '');

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

  // ===================== 유틸 / 액션 =====================

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
    // 프리셋 카테고리 이모지 결정 로직 (수입용)
    String getPresetEmoji(String name) {
      switch (name) {
        case '급여':
          return '💼';
        case '사업':
          return '🏢';
        case '배당':
          return '📈';
        case '용돈':
          return '🎁';
        default:
          return '💰';
      }
    }

    // 1) 프리셋 이름 리스트
    final presetNames = vm.categories.map((c) => c.name).toList();
    // 2) 커스텀 카테고리
    final custom = vm.customCategories;
    // 3) 프리셋 + 커스텀 통합 (중복 제거)
    final allNames = <String>{
      ...presetNames,
      ...custom,
    }.toList();

    // 카테고리 입력용 컨트롤러 (바텀시트 안에서만 사용)
    final categoryController = TextEditingController(text: entry.category);

    openCategorySheet(
      context,
      categoryController,
      // onSelected
          (value) {
        // 선택된 카테고리 뷰모델에 반영
        vm.updateEntry(index, category: value);

        // 프리셋이면 프리셋 이모지 세팅
        if (vm.categories.any((c) => c.name == value)) {
          vm.setCategoryEmoji(value, getPresetEmoji(value));
        }
      },
      // 🔹 새 구조: 하나의 리스트로 전달
      categories: allNames,
      // 🔹 카테고리별 이모지 맵
      categoryEmojis: vm.categoryEmojis,
      // 🔹 새 커스텀 카테고리 추가될 때 (이름 + 이모지)
      onCategoryAdded: (name, emoji) {
        vm.addCustomCategory(name, emoji);
      },
      // 🔹 카테고리 삭제될 때
      onCategoryRemoved: (name) {
        vm.removeCustomCategory(name);
      },
      // 🔹 정렬 후 최종 순서 (원하면 뷰모델에 저장)
      onReorder: (newOrder) {
        // 예: vm.reorderCategories(newOrder);
        // 아직 정렬 저장 안 할 거면 비워둬도 됨
      },
    );
  }

  void _showItemOptions(
      BuildContext context,
      AddIncomeViewModel vm,
      int index,
      ) {
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
                      const SnackBar(
                        content: Text('최소 하나의 항목은 유지해야 합니다'),
                      ),
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

    // 이번에 입력한 총 금액을 뷰모델에 저장
    vm.appliedAmountText = vm.totalFormatted;

    // 다음 페이지로 이동 (뷰모델에서 금액을 읽어감)
    Navigator.of(context).pushNamed('/apply_income_option');
  }
}
