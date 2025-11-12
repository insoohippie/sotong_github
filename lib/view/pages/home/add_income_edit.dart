import 'package:flutter/material.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../model/income_entry.dart';
import '../../../view/pages/plan/chat_widgets/input_modal/category_utils.dart';

class AddIncomeEditPage extends StatefulWidget {
  const AddIncomeEditPage({super.key});

  @override
  State<AddIncomeEditPage> createState() => _AddIncomeEditPageState();
}

class _AddIncomeEditPageState extends State<AddIncomeEditPage> {
  List<IncomeEntry> _incomeEntries = [];

  // 사용자 정의 카테고리 관리
  List<String> _customCategories = [];
  Map<String, String> _categoryEmojis = {};

  // 컨트롤러 캐싱으로 성능 최적화
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _contentControllers = {};

  // 월 수입 카테고리 프리셋 사용
  final List<CatPreset> _categories = incomePresets;

  @override
  void initState() {
    super.initState();
    _addNewEntry();
  }

  @override
  void dispose() {
    // 컨트롤러 정리
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    for (final controller in _contentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewEntry() {
    setState(() {
      final index = _incomeEntries.length;
      _incomeEntries.add(IncomeEntry(category: ''));
      _amountControllers[index] = TextEditingController();
      _contentControllers[index] = TextEditingController();
    });
  }

  void _updateEntry(int index, IncomeEntry entry) {
    setState(() {
      _incomeEntries[index] = entry;
    });
  }

  // 사용자 정의 카테고리 추가
  void _addCustomCategory(String category, String emoji) {
    setState(() {
      if (!_customCategories.contains(category)) {
        _customCategories.add(category);
        _categoryEmojis[category] = emoji;
      }
    });
  }

  // 사용자 정의 카테고리 삭제
  void _removeCustomCategory(String category) {
    setState(() {
      _customCategories.remove(category);
      _categoryEmojis.remove(category);
    });
  }

  void _saveIncome() {
    // 빈 항목들 제거
    final validEntries = _incomeEntries
        .where((entry) => !entry.isEmpty)
        .toList();

    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 하나의 입금 내역을 입력해주세요')));
      return;
    }

    // 총 금액 계산
    int totalAmount = 0;
    for (final entry in validEntries) {
      if (entry.amount != null) {
        final cleanAmount = entry.amount!.replaceAll(',', '');
        totalAmount += int.tryParse(cleanAmount) ?? 0;
      }
    }

    // TODO: 실제 저장 로직 구현
    // 금액 변화 선택 페이지로 이동
    Navigator.of(context).pushReplacementNamed(
      '/amount_change_choice',
      arguments:
          '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: '추가 입금 (편집용)',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 입금 내역들
                    ...List.generate(_incomeEntries.length, (index) {
                      return _buildIncomeEntry(index);
                    }),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // 입금내역 추가 버튼 (카테고리 스타일)
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
                          onTap: _addNewEntry,
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

            // 하단 버튼 (카테고리 스타일 적용)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: '다음',
                enabled: true,
                onPressed: _saveIncome,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeEntry(int index) {
    final entry = _incomeEntries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.fieldSpacing),
      child: GestureDetector(
        onLongPress: () => _showItemOptions(index),
        child: Column(
          children: [
            // 첫 번째 줄: 카테고리(왼쪽) + 금액(오른쪽)
            Row(
              children: [
                // 카테고리 Pill (왼쪽, flex: 2)
                Expanded(flex: 2, child: _buildCategoryField(index, entry)),
                const SizedBox(width: 8),
                // 금액 입력 (오른쪽, flex: 3)
                Expanded(flex: 3, child: _buildAmountField(index, entry)),
              ],
            ),
            const SizedBox(height: 8),
            // 두 번째 줄: 내용 입력
            _buildContentField(index, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField(int index, IncomeEntry entry) {
    return CategoryPill(
      text: entry.category,
      presets: _categories,
      onTap: () => _showCategorySheet(index, entry),
      onClear: () {
        _updateEntry(
          index,
          IncomeEntry(
            category: '',
            content: entry.content,
            amount: entry.amount,
          ),
        );
      },
      customEmoji: _categoryEmojis[entry.category],
    );
  }

  Widget _buildContentField(int index, IncomeEntry entry) {
    return CustomTextField(
      controller: _contentControllers[index] ??= TextEditingController(
        text: entry.content ?? '',
      ),
      hintText: '내용을 입력하세요',
      onChanged: (value) {
        _updateEntry(
          index,
          IncomeEntry(
            category: entry.category,
            content: value.isEmpty ? null : value,
            amount: entry.amount,
          ),
        );
      },
      height: 60,
    );
  }

  Widget _buildAmountField(int index, IncomeEntry entry) {
    final controller = _amountControllers[index] ??= TextEditingController(
      text: entry.amount ?? '',
    );

    return CustomTextField(
      controller: controller,
      hintText: '(예: 10,000)',
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final un = _unformatNumber(value);

        // entry 업데이트
        _updateEntry(
          index,
          IncomeEntry(
            category: entry.category,
            content: entry.content,
            amount: un.isEmpty ? null : un,
          ),
        );

        // 표시용 포맷(콤마)
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

  // 금액 포맷 유틸
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

  // 월 수입 카테고리 선택 시트
  void _showCategorySheet(int index, IncomeEntry entry) {
    // 프리셋 카테고리의 이모지 가져오기
    String getPresetEmoji(String categoryName) {
      switch (categoryName) {
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

    openCategorySheet(
      context,
      TextEditingController(text: entry.category),
      (value) {
        // 프리셋 카테고리인 경우 이모지도 함께 저장
        if (_categories.any((cat) => cat.name == value)) {
          _categoryEmojis[value] = getPresetEmoji(value);
        }

        _updateEntry(
          index,
          IncomeEntry(
            category: value,
            content: entry.content,
            amount: entry.amount,
          ),
        );
      },
      presets: _categories,
      customCategories: _customCategories,
      onCustomCategoryAdded: (category) => _addCustomCategory(category, '💰'),
      onCustomCategoryRemoved: _removeCustomCategory,
      onCustomCategoryAddedWithEmoji: _addCustomCategory,
      categoryEmojis: _categoryEmojis,
    );
  }

  // 꾹 누르기 옵션 메뉴
  void _showItemOptions(int index) {
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
              // grab bar
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

              // 옵션 버튼들
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.pop(context);
                  _removeEntry(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 항목 삭제
  void _removeEntry(int index) {
    if (_incomeEntries.length > 1) {
      setState(() {
        _incomeEntries.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 하나의 항목은 유지해야 합니다')));
    }
  }
}
