// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  static const header = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 26,
    color: Colors.black,
    fontWeight: FontWeight.w800,
  );

  static const paragraph = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w500,
  );

  static const subtext = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    color: Color(0xFF9A9A9A),
    fontWeight: FontWeight.w400,
  );

  static const infoText = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF4EA4FF), // 연한 하늘색
  );

  static const errorText = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.red,
  );
}


