import 'package:flutter/material.dart';

import '../../repository/auth_repository.dart';
import '../../repository/category_repository.dart';
import '../../repository/record_repository.dart';

class SettingViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final CategoryRepository _categoryRepository;
  final RecordRepository _recordRepository;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  bool isOnline = true;

  SettingViewModel(
      this._authRepository,
      this._categoryRepository,
      this._recordRepository,
      );

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  /// 로그아웃
  Future<void> logout() async {
    await _authRepository.logout();
  }

  /// 데이터 지우기: 서버 + 로컬(현재 uid 것만)
  Future<void> deleteAllMyData() async {
    // 1) 서버 데이터 삭제 (온라인 필요)
    await _categoryRepository.deleteMyCategoryOnServer();
    await _recordRepository.deleteAllMonthlyOnServer();

    // 2) 로컬 캐시 삭제 (현재 uid prefix만)
    await _categoryRepository.clearMyCategoryCache();
    await _recordRepository.resetAllCacheForCurrentUser();

    // 3) 로그아웃
    await _authRepository.logout();
  }

}
