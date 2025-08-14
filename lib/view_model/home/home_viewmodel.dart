import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;

  HomeViewModel(this._authRepo, this._planRepo);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // 프로필
  String? _uid;
  String _name = '회원';
  String? _email;
  String? _birthday;
  String? _gender;

  String? get uid => _uid;
  String get name => _name;
  String? get email => _email;
  String? get birthday => _birthday;
  String? get gender => _gender;

  // 예: 최근 플랜 요약 같은 것도 필요하면 여기에 필드 추가
  // PlanInfo? _latestPlan;  // 필요시

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // try {
    //   // 1) 현재 로그인 사용자
    //   final currUid = await _authRepo.getCurrentUserId();
    //   if (currUid == null) throw Exception('로그인 정보가 없습니다.');
    //   _uid = currUid;
    //
    //   // 2) users/{uid} 문서
    //   final doc = await _authRepo.getUserDoc(currUid);
    //   final data = doc.data();
    //   if (data == null) throw Exception('사용자 문서를 찾을 수 없습니다.');
    //
    //   _name = (data['name'] as String?)?.trim().isNotEmpty == true
    //       ? (data['name'] as String).trim()
    //       : '회원';
    //   _email = data['id'] as String?;       // 스키마 상 이메일 필드가 'id'였음
    //   _birthday = data['birthday'] as String?;
    //   _gender = data['gender'] as String?;
    //
    //   // 3) (옵션) 플랜 관련 데이터 가져오기
    //   // 예: 최신 플랜 불러오기 등
    //   // _latestPlan = await _planRepo.getLatestPlanForUser(currUid);
    //
    // } catch (e) {
    //   _error = e.toString().replaceFirst('Exception: ', '');
    // } finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
  }

  Future<void> refresh() => load();
}
