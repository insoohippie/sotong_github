import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/appbars/custom_app_bar_title_subtitle.dart';

import '../../../../view_model/record/daily_category_viewmodel.dart';
import '../../../../model/record/daily_category_item.dart';

// 네가 만든 컴포넌트/테마들
import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/buttons/custom_button.dart';
import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/texts/subtext.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart'; // ✅ 패딩값 통일

class DailyCategoryAddPage extends StatefulWidget {
  final DailyCategoryItem? editItem;
  final int? editIndex;

  const DailyCategoryAddPage({super.key, this.editItem, this.editIndex});

  @override
  State<DailyCategoryAddPage> createState() => _DailyCategoryAddPageState();
}

class _DailyCategoryAddPageState extends State<DailyCategoryAddPage> {
  final _name = TextEditingController();
  late IconData _selectedIcon;
  late Color _selectedColor;

  // 아이콘 후보
  final List<IconData> _iconCandidates = const [
    Icons.restaurant_rounded,
    Icons.ramen_dining_rounded,
    Icons.local_cafe_rounded,
    Icons.local_grocery_store_rounded,
    Icons.shopping_bag_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.book_rounded,
    Icons.medical_services_rounded,
    Icons.directions_bus_rounded,
    Icons.car_rental_rounded,
    Icons.house_rounded,
    Icons.lightbulb_rounded,
    Icons.savings_rounded,
    Icons.pets_rounded,
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

    if (widget.editItem != null) {
      // 수정 모드: 기존 데이터 로드
      _name.text = widget.editItem!.name;
      _selectedIcon = widget.editItem!.icon;
      _selectedColor = widget.editItem!.color;
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
    if (widget.editItem != null && widget.editIndex != null) {
      // 수정 모드
      context.read<DailyCategoryViewModel>().updateAt(
        widget.editIndex!,
        name: n,
        icon: _selectedIcon,
        color: _selectedColor,
      );
    } else {
      // 추가 모드
      context.read<DailyCategoryViewModel>().addCategory(
        n,
        _selectedIcon,
        _selectedColor,
      );
    }
    Navigator.pop(context); // 관리 페이지로 복귀 → Provider로 즉시 갱신됨
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _name.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarTitleSubtitle(
              title: widget.editItem != null ? '카테고리 수정' : '카테고리 추가',
              subtitle: '아이콘과 색상을 선택하세요',
              onBack: () => Navigator.pop(context),
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

            // ✅ 하단 버튼(RecordSpendingPage와 동일한 배치)
            CustomButton(text: '저장', enabled: isValid, onPressed: _save),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}
