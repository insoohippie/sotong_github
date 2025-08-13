// repository/plan_repository.dart
import '../data_source/plan_data_source.dart';
import '../data_source/auth_data_source.dart';
import '../model/plan_info.dart';

class PlanRepository {
  final PlanDataSource _planDs;
  final AuthDataSource _authDs;

  PlanRepository(this._planDs, this._authDs);

  /// 현재 로그인 유저의 uid 기준으로 저장
  Future<String> saveCurrentUserPlan(PlanInfo plan) async {
    final uid = _authDs.currentUser?.uid;
    if (uid == null) {
      throw Exception('로그인이 필요합니다.');
    }
    return _planDs.savePlan(uid, plan);
  }
}