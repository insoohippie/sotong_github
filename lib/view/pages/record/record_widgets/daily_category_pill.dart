import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/texts/paragraph_text.dart';

/// 오늘의 소비 입력에서만 쓰는 Large Pill (height=60, radius=12, ParagraphText)
class DailyCategoryPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onClear;

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

    final CatPreset matched = dailyPresets.firstWhere(
          (p) => p.name == text.trim(),
      orElse: () => const CatPreset('', Icons.add_circle_outline_rounded),
    );

    final bool isPreset = matched.name.isNotEmpty;
    final IconData iconData = hasValue
        ? (isPreset ? matched.icon : Icons.push_pin_rounded)
        : Icons.add_circle_outline_rounded;

    final double iconSize = 18;

    return InkWell(
      onTap: onTap,
      onLongPress: onClear,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        height: kHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.lightBlue : AppColors.greyBackground,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            Icon(
              iconData,
              size: iconSize,
              color: hasValue ? AppColors.primary : AppColors.subText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ParagraphText(
                text: hasValue ? text : '입력',
                color: hasValue ? Colors.black : AppColors.subText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 오늘의 소비 프리셋
class CatPreset {
  final String name;
  final IconData icon;
  const CatPreset(this.name, this.icon);
}

final List<CatPreset> dailyPresets = const [
  CatPreset('식비', Icons.restaurant_rounded),
  CatPreset('교통비', Icons.train_rounded),
  CatPreset('카페', Icons.local_cafe_rounded),
  CatPreset('취미', Icons.sports_esports_rounded),
  CatPreset('식비', Icons.restaurant_rounded),
  CatPreset('교통비', Icons.train_rounded),
  CatPreset('카페', Icons.local_cafe_rounded),
  CatPreset('취미', Icons.sports_esports_rounded),
  CatPreset('식비', Icons.restaurant_rounded),
  CatPreset('교통비', Icons.train_rounded),
  CatPreset('카페', Icons.local_cafe_rounded),
];

/// 오늘의 소비 입력 전용 카테고리 시트
Future<void> openDailyCategorySheet(
    BuildContext context,
    TextEditingController controller,
    void Function(String) onSelected,
    ) async {
  String temp = controller.text;

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
          tempController ??= TextEditingController(text: temp);
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 바
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

                // 프리셋 칩
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dailyPresets.map((p) {
                      final selected = temp == p.name;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.icon,
                              size: 16,
                              color: selected ? Colors.white : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(p.name),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            temp = p.name;
                            tempController!.text = temp;
                            tempController!.selection =
                                TextSelection.collapsed(offset: temp.length);
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

                // 입력 + 확인 (한 줄)
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
                        onPressed: () {
                          final result = temp.trim();
                          controller.text = result;
                          onSelected(result);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(80, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
