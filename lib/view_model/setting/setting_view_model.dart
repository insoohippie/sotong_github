import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../repository/auth_repository.dart';
import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/plan_cache_repository.dart';
import '../../repository/ref_category_repository.dart';
import '../../repository/account_delete_repository.dart';
import '../../services/app_session_reset_service.dart';
import '../../services/plan_debug_printer.dart';

const String _kDarkModeKey = 'isDarkMode';

class SettingViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final RecordRepository _recordRepository;
  final PlanRepository _planRepository;
  final RefDataRepository _refDataRepository;
  final PlanCacheRepository _planCacheRepository;
  final RefCategoryRepository _refCategoryRepository;
  final AccountDeleteRepository _accountDeleteRepository;
  final AppSessionResetService _sessionResetService;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  bool isOnline = true;

  SettingViewModel(
      this._authRepository,
      this._recordRepository,
      this._planRepository,
      this._refDataRepository,
      this._planCacheRepository,
      this._refCategoryRepository,
      this._accountDeleteRepository,
      this._sessionResetService,
      ) {
    _loadDarkMode();
  }

  void _loadDarkMode() {
    try {
      _isDarkMode =
      Hive.box('settings').get(_kDarkModeKey, defaultValue: false) as bool;
    } catch (_) {
      _isDarkMode = false;
    }
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    try {
      Hive.box('settings').put(_kDarkModeKey, value);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logout() async {
    // 1. Provider 메모리 상태 초기화
    _sessionResetService.resetAll();

    // 2. Firebase Auth 로그아웃
    //
    // 주의:
    // 로그아웃에서는 monthly_spending, refData, plan_cache,
    // notification_cache 같은 사용자 로컬 데이터는 지우면 안 됨.
    // 계정별 key(uid prefix)로 분리되어 있으므로 보존해도 계정 간 데이터가 섞이지 않음.
    await _authRepository.logout();
  }

  Future<void> deleteAccountCompletely(String password) async {
    if (!isOnline) {
      throw Exception('계정 삭제는 인터넷 연결이 필요합니다.');
    }

    if (password.trim().isEmpty) {
      throw Exception('비밀번호를 입력해 주세요.');
    }

    // 1. 비밀번호 재인증
    await _authRepository.verifyCurrentPassword(password.trim());

    // 2. Provider 메모리 상태 초기화
    _sessionResetService.resetAll();

    // 3. Firestore 사용자 데이터 삭제
    // 4. Hive 사용자 데이터 삭제
    // 5. Firebase Auth 계정 삭제
    await _accountDeleteRepository.deleteAccountCompletely();
  }

  Future<void> uploadAllData() async {
    final uid = _authRepository.cachedUid ?? _authRepository.currentUserId;
    if (uid == null) {
      debugPrint('[SettingViewModel] upload aborted: missing uid');
      return;
    }
    if (!isOnline) {
      debugPrint('[SettingViewModel] upload aborted: offline');
      throw Exception('데이터 연결을 확인해 주세요');
    }

    _recordRepository.localMode = false;
    try {
      await _syncPlan(uid);
      await _syncRecords(uid);
      await _syncCategories(uid);
    } finally {
      _recordRepository.localMode = true;
    }
  }

  Future<void> _syncPlan(String uid) async {
    final snapshot = _planCacheRepository.loadSnapshot(uid);
    if (snapshot == null) {
      debugPrint('[SettingViewModel] no cached plan for upload');
      return;
    }

    final tree = PlanDebugPrinter.describe(
      plan: snapshot.plan,
      refData: snapshot.refData,
    );
    debugPrint('--- Plan Tree Upload ---\n$tree');

    await _planRepository.replacePlan(snapshot.plan);
  }

  Future<void> _syncRecords(String uid) async {
    debugPrint('[SettingViewModel] syncing dirty record months...');
    await _recordRepository.syncDirtyMonths();
  }

  Future<void> _syncCategories(String uid) async {
    debugPrint('[SettingViewModel] syncing ref categories...');
    await _refCategoryRepository.syncToRemote();

    debugPrint('[SettingViewModel] syncing ref data...');
    await _refDataRepository.syncToRemote();
  }
}