// lib/repository/record_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data_source/record_data_source.dart';
import '../data_source/auth_data_source.dart';
import '../model/record/day_spending.dart';
import '../model/record/monthly_spending.dart';

class RecordRepository {
  final RecordDataSource _dataSource;
  final AuthDataSource _authDataSource;

  final Box _cacheBox = Hive.box('monthly_spending');

  RecordRepository(this._dataSource, this._authDataSource);

  String? get _uid => _authDataSource.currentUser?.uid;

  /// TODO: 나중에 connectivity_plus 로 실제 네트워크 상태 반영
  bool isOnline = true;

  // ============== 내부: 키/캐시/dirty 헬퍼 ==============

  String _monthKey(String monthKey) {
    final uid = _uid;
    if (uid == null) return 'NO_UID:$monthKey'; // (실제 사용은 uid null이면 바로 return)
    return '$uid:$monthKey';
  }

  /// dirty 플래그 key
  String _dirtyKey(String monthKey) => '${_monthKey(monthKey)}:dirty';

  MonthlySpending? _loadFromCache(String monthKey) {
    final uid = _uid;
    if (uid == null) return null;

    final key = _monthKey(monthKey);
    if (!_cacheBox.containsKey(key)) return null;

    final rawStr = _cacheBox.get(key);
    if (rawStr is! String) return null;

    try {
      final map = jsonDecode(rawStr) as Map<String, dynamic>;
      return MonthlySpending.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _saveToCache(String monthKey, MonthlySpending month) {
    final uid = _uid;
    if (uid == null) return;
    final key = _monthKey(monthKey);
    _cacheBox.put(key, jsonEncode(month.toJson()));
  }

  bool _isDirty(String monthKey) {
    final uid = _uid;
    if (uid == null) return false;
    final v = _cacheBox.get(_dirtyKey(monthKey));
    return v is bool ? v : false;
  }

  void _setDirty(String monthKey, bool value) {
    final uid = _uid;
    if (uid == null) return;
    _cacheBox.put(_dirtyKey(monthKey), value);
  }

  bool _isSame(MonthlySpending a, MonthlySpending b) {
    // NOTE: map iteration order가 모델 내부에서 안정적이라는 전제(현재 구조면 보통 OK)
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }

  // ============== 내부: Firestore safe wrappers ==============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _safeGetRemoteMonth(
      String uid,
      String monthKey,
      ) async {
    try {
      return await _dataSource.getMonthlyDoc(uid, monthKey);
    } catch (_) {
      return null;
    }
  }

  /// ✅ 성공/실패를 리턴한다 (정책: 실패면 dirty 유지)
  Future<bool> _safeSetRemote(
      String uid,
      String monthKey,
      MonthlySpending month,
      ) async {
    try {
      final data = month.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
      await _dataSource.setMonthlyDoc(uid, monthKey, data, merge: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============== Public: 월 단위 로드/저장 ==============

  /// 날짜 → 'yyyy-MM' 문자열로 변환
  String _toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  /// ✅ 오프라인 퍼스트 월 로딩 (정책 100% 준수 버전)
  ///
  /// - uid 없으면: 기본값만 반환 (Hive/Firestore 접근 금지)
  /// - 캐시 있으면: 캐시 즉시 반환(오프라인이면 끝)
  /// - 온라인이면: dirty 기반 sync
  ///   - dirty=true  => 로컬 우선 (업로드 성공 시에만 dirty=false)
  ///   - dirty=false => 서버 우선
  /// - 서버 read 실패해도 앱이 터지지 않도록 안전 처리 (캐시/초기값 반환)
  Future<MonthlySpending> loadMonthlySpending(String monthKey) async {
    final uid = _uid;

    // A. uid 없으면: 기본값만 (캐시/서버 금지)
    if (uid == null) {
      return MonthlySpending.empty(monthKey);
    }

    final cache = _loadFromCache(monthKey);
    final dirty = _isDirty(monthKey);

    // 1) 캐시가 있으면 캐시 우선 반환
    if (cache != null) {
      if (!isOnline) return cache;

      final snap = await _safeGetRemoteMonth(uid, monthKey);

      // ✅ 서버 read 실패면: 캐시 그대로 반환
      if (snap == null) return cache;

      // 서버 문서 없음
      if (!snap.exists) {
        final ok = await _safeSetRemote(uid, monthKey, cache);

        if (dirty) {
          // ✅ dirty=true인 경우만 "성공 시" 해제
          if (ok) _setDirty(monthKey, false);
          // 실패면 dirty 유지
        } else {
          // dirty=false면 굳이 dirty 만질 필요 없음 (이미 false)
        }
        return cache;
      }

      // 서버 문서 있음
      final data = snap.data() as Map<String, dynamic>;
      final remote = MonthlySpending.fromFirestore(monthKey, data);

      if (dirty) {
        // dirty=true => 로컬 우선
        if (!_isSame(cache, remote)) {
          final ok = await _safeSetRemote(uid, monthKey, cache);
          if (ok) _setDirty(monthKey, false); // ✅ 성공 시에만 해제
          // 실패면 dirty 유지
        } else {
          // remote == cache: 이미 일치 -> dirty 해제 가능
          _setDirty(monthKey, false);
        }
        return cache;
      } else {
        // dirty=false => 서버 우선
        if (!_isSame(cache, remote)) {
          _saveToCache(monthKey, remote);
          _setDirty(monthKey, false);
          return remote;
        }
        return cache;
      }
    }

    // 2) 캐시가 없으면
    if (isOnline) {
      final snap = await _safeGetRemoteMonth(uid, monthKey);

      // ✅ 서버 read 실패면: 로컬에 empty 생성 + dirty=true (나중 업로드 대상)
      if (snap == null) {
        final fallback = MonthlySpending.empty(monthKey);
        _saveToCache(monthKey, fallback);
        _setDirty(monthKey, true);
        return fallback;
      }

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final remote = MonthlySpending.fromFirestore(monthKey, data);
        _saveToCache(monthKey, remote);
        _setDirty(monthKey, false);
        return remote;
      }

      // 서버에도 없으면 initial 생성해서 캐시 저장 + 서버 저장
      final initial = MonthlySpending.empty(monthKey);
      _saveToCache(monthKey, initial);
      _setDirty(monthKey, false);

      final ok = await _safeSetRemote(uid, monthKey, initial);
      if (!ok) {
        // ✅ 서버 저장 실패면 dirty=true로 남겨서 재시도 대상
        _setDirty(monthKey, true);
      }

      return initial;
    }

    // 오프라인 + 캐시 없음
    final offlineInitial = MonthlySpending.empty(monthKey);
    _saveToCache(monthKey, offlineInitial);
    _setDirty(monthKey, true);
    return offlineInitial;
  }

  /// DateTime으로 월 요청하고 싶을 때
  Future<MonthlySpending> loadMonthlySpendingByDate(DateTime date) {
    return loadMonthlySpending(_toMonthKey(date));
  }

  /// ✅ 월 전체 저장 (정책 100% 준수)
  ///
  /// 1) Hive 저장
  /// 2) markDirty면 dirty=true
  /// 3) 온라인이면 Firestore 업로드 시도
  /// 4) 업로드 성공 시 dirty=false / 실패 시 dirty=true 유지
  Future<void> saveMonthlySpending(
      MonthlySpending month, {
        bool markDirty = true,
      }) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = month.monthKey;

    _saveToCache(monthKey, month);
    if (markDirty) _setDirty(monthKey, true);

    if (isOnline) {
      final ok = await _safeSetRemote(uid, monthKey, month);
      if (ok) {
        _setDirty(monthKey, false);
      } else {
        // ✅ 실패면 dirty 유지 (정책)
        _setDirty(monthKey, true);
      }
    }
  }

  /// ✅ DaySpending 한 날짜를 월 구조에 upsert
  ///
  /// - 월 단위로 loadMonthlySpending() 호출 (offline-first + sync)
  /// - days[dateKey]만 교체
  /// - saveMonthlySpending() 로 다시 저장 (dirty/업로드 처리)
  Future<void> upsertDaySpending(DaySpending day) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = _toMonthKey(day.date);
    final dateKey = DateFormat('yyyy-MM-dd').format(day.date);

    final monthly = await loadMonthlySpending(monthKey);

    final newDays = Map<String, DaySpending>.from(monthly.days);
    newDays[dateKey] = day;

    final updatedMonthly = monthly.copyWith(days: newDays);

    await saveMonthlySpending(updatedMonthly);
  }

  // ============== 디버그/관리용 ==============

  /// 현재 유저의 월 캐시만 전부 삭제하고 싶을 때
  Future<void> resetAllCacheForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return;

    final prefix = '$uid:';
    final keysToDelete = _cacheBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);

    for (final k in keysToDelete) {
      await _cacheBox.delete(k);
    }
  }

  Future<void> deleteAllMonthlyOnServer() async {
    final uid = _uid;
    if (uid == null) return;

    final snap = await _dataSource.listMonthlyDocs(uid);
    if (snap.docs.isEmpty) return;

    final db = FirebaseFirestore.instance;
    var batch = db.batch();
    var count = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;

      // 배치 500 제한 대비(안전)
      if (count == 450) {
        await batch.commit();
        batch = db.batch();
        count = 0;
      }
    }

    await batch.commit();
  }
}