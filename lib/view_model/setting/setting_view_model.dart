import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../repository/auth_repository.dart';
import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/plan_cache_repository.dart';
import '../../repository/ref_category_repository.dart';
import '../../services/plan_debug_printer.dart';

const String _kDarkModeKey = 'isDarkMode';

class SettingViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final RecordRepository _recordRepository;
  final PlanRepository _planRepository;
  final RefDataRepository _refDataRepository;
  final PlanCacheRepository _planCacheRepository;
  final RefCategoryRepository _refCategoryRepository;

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

  /// 로그아웃
  Future<void> logout() async {
    await _authRepository.logout();
  }

  /// 데이터 지우기: 서버 + 로컬(현재 uid 것만)
  Future<void> deleteAllMyData() async {
    // 1) 서버 데이터 삭제 (온라인 필요)
    await _recordRepository.deleteAllMonthlyOnServer();

    // 2) 로컬 캐시 삭제 (현재 uid prefix만)
    await _recordRepository.resetAllCacheForCurrentUser();

    // 3) 로그아웃
    await _authRepository.logout();
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
    final tree = PlanDebugPrinter.describe(plan: snapshot.plan, refData: snapshot.refData);
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
