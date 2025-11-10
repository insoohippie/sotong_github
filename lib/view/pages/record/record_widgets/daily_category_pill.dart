import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/record/daily_category_viewmodel.dart';
import 'daily_category_manage_file.dart';

/// 오늘의 소비 입력에서만 쓰는 Large Pill (height=60, radius=12, ParagraphText)
class DailyCategoryPill extends StatelessWidget {
  final String text;          // 현재 선택된 카테고리명
  final VoidCallback onTap;   // 시트 열기 등
  final VoidCallback onClear; // 롱프레스 초기화

  const DailyCategoryPill({
    Key? key,
    required this.text,
    required this.onTap,
    required this.onClear,
  }) : super(key: key);

  static const double kHeight = 60;
  static const double kRadius = 12;

  @override
  Widget build(BuildContext context) {
    final hasValue = text.trim().isNotEmpty;
    final vm = context.watch<DailyCategoryViewModel>();
    final matched = vm.findByName(text.trim());

    return InkWell(
      onTap: onTap,
      onLongPress: onClear,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        height: kHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.lightBlue : AppColors.greyBackground, // ✅ 라이트블루 유지
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            // 왼쪽 아이콘: 항상 검정
            if (hasValue && matched != null)
              Icon(matched.icon, size: 20, color: Colors.black) // ✅ 검정 아이콘
            else
              Icon(
                hasValue ? Icons.push_pin_rounded : Icons.add_circle_outline_rounded,
                size: 20,
                color: hasValue ? AppColors.primary : AppColors.subText,
              ),

            const SizedBox(width: 8),

            // 텍스트
            Expanded(
              child: ParagraphText(
                text: hasValue ? text : '입력',
                color: hasValue ? Colors.black : AppColors.subText,
              ),
            ),

            // ✅ 오른쪽: 작은 색상 동그라미 (사용자 색)
            if (hasValue && matched != null)
              Container(
                width: 10, // 🔹 작게
                height: 10,
                decoration: BoxDecoration(
                  color: matched.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1), // 살짝 테두리
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 오늘의 소비 입력 전용 카테고리 시트 (뷰모델 기반)
Future<void> openDailyCategorySheet(
    BuildContext context,
    TextEditingController controller,
    void Function(String) onSelected,
    ) async {
  String temp = controller.text;
  String _norm(String s) => s.trim();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      TextEditingController? tempController;

      return StatefulBuilder(
        builder: (context, setModalState) {
          final vm = context.watch<DailyCategoryViewModel>();
          final enabled = vm.enabledItems;

          tempController ??= TextEditingController(text: temp);
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;

          final bool isValid = _norm(temp).isNotEmpty;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),

                // 제목 + 관리 버튼
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        await Navigator.of(ctx).push(
                          MaterialPageRoute(builder: (_) => const DailyCategoryManagePage()),
                        );
                        // 복귀 후 선택값 유효성 점검
                        final stillExists = context
                            .read<DailyCategoryViewModel>()
                            .enabledItems
                            .any((e) => e.name.trim() == temp.trim());
                        if (!stillExists) {
                          setModalState(() {
                            temp = '';
                            tempController!.text = '';
                          });
                        }
                      },
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('카테고리 관리'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 프리셋 칩(아이콘 + 이름 + 색상 동그라미)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: enabled.map((p) {
                      final selected = p.name.trim() == temp.trim();
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ 색상 동그라미 + 검은 아이콘
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: p.color,
                              child: Icon(p.icon, size: 14, color: Colors.black),
                            ),
                            const SizedBox(width: 6),
                            Text(p.name),
                            // ⛔ 우측 작은 색상 점 제거
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            temp = p.name;
                            tempController!.text = temp;
                            tempController!.selection = TextSelection.collapsed(offset: temp.length);
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF3F4F6),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // 직접 입력 + 확인 (빈 값이면 비활성화)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: CustomTextField(
                          controller: tempController!,
                          hintText: '다른 카테고리 입력',
                          onChanged: (v) => setModalState(() => temp = v),
                          height: 60,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () {
                          final result = _norm(temp);
                          controller.text = result;
                          onSelected(result);
                          Navigator.pop(ctx);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(80, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      );
    },
  );
}
