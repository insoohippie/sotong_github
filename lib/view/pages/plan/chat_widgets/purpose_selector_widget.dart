import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

class PurposeSelectorWidget extends StatelessWidget {
  final List<String> options;
  final Function(String) onSelect;

  const PurposeSelectorWidget({
    Key? key,
    required this.options,
    required this.onSelect,
  }) : super(key: key);

  static const Map<String, String> _emojiMap = {
    '여행자금': '✈️',
    '자취 준비': '🏠',
    '부모님 선물': '🎁',
    '결혼 준비': '💒',
    '학자금': '🎓',
    '이직준비': '💼',
    '긴급자금': '🚨',
    '기타': '💡',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final purpose = options[index];
          final emoji = _emojiMap[purpose] ?? '💡';

          return GestureDetector(
            onTap: () => onSelect(purpose),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // ✅ 은은한 그림자
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: Text(
                    purpose,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
