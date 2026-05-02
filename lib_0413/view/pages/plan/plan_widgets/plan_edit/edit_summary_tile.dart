import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../component/theme/app_colors.dart';

class EditSummaryTile extends StatelessWidget {
  final String label;
  final double total;
  final VoidCallback onEdit;
  final String? unit; // 기본 '원'
  final String? subtitle; // 선택 설명 텍스트
  final bool showDivider;

  /// null이면 회색(greyBackground)
  final Color? backgroundColor;

  /// null이면 subText(회색), 저축 가능 시 파랑(primary), 저축 불가 시 빨강(redText) 전달
  final Color? labelColor;

  const EditSummaryTile({
    Key? key,
    required this.label,
    required this.total,
    required this.onEdit,
    this.unit,
    this.subtitle,
    this.showDivider = true,
    this.backgroundColor,
    this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBg =
        backgroundColor ??
            (isDark ? theme.colorScheme.surface : AppColors.greyBackground);
    final formattedTotal = NumberFormat('#,###').format(total.toInt());

    return Padding(
      // MinimalField와 동일: 위아래 6px 패딩
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard Variable',
              color: labelColor ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // ✅ 컨테이너 전체 탭 → onEdit 실행
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onEdit,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$formattedTotal${unit ?? '원'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          if (showDivider) Divider(height: 5, color: theme.dividerColor),
        ],
      ),
    );
  }
}
