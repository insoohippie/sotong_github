// lib/repository/record_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/record_data_source.dart';
import '../model/record/day_record.dart';
import '../model/record/monthly_record.dart';
import '../model/record/record_entry.dart';

class RecordRepository {
  final RecordDataSource _dataSource;
  final AuthDataSource _authDataSource;

  /// ✅ 기존 캐시와의 호환을 위해 box 이름은 그대로 유지
  final Box _cacheBox = Hive.box('monthly_spending');

  bool localMode = true;

  RecordRepository(this._dataSource, this._authDataSource);

  String? get _uid => _authDataSource.currentUser?.uid;

  /// TODO: 나중에 connectivity_plus 로 실제 네트워크 상태 반영
  bool isOnline = true;

  // ============== 내부: 키/캐시/dirty 헬퍼 ==============

  String _monthKey(String monthKey) {
    final uid = _uid;
    if (uid == null) return 'NO_UID:$monthKey';
    return '$uid:$monthKey';
  }

  String _dirtyKey(String monthKey) => '${_monthKey(monthKey)}:dirty';

  MonthlyRecord? _loadFromCache(String monthKey) {
    final uid = _uid;
    if (uid == null) return null;

    final key = _monthKey(monthKey);
    if (!_cacheBox.containsKey(key)) return null;

    final rawStr = _cacheBox.get(key);
    if (rawStr is! String) return null;

    try {
      final map = jsonDecode(rawStr) as Map<String, dynamic>;
      return MonthlyRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _saveToCache(String monthKey, MonthlyRecord month) {
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

  bool _isSame(MonthlyRecord a, MonthlyRecord b) {
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }

  bool hasAnyCacheForCurrentUser() {
    final uid = _uid;
    if (uid == null) return false;
    final prefix = '$uid:';
    return _cacheBox.keys.whereType<String>().any(
      (key) => key.startsWith(prefix) && !key.endsWith(':dirty'),
    );
  }

  Future<void> hydrateAllFromRemote() async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[RecordRepository] hydrate aborted: missing uid');
      return;
    }
    if (!isOnline) {
      debugPrint('[RecordRepository] hydrate aborted: offline');
      return;
    }
    if (localMode) {
      debugPrint('[RecordRepository] hydrate aborted: localMode=true');
      return;
    }
    try {
      final snaps = await _dataSource.listMonthlyDocs(uid);
      for (final doc in snaps.docs) {
        final monthKey = doc.id;
        final data = doc.data();
        final remote = MonthlyRecord.fromFirestore(monthKey, data);
        _saveToCache(monthKey, remote);
        _setDirty(monthKey, false);
      }
      debugPrint('[RecordRepository] hydrate complete: ${snaps.docs.length} months cached');
    } catch (e) {
      debugPrint('[RecordRepository] hydrate failed: $e');
    }
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

  /// ✅ 성공/실패를 리턴한다 (실패면 dirty 유지)
  Future<bool> _safeSetRemote(
      String uid,
      String monthKey,
      MonthlyRecord month,
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

  String _toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  Future<MonthlyRecord> loadMonthlyRecord(String monthKey) async {
    final uid = _uid;

    // A. uid 없으면: 기본값만 반환
    if (uid == null) {
      return MonthlyRecord.empty(monthKey);
    }

    final cache = _loadFromCache(monthKey);
    final dirty = _isDirty(monthKey);

    // 1) 캐시가 있으면 캐시 우선
    if (cache != null) {
      if (!isOnline) return cache;

      final snap = await _safeGetRemoteMonth(uid, monthKey);

      // 서버 read 실패면 캐시 반환
      if (snap == null) return cache;

      // 서버 문서 없음
      if (!snap.exists) {
        final ok = await _safeSetRemote(uid, monthKey, cache);

        if (dirty) {
          if (ok) _setDirty(monthKey, false);
        }

        return cache;
      }

      // 서버 문서 있음
      final data = snap.data() as Map<String, dynamic>;
      final remote = MonthlyRecord.fromFirestore(monthKey, data);

      if (dirty) {
        if (localMode) {
          debugPrint(
            '[RecordRepository] dirty month=$monthKey but localMode=true; skip remote upload',
          );
          return cache;
        }
        // dirty=true => 로컬 우선 (온라인 + localMode=false일 때만 업로드)
        if (!_isSame(cache, remote)) {
          debugPrint(
            '[RecordRepository] syncing dirty month immediately month=$monthKey (localMode=$localMode)',
          );
          final ok = await _safeSetRemote(uid, monthKey, cache);
          if (ok) _setDirty(monthKey, false);
        } else {
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
    if (!localMode && isOnline) {
      final snap = await _safeGetRemoteMonth(uid, monthKey);

      // 서버 read 실패면: local empty + dirty=true
      if (snap == null) {
        final fallback = MonthlyRecord.empty(monthKey);
        _saveToCache(monthKey, fallback);
        _setDirty(monthKey, true);
        return fallback;
      }

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final remote = MonthlyRecord.fromFirestore(monthKey, data);
        _saveToCache(monthKey, remote);
        _setDirty(monthKey, false);
        return remote;
      }

      // 서버에도 없으면 initial 생성
      final initial = MonthlyRecord.empty(monthKey);
      _saveToCache(monthKey, initial);
      _setDirty(monthKey, false);

      final ok = await _safeSetRemote(uid, monthKey, initial);
      if (!ok) {
        _setDirty(monthKey, true);
      }

      return initial;
    }

    // 오프라인 + 캐시 없음
    final offlineInitial = MonthlyRecord.empty(monthKey);
    _saveToCache(monthKey, offlineInitial);
    _setDirty(monthKey, true);
    return offlineInitial;
  }

  Future<MonthlyRecord> loadMonthlyRecordByDate(DateTime date) {
    return loadMonthlyRecord(_toMonthKey(date));
  }

  Future<void> saveMonthlyRecord(
      MonthlyRecord month, {
        bool markDirty = true,
      }) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = month.monthKey;

    _saveToCache(monthKey, month);
    if (markDirty) _setDirty(monthKey, true);

    if (!localMode && isOnline) {
      final ok = await _safeSetRemote(uid, monthKey, month);
      if (ok) {
        _setDirty(monthKey, false);
      } else {
        _setDirty(monthKey, true);
      }
    }
  }

  /// ✅ 하루 기록 전체 upsert
  Future<void> upsertDayRecord(DayRecord day) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = _toMonthKey(day.date);
    final dateKey = DateFormat('yyyy-MM-dd').format(day.date);

    final monthly = await loadMonthlyRecord(monthKey);

    final newDays = Map<String, DayRecord>.from(monthly.days);
    newDays[dateKey] = day;

    final updatedMonthly = monthly.copyWith(days: newDays);

    await saveMonthlyRecord(updatedMonthly);
  }

  /// ✅ 소비만 갱신
  Future<void> upsertSpendingForDate({
    required DateTime date,
    required List<RecordEntry> spendingEntries,
    required int totalSpendingAmount,
    String? emotion,
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = _toMonthKey(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final monthly = await loadMonthlyRecord(monthKey);
    final existingDay = monthly.days[dateKey] ?? DayRecord.empty(date);

    final updatedDay = existingDay.copyWith(
      date: date,
      totalSpendingAmount: totalSpendingAmount,
      spendingEntries: spendingEntries.cast(),
      emotion: emotion ?? existingDay.emotion,
      comment: comment ?? existingDay.comment,
    );

    final newDays = Map<String, DayRecord>.from(monthly.days);
    newDays[dateKey] = updatedDay;

    final updatedMonthly = monthly.copyWith(days: newDays);
    await saveMonthlyRecord(updatedMonthly);
  }

  /// ✅ 수입만 갱신
  Future<void> upsertIncomeForDate({
    required DateTime date,
    required List<RecordEntry> incomeEntries,
    required int totalIncomeAmount,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final monthKey = _toMonthKey(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final monthly = await loadMonthlyRecord(monthKey);
    final existingDay = monthly.days[dateKey] ?? DayRecord.empty(date);

    final updatedDay = existingDay.copyWith(
      date: date,
      totalIncomeAmount: totalIncomeAmount,
      incomeEntries: incomeEntries.cast(),
    );

    final newDays = Map<String, DayRecord>.from(monthly.days);
    newDays[dateKey] = updatedDay;

    final updatedMonthly = monthly.copyWith(days: newDays);
    await saveMonthlyRecord(updatedMonthly);
  }

  // ============== 디버그/관리용 ==============

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

      if (count == 450) {
        await batch.commit();
        batch = db.batch();
        count = 0;
      }
    }

    await batch.commit();
  }

  Future<void> syncDirtyMonths() async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[RecordRepository] syncDirtyMonths aborted: missing uid');
      return;
    }
    final prefix = '$uid:';
    final dirtySuffix = ':dirty';
    final dirtyKeys = _cacheBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix) && k.endsWith(dirtySuffix))
        .toList(growable: false);
    for (final dirtyKey in dirtyKeys) {
      final monthKeyWithPrefix =
          dirtyKey.substring(0, dirtyKey.length - dirtySuffix.length);
      final monthKey = monthKeyWithPrefix.substring(prefix.length);
      final cached = _loadFromCache(monthKey);
      if (cached == null) continue;
      debugPrint(
          '[RecordRepository] syncing dirty month=$monthKey (localMode=$localMode)');
      final ok = await _safeSetRemote(uid, monthKey, cached);
      if (ok) {
        _setDirty(monthKey, false);
      } else {
        debugPrint(
            '[RecordRepository] failed to sync month $monthKey, will retry later');
        _setDirty(monthKey, true);
      }
    }
  }
}
