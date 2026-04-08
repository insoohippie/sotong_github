import 'package:flutter/material.dart';

/// 수입/소비 기록 플로우 종료 후 홈 대신 [PendingSpendingDaysPage]로 돌아갈지 결정합니다.
///
/// [rootNavigator]로 푸시해 중첩 [Navigator] 아래에서도 메인 셸(탭 홈)로 확실히 이동합니다.
void finishRecordFlowToHomeOrPending(
    BuildContext context, {
      required bool returnToPending,
    }) {
  final nav = Navigator.of(context, rootNavigator: true);

  if (!returnToPending) {
    nav.pushNamedAndRemoveUntil(
      '/home_tab_navigator',
          (route) => false,
    );
    return;
  }

  nav.popUntil(
        (route) => route.settings.name == '/pending_spending_days',
  );

  final name = ModalRoute.of(context)?.settings.name;
  if (name != '/pending_spending_days') {
    nav.pushNamedAndRemoveUntil(
      '/pending_spending_days',
          (route) => false,
    );
  }
}
