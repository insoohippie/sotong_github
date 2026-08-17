import 'package:flutter/foundation.dart';

import '../model/refData/ref_data.dart';
import '../repository/plan_cache_repository.dart';
import '../repository/ref_data_repository.dart';
import 'plan_transition_storage.dart';

/// 완료된 플랜에서 새 플랜으로 전환하기 전, 이전 플랜 데이터를 정리·보존한다.
///
/// 순서(각 단계는 앞 단계 성공을 전제):
///   1. 이전 플랜 refData 전체를 비활성화하여 저장 (삭제하지 않음)
///   2. plan_cache 스냅샷 삭제 (이전 플랜이 캐시에서 되살아나지 않도록)
///   3. "새 플랜 작성 중" 플래그 기록 (저장 전 이탈 방어)
///
/// 반환값: 비활성화된 이전 refData. 호출자는 이를 ChatPlanViewModel.resetSession에
/// 넘겨, 새 플랜의 ID 발급기(_nextSequentialId)가 이전 ID를 인지해 충돌을 피하게 한다.
/// (비활성 레코드는 primary 값 계산·겹침 검사에서 자동 제외되므로 새 플랜 계산에 영향 없음)
///
/// 완료 스냅샷(PastPlanSnapshot)은 목표 달성 감지 시점에 이미 저장되므로
/// 여기서는 다루지 않는다.
class PlanTransitionService {
  PlanTransitionService({
    required RefDataRepository refDataRepo,
    required PlanCacheRepository planCacheRepo,
  })  : _refDataRepo = refDataRepo,
        _planCacheRepo = planCacheRepo;

  final RefDataRepository _refDataRepo;
  final PlanCacheRepository _planCacheRepo;

  Future<RefData> prepareNewPlan({required String uid}) async {
    // 1) 이전 refData 로드 → 전부 비활성화 → 저장
    final previous = await _refDataRepo.loadAll();
    final now = DateTime.now();

    for (final entry in previous.monthlyIncomeMap.entries.toList()) {
      if (!entry.value.isActive) continue;
      final deactivated = entry.value.deactivate();
      previous.monthlyIncomeMap[entry.key] = deactivated;
      await _refDataRepo.saveMonthlyIncome(deactivated);
    }
    for (final entry in previous.monthlyConsumeMap.entries.toList()) {
      if (!entry.value.isActive) continue;
      final deactivated = entry.value.deactivate();
      previous.monthlyConsumeMap[entry.key] = deactivated;
      await _refDataRepo.saveMonthlyConsume(deactivated);
    }
    for (final entry in previous.dailyConsumeMap.entries.toList()) {
      if (!entry.value.isActive) continue;
      final deactivated = entry.value.softDelete(now);
      previous.dailyConsumeMap[entry.key] = deactivated;
      await _refDataRepo.saveDailyConsume(deactivated);
    }
    debugPrint(
      '[PlanTransition] deactivated refData '
      'mi=${previous.monthlyIncomeMap.length} '
      'mc=${previous.monthlyConsumeMap.length} '
      'dc=${previous.dailyConsumeMap.length}',
    );

    // 2) 이전 플랜 캐시 제거
    await _planCacheRepo.clearSnapshot(uid);

    // 3) 전환 중 플래그
    await PlanTransitionStorage.instance.markInProgress(uid: uid);

    // 새 플랜용 RefData: planId 없음, 비활성 레코드만 carry-over
    return RefData(
      planId: '',
      monthlyIncomes: previous.monthlyIncomeMap,
      monthlyConsumes: previous.monthlyConsumeMap,
      dailyConsumes: previous.dailyConsumeMap,
    );
  }
}
