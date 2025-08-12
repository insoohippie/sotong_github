import 'package:flutter/material.dart';

class AppBorderRadius {
  // 모든 모서리 둥글기를 중앙에서 관리
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
  static const double modalRadius = 16.0;

  // 카드용 BorderRadius
  static BorderRadius get card => BorderRadius.circular(cardRadius);

  // 버튼용 BorderRadius
  static BorderRadius get button => BorderRadius.circular(buttonRadius);

  // 입력 필드용 BorderRadius
  static BorderRadius get input => BorderRadius.circular(inputRadius);

  // 모달용 BorderRadius (상단만 둥글게)
  static BorderRadius get modalTop => const BorderRadius.only(
    topLeft: Radius.circular(modalRadius),
    topRight: Radius.circular(modalRadius),
  );
}
