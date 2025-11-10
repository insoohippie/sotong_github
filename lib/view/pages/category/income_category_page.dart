import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import '../plan/chat_widgets/input_modal/category_utils.dart';
import 'category_state_manager.dart';

/// 월 수입 카테고리 관리 페이지
class IncomeCategoryPage extends StatefulWidget {
  const IncomeCategoryPage({Key? key}) : super(key: key);

  @override
  State<IncomeCategoryPage> createState() => _IncomeCategoryPageState();
}

class _IncomeCategoryPageState extends State<IncomeCategoryPage> {
  final List<CatPreset> _incomeCategories = [
    const CatPreset('급여', Icons.account_balance_wallet_rounded),
    const CatPreset('사업', Icons.business_center_rounded),
    const CatPreset('배당', Icons.trending_up_rounded),
    const CatPreset('용돈', Icons.card_giftcard_rounded),
  ];

  late List<bool> _categoryEnabled;

  @override
  void initState() {
    super.initState();
    _categoryEnabled = List.from(CategoryStateManager.incomeEnabledStates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '월 수입 카테고리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _incomeCategories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _incomeCategories[i];
          return Dismissible(
            key: Key(item.name),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('카테고리 삭제'),
                  content: Text('${item.name} 카테고리를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              setState(() {
                _incomeCategories.removeAt(i);
                _categoryEnabled.removeAt(i);
                CategoryStateManager.updateIncomeStates(_categoryEnabled);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} 카테고리가 삭제되었습니다')),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 24),
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _categoryEnabled[i] ? Colors.black : Colors.grey,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => _editCategory(i),
                    ),
                    Switch(
                      value: _categoryEnabled[i],
                      onChanged: (value) {
                        setState(() {
                          _categoryEnabled[i] = value;
                          CategoryStateManager.setIncomeState(i, value);
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _addCategory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AddEditCategoryPage(
          onSave: (name, icon, color) {
            setState(() {
              _incomeCategories.add(CatPreset(name, icon));
              _categoryEnabled.add(true); // 새 카테고리는 기본적으로 활성화
              CategoryStateManager.updateIncomeStates(_categoryEnabled);
            });
          },
        ),
      ),
    );
  }

  void _editCategory(int index) {
    final item = _incomeCategories[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AddEditCategoryPage(
          initialName: item.name,
          initialIcon: item.icon,
          onSave: (name, icon, color) {
            setState(() {
              _incomeCategories[index] = CatPreset(name, icon);
            });
          },
        ),
      ),
    );
  }
}

class _AddEditCategoryPage extends StatefulWidget {
  final String? initialName;
  final IconData? initialIcon;
  final Color? initialColor;
  final Function(String name, IconData icon, Color color) onSave;

  const _AddEditCategoryPage({
    this.initialName,
    this.initialIcon,
    this.initialColor,
    required this.onSave,
  });

  @override
  State<_AddEditCategoryPage> createState() => _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends State<_AddEditCategoryPage> {
  final _name = TextEditingController();
  late IconData _selectedIcon;
  late Color _selectedColor;

  // 아이콘 후보 (수입 관련)
  final List<IconData> _iconCandidates = const [
    Icons.account_balance_wallet_rounded,
    Icons.business_center_rounded,
    Icons.trending_up_rounded,
    Icons.card_giftcard_rounded,
    Icons.payments_rounded,
    Icons.handshake_rounded,
    Icons.savings_rounded,
    Icons.attach_money_rounded,
    Icons.account_balance_rounded,
    Icons.work_rounded,
    Icons.monetization_on_rounded,
    Icons.receipt_long_rounded,
    Icons.diamond_rounded,
    Icons.star_rounded,
    Icons.grade_rounded,
  ];

  // 색상 후보(파스텔 느낌)
  final List<Color> _colorCandidates = const [
    Color(0xFFFFE082), // amber
    Color(0xFFFFAB91), // orange
    Color(0xFFFFCDD2), // pink
    Color(0xFFCE93D8), // purple
    Color(0xFFB39DDB), // deep purple
    Color(0xFF90CAF9), // blue
    Color(0xFFA5D6A7), // green
    Color(0xFFC5E1A5), // light green
    Color(0xFFFFF59D), // yellow
    Color(0xFF80CBC4), // teal
    Color(0xFFB0BEC5), // blue grey
  ];

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {})); // 버튼 활성/비활성 갱신

    if (widget.initialName != null) {
      // 수정 모드: 기존 데이터 로드
      _name.text = widget.initialName!;
      _selectedIcon =
          widget.initialIcon ?? Icons.account_balance_wallet_rounded;
      _selectedColor = widget.initialColor ?? _colorCandidates[0];
    } else {
      // 추가 모드: 기본값 설정
      _selectedIcon = _iconCandidates[0];
      _selectedColor = _colorCandidates[0];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카테고리 이름을 입력하세요.')));
      return;
    }
    widget.onSave(n, _selectedIcon, _selectedColor);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _name.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialName != null ? '카테고리 수정' : '카테고리 추가',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 서브타이틀
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '아이콘과 색상을 선택하세요',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.fieldSpacing),
                      const SubText(text: '카테고리명', fontWeight: FontWeight.w600),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _name,
                        hintText: '카테고리 이름을 입력하세요',
                        onChanged: (_) {}, // 리스너로 상태 갱신 중
                        height: 60,
                      ),

                      const SizedBox(height: 24),
                      const SubText(text: '아이콘', fontWeight: FontWeight.w600),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _iconCandidates.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemBuilder: (_, i) {
                            final icon = _iconCandidates[i];
                            final selected = icon == _selectedIcon;
                            return InkWell(
                              onTap: () => setState(() => _selectedIcon = icon),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.lightBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.subText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                      const SubText(text: '색상', fontWeight: FontWeight.w600),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _colorCandidates.map((c) {
                            final selected = c.value == _selectedColor.value;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = c),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFFE5E7EB),
                                    width: selected ? 3 : 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),
                      // 미리보기 카드
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _selectedColor.withOpacity(0.25),
                              child: Icon(_selectedIcon, color: Colors.black87),
                            ),
                            const SizedBox(width: 12),
                            const ParagraphText(
                              text: '미리보기',
                              fontWeight: FontWeight.w600,
                            ),
                            const Spacer(),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.bottomSpacing),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼
            CustomButton(text: '저장', enabled: isValid, onPressed: _save),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}
