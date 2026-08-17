import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repository/auth_repository.dart';
import '../../../services/plan_transition_service.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';

/// 완료된 플랜에서 "새로운 플랜 만들기"로 진입하는 공통 흐름.
/// (celebration의 '나의 기록' 페이지, 설정 메뉴 두 곳에서 사용)
///
/// 1. PlanTransitionService: 이전 refData 비활성화 + 캐시 정리 + 전환 중 플래그
/// 2. ChatPlanViewModel: 비활성 refData를 품은 채 새 세션 시작
/// 3. 스택을 비우고 플랜 챗으로 이동
///
/// 실패 시 스낵바로 알리고 이동하지 않는다.
Future<void> startNewPlanFlow(BuildContext context) async {
  final authRepo = context.read<AuthRepository>();
  final uid = authRepo.cachedUid ?? authRepo.currentUserId;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인 정보를 확인할 수 없어요.')),
    );
    return;
  }

  final transition = context.read<PlanTransitionService>();
  final chatVM = context.read<ChatPlanViewModel>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  try {
    final carryOver = await transition.prepareNewPlan(uid: uid);
    chatVM.startNewPlanSession(carryOverRefData: carryOver);
  } catch (e) {
    debugPrint('[startNewPlanFlow] failed: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('새 플랜 준비 중 문제가 발생했어요. 다시 시도해주세요.')),
    );
    return;
  }

  navigator.pushNamedAndRemoveUntil('/plan_chat', (_) => false);
}
