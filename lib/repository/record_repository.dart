// lib/repository/record_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    if (uid == null) {
      return 'NO_UID:$monthKey';
    }
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
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }

  // ============== Public: 월 단위 로드/저장 ==============

  // 날짜 → 'yyyy-MM' 문자열로 변환
  String _toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  /// 오프라인 퍼스트 월 로딩
  ///
  /// 1) 캐시가 있으면:
  ///    - 오프라인 또는 uid 없음 → 캐시 그대로 사용
  ///    - 온라인:
  ///        - Firestore 문서 가져와서:
  ///          - 서버 없음:
  ///              - 캐시 dirty면 → 캐시를 서버에 업로드
  ///              - 아니면 → 캐시 기준 그대로 사용(필요시 업로드)
  ///          - 서버 있음:
  ///              - 캐시 dirty:
  ///                  - remote != cache → 로컬 우선(캐시 → 서버 덮어쓰기)
  ///                  - remote == cache → dirty 해제
  ///              - 캐시 not dirty:
  ///                  - remote != cache → 서버 우선(remote → 캐시 덮어쓰기)
  ///                  - remote == cache → 그대로
  ///
  /// 2) 캐시가 없으면:
  ///    - 온라인:
  ///        - 서버에 있으면 remote → 캐시
  ///        - 없으면 MonthlySpending.empty() 생성해서 서버/캐시에 저장
  ///    - 오프라인:
  ///        - empty 생성해서 캐시만, dirty=true
  Future<MonthlySpending> loadMonthlySpending(String monthKey) async {
    final uid = _uid;

    if (uid == null) {
      return MonthlySpending.empty(monthKey);
    }

    final cache = _loadFromCache(monthKey);
    final dirty = _isDirty(monthKey);

    if (cache != null) {
      if (!isOnline) return cache;

      final snap = await _dataSource.getMonthlyDoc(uid, monthKey);
      if (!snap.exists) {
        if (dirty) {
          await _safeSetRemote(uid, monthKey, cache);
          _setDirty(monthKey, false);
        } else {
          await _safeSetRemote(uid, monthKey, cache);
        }
        return cache;
      }

      final data = snap.data() as Map<String, dynamic>;
      final remote = MonthlySpending.fromFirestore(monthKey, data);

      if (dirty) {
        if (!_isSame(cache, remote)) {
          await _safeSetRemote(uid, monthKey, cache);
        }
        _setDirty(monthKey, false);
        return cache;
      } else {
        if (!_isSame(cache, remote)) {
          _saveToCache(monthKey, remote);
          _setDirty(monthKey, false);
          return remote;
        }
        return cache;
      }
    }

    if (isOnline) {
      final snap = await _dataSource.getMonthlyDoc(uid, monthKey);
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final remote = MonthlySpending.fromFirestore(monthKey, data);
        _saveToCache(monthKey, remote);
        _setDirty(monthKey, false);
        return remote;
      }

      final initial = MonthlySpending.empty(monthKey);
      _saveToCache(monthKey, initial);
      _setDirty(monthKey, false);
      await _safeSetRemote(uid, monthKey, initial);
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

  /// 월 전체 저장 (타입 안전 버전)
  ///
  /// - 항상 Hive에 저장
  /// - 기본적으로 dirty = true (이 기기에서 수정됨)
  /// - 온라인이면 Firestore에도 업로드 후 dirty=false
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
      await _safeSetRemote(uid, monthKey, month);
      _setDirty(monthKey, false);
    }
  }

  /// DaySpending 한 날짜를 월 구조에 upsert
  ///
  /// - 월 단위로 loadMonthlySpending() 호출
  /// - days[dateKey]만 교체
  /// - saveMonthlySpending() 로 다시 저장
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

  // ============== 내부: Firestore 세이브 래퍼 ==============

  Future<void> _safeSetRemote(String uid, String monthKey, MonthlySpending month) async {
    try {
      final data = month.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
      await _dataSource.setMonthlyDoc(uid, monthKey, data, merge: false);
    } catch (_) {}
  }

  // ============== 디버그/관리용 (원하면 사용) ==============

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
