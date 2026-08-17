import 'package:hive_flutter/hive_flutter.dart';

/// "새 플랜 작성 중" 플래그 저장소.
///
/// 완료된 플랜에서 새 플랜 만들기를 시작한 뒤, 새 플랜이 저장되기 전에
/// 앱을 종료·재시작해도 이전(완료) 플랜의 잠긴 홈으로 떨어지지 않고
/// 플랜 챗으로 복귀하도록 스플래시 라우팅에서 참조한다.
/// 새 플랜 저장 성공 시 해제된다.
class PlanTransitionStorage {
  PlanTransitionStorage._();

  static final PlanTransitionStorage instance = PlanTransitionStorage._();

  static const String _boxName = 'auth_cache';
  static const String _keyPrefix = 'newPlanInProgress';

  Box get _box => Hive.box(_boxName);

  String _key(String uid) => '$_keyPrefix:$uid';

  bool isInProgress({required String uid}) {
    return _box.get(_key(uid), defaultValue: false) as bool;
  }

  Future<void> markInProgress({required String uid}) async {
    await _box.put(_key(uid), true);
  }

  Future<void> clear({required String uid}) async {
    await _box.delete(_key(uid));
  }
}
