import 'package:flutter/material.dart';

/// 회색 원 안에 도움말 아이콘 + 짧은 캡션 텍스트.
/// 기존 `_CaptionWithDot`과 동일하게 동작하지만 어디서든 재사용 가능.
class CaptionWithDot extends StatelessWidget {
  final String text;

  /// 필요 시 스타일/아이콘 커스터마이즈를 위한 선택 파라미터
  final double dotSize;
  final Color dotColor;
  final IconData icon;
  final double iconSize;
  final TextStyle? textStyle;
  final double spacing;

  const CaptionWithDot({
    super.key,
    required this.text,
    this.dotSize = 16,
    this.dotColor = const Color(0xFFDADADA),
    this.icon = Icons.help_outline,
    this.iconSize = 12,
    this.textStyle = const TextStyle(
      fontFamily: 'Pretendard Variable',
      fontSize: 13,
      color: Color(0xFF9E9E9E),
    ),
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            text,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
