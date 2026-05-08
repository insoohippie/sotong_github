// lib/repository/ref_data_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/ref_data_data_source.dart';
import '../model/refData/daily_consume.dart';
import '../model/refData/monthly_consume.dart';
import '../model/refData/monthly_income.dart';
import '../model/refData/ref_data.dart';

/// Repository responsible for loading and persisting refData entities.
/// ✅ Policy 100%:
/// - uid 없으면 cache/remote 접근 금지 (기본값 반환 / save는 무시)
/// - cache는 uid별 분리
/// - 온라인 동기화 실패 시 dirty 유지 (절대 false로 안 내림)
class RefDataRepository {
  RefDataRepository(this._ds, this._auth);

  final RefDataDataSource _ds;
  final AuthDataSource _auth;

  // ✅ main()에서 이미 openBox('refData') 해두는 것을 권장
  //   (너가 categories 박스 쓰는 것처럼)
  final Box _cacheBox = Hive.box('refData');

  /// TODO: connectivity_plus로 실제 반영 가능
  bool isOnline = true;

  // =========================================================
  // Policy: uid 없으면 cache/remote 절대 사용 X
  // =========================================================
  String? get _uid => _auth.currentUser?.uid;

  // =========================================================
  // Cache Keys (uid 별 분리)
  // =========================================================
  String _cacheKeyAll(String uid) => '$uid:refdata:all';
  String _dirtyKeyAll(String uid) => '${_cacheKeyAll(uid)}:dirty';

  String _cacheKeyMonthlyIncome(String uid, String id) => '$uid:refdata:mi:$id';
  String _cacheKeyMonthlyConsume(String uid, String id) => '$uid:refdata:mc:$id';
  String _cacheKeyDailyConsume(String uid, String id) => '$uid:refdata:dc:$id';

  String _dirtyKeyMonthlyIncome(String uid, String id) =>
      '${_cacheKeyMonthlyIncome(uid, id)}:dirty';
  String _dirtyKeyMonthlyConsume(String uid, String id) =>
      '${_cacheKeyMonthlyConsume(uid, id)}:dirty';
  String _dirtyKeyDailyConsume(String uid, String id) =>
      '${_cacheKeyDailyConsume(uid, id)}:dirty';

  bool _isDirtyKey(String key) {
    final v = _cacheBox.get(key);
    return v is bool ? v : false;
  }

  void _setDirtyKey(String key, bool value) {
    _cacheBox.put(key, value);
  }

  // =========================================================
  // Cache Serialize/Deserialize
  // =========================================================
  void _putJson(String key, Map<String, dynamic> map) {
    _cacheBox.put(key, jsonEncode(map));
  }

  Map<String, dynamic>? _getJson(String key) {
    final raw = _cacheBox.get(key);
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // Cache Loaders (개별 문서)
  // =========================================================
  Map<String, MonthlyIncome> _loadMonthlyIncomeCacheAll(String uid) {
    final all = <String, MonthlyIncome>{};
    // allKey가 있으면 그걸 기반으로 읽고, 없으면 스캔해서 읽음
    final index = _getJson(_cacheKeyAll(uid));
    final ids = (index?['monthlyIncomeIds'] as List?)?.whereType<String>().toList();

    if (ids != null) {
      for (final id in ids) {
        final m = _getJson(_cacheKeyMonthlyIncome(uid, id));
        if (m != null) {
          all[id] = MonthlyIncome.fromMap(id, m);
        }
      }
      return all;
    }

    // fallback: box key 스캔 (느리지만 안전)
    for (final k in _cacheBox.keys.whereType<String>()) {
      if (!k.startsWith('$uid:refdata:mi:')) continue;
      if (k.endsWith(':dirty')) continue;
      final id = k.split(':').last;
      final m = _getJson(k);
      if (m != null) all[id] = MonthlyIncome.fromMap(id, m);
    }
    return all;
  }

  Map<String, MonthlyConsume> _loadMonthlyConsumeCacheAll(String uid) {
    final all = <String, MonthlyConsume>{};
    final index = _getJson(_cacheKeyAll(uid));
    final ids = (index?['monthlyConsumeIds'] as List?)?.whereType<String>().toList();

    if (ids != null) {
      for (final id in ids) {
        final m = _getJson(_cacheKeyMonthlyConsume(uid, id));
        if (m != null) {
          all[id] = MonthlyConsume.fromMap(id, m);
        }
      }
      return all;
    }

    for (final k in _cacheBox.keys.whereType<String>()) {
      if (!k.startsWith('$uid:refdata:mc:')) continue;
      if (k.endsWith(':dirty')) continue;
      final id = k.split(':').last;
      final m = _getJson(k);
      if (m != null) all[id] = MonthlyConsume.fromMap(id, m);
    }
    return all;
  }

  Map<String, DailyConsume> _loadDailyConsumeCacheAll(String uid) {
    final all = <String, DailyConsume>{};
    final index = _getJson(_cacheKeyAll(uid));
    final ids = (index?['dailyConsumeIds'] as List?)?.whereType<String>().toList();

    if (ids != null) {
      for (final id in ids) {
        final m = _getJson(_cacheKeyDailyConsume(uid, id));
        if (m != null) {
          all[id] = DailyConsume.fromMap(id, m);
        }
      }
      return all;
    }

    for (final k in _cacheBox.keys.whereType<String>()) {
      if (!k.startsWith('$uid:refdata:dc:')) continue;
      if (k.endsWith(':dirty')) continue;
      final id = k.split(':').last;
      final m = _getJson(k);
      if (m != null) all[id] = DailyConsume.fromMap(id, m);
    }
    return all;
  }

  void _saveIndexAll(
      String uid, {
        required Iterable<String> monthlyIncomeIds,
        required Iterable<String> monthlyConsumeIds,
        required Iterable<String> dailyConsumeIds,
      }) {
    _putJson(_cacheKeyAll(uid), {
      'monthlyIncomeIds': monthlyIncomeIds.toList(growable: false),
      'monthlyConsumeIds': monthlyConsumeIds.toList(growable: false),
      'dailyConsumeIds': dailyConsumeIds.toList(growable: false),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // =========================================================
  // Safe Remote wrappers (터지면 안 됨)
  // =========================================================
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> _safeFetchMonthlyIncomes(
      String uid) async {
    try {
      return await _ds.fetchMonthlyIncomes(uid);
    } catch (_) {
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> _safeFetchMonthlyConsumes(
      String uid) async {
    try {
      return await _ds.fetchMonthlyConsumes(uid);
    } catch (_) {
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> _safeFetchDailyConsumes(
      String uid) async {
    try {
      return await _ds.fetchDailyConsumes(uid);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _safeUpsertMonthlyIncome(
      String uid, String id, Map<String, dynamic> map) async {
    try {
      await _ds.upsertMonthlyIncome(uid, id, map);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeUpsertMonthlyConsume(
      String uid, String id, Map<String, dynamic> map) async {
    try {
      await _ds.upsertMonthlyConsume(uid, id, map);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeUpsertDailyConsume(
      String uid, String id, Map<String, dynamic> map) async {
    try {
      await _ds.upsertDailyConsume(uid, id, map);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeDeleteMonthlyIncome(String uid, String id) async {
    try {
      await _ds.deleteMonthlyIncome(uid, id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeDeleteMonthlyConsume(String uid, String id) async {
    try {
      await _ds.deleteMonthlyConsume(uid, id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeDeleteDailyConsume(String uid, String id) async {
    try {
      await _ds.deleteDailyConsume(uid, id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // Public API
  // =========================================================

  /// Loads every refData document beneath the user and hydrates [RefData].
  /// ✅ Policy:
  /// - uid 없으면 빈 RefData 반환
  /// - 오프라인이면 캐시 반환
  /// - 온라인이면 remote -> 캐시 갱신
  /// - remote 실패 시 캐시 반환 (없으면 빈 값) + allDirty 유지
  Future<RefData> loadAll() async {
    final uid = _uid;
    if (uid == null) {
      return RefData(
        planId: '',
        monthlyIncomes: const {},
        monthlyConsumes: const {},
        dailyConsumes: const {},
      );
    }

    // 1) 캐시 로드
    final cachedMonthlyIncomes = _loadMonthlyIncomeCacheAll(uid);
    final cachedMonthlyConsumes = _loadMonthlyConsumeCacheAll(uid);
    final cachedDailyConsumes = _loadDailyConsumeCacheAll(uid);
    final allDirty = _isDirtyKey(_dirtyKeyAll(uid));

    // 오프라인이면 캐시 우선
    if (!isOnline) {
      return RefData(
        planId: '',
        monthlyIncomes: cachedMonthlyIncomes,
        monthlyConsumes: cachedMonthlyConsumes,
        dailyConsumes: cachedDailyConsumes,
      );
    }

    // 2) 온라인이면 remote fetch (실패하면 캐시로 폴백)
    final results = await Future.wait([
      _safeFetchMonthlyIncomes(uid),
      _safeFetchMonthlyConsumes(uid),
      _safeFetchDailyConsumes(uid),
    ]);

    final miDocs = results[0];
    final mcDocs = results[1];
    final dcDocs = results[2];

    // 하나라도 null이면(=read 실패) 캐시 반환
    if (miDocs == null || mcDocs == null || dcDocs == null) {
      // 캐시가 비어있다면 "빈 값 + dirty=true"로 다음에 다시 시도하도록
      if (cachedMonthlyIncomes.isEmpty &&
          cachedMonthlyConsumes.isEmpty &&
          cachedDailyConsumes.isEmpty) {
        _setDirtyKey(_dirtyKeyAll(uid), true);
      } else {
        // 기존 dirty 상태 유지 (false로 내리지 않음)
        if (allDirty) _setDirtyKey(_dirtyKeyAll(uid), true);
      }

      return RefData(
        planId: '',
        monthlyIncomes: cachedMonthlyIncomes,
        monthlyConsumes: cachedMonthlyConsumes,
        dailyConsumes: cachedDailyConsumes,
      );
    }

    // 3) remote -> model
    final remoteMonthlyIncomes = <String, MonthlyIncome>{
      for (final doc in miDocs) doc.id: MonthlyIncome.fromMap(doc.id, doc.data()),
    };
    final remoteMonthlyConsumes = <String, MonthlyConsume>{
      for (final doc in mcDocs) doc.id: MonthlyConsume.fromMap(doc.id, doc.data()),
    };
    final remoteDailyConsumes = <String, DailyConsume>{
      for (final doc in dcDocs) doc.id: DailyConsume.fromMap(doc.id, doc.data()),
    };

    // 4) remote 우선 캐시 갱신 (✅ 최소 정책: dirty개별 문서가 있으면 그건 건드리지 않음)
    // - 로드 시점에는 "서버가 최신"을 기본으로 하되,
    // - 로컬에서 수정 중인 문서(=dirty)는 overwrite 하면 안 됨.
    for (final e in remoteMonthlyIncomes.entries) {
      final dirtyKey = _dirtyKeyMonthlyIncome(uid, e.key);
      if (_isDirtyKey(dirtyKey)) continue;
      _putJson(_cacheKeyMonthlyIncome(uid, e.key), e.value.toMap());
    }
    for (final e in remoteMonthlyConsumes.entries) {
      final dirtyKey = _dirtyKeyMonthlyConsume(uid, e.key);
      if (_isDirtyKey(dirtyKey)) continue;
      _putJson(_cacheKeyMonthlyConsume(uid, e.key), e.value.toMap());
    }
    for (final e in remoteDailyConsumes.entries) {
      final dirtyKey = _dirtyKeyDailyConsume(uid, e.key);
      if (_isDirtyKey(dirtyKey)) continue;
      _putJson(_cacheKeyDailyConsume(uid, e.key), e.value.toMap());
    }

    // index 저장
    _saveIndexAll(
      uid,
      monthlyIncomeIds: remoteMonthlyIncomes.keys,
      monthlyConsumeIds: remoteMonthlyConsumes.keys,
      dailyConsumeIds: remoteDailyConsumes.keys,
    );

    // allDirty는 load 성공하면 false로 내려도 됨 (개별 dirty는 별도 유지)
    _setDirtyKey(_dirtyKeyAll(uid), false);

    // 5) 반환은 remote 기준
    return RefData(
      planId: '',
      monthlyIncomes: remoteMonthlyIncomes,
      monthlyConsumes: remoteMonthlyConsumes,
      dailyConsumes: remoteDailyConsumes,
    );
  }

  // =========================================================
  // Save APIs (cache 먼저, dirty 설정, 온라인이면 업로드 시도)
  // =========================================================

  Future<void> saveMonthlyIncome(MonthlyIncome income) async {
    final uid = _uid;
    if (uid == null) return;

    final id = income.id;
    final cacheKey = _cacheKeyMonthlyIncome(uid, id);
    final dirtyKey = _dirtyKeyMonthlyIncome(uid, id);

    _putJson(cacheKey, income.toMap());
    _setDirtyKey(dirtyKey, true);

    // index에도 반영
    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['monthlyIncomeIds'] as List?)?.whereType<String>().toSet() ?? <String>{};
    ids.add(id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: ids,
      monthlyConsumeIds: (cur['monthlyConsumeIds'] as List?)?.whereType<String>() ?? const [],
      dailyConsumeIds: (cur['dailyConsumeIds'] as List?)?.whereType<String>() ?? const [],
    );

    if (isOnline) {
      final ok = await _safeUpsertMonthlyIncome(uid, id, income.toMap());
      if (ok) _setDirtyKey(dirtyKey, false);
    }
  }

  Future<void> saveMonthlyConsume(MonthlyConsume consume) async {
    final uid = _uid;
    if (uid == null) return;

    final id = consume.id;
    final cacheKey = _cacheKeyMonthlyConsume(uid, id);
    final dirtyKey = _dirtyKeyMonthlyConsume(uid, id);

    _putJson(cacheKey, consume.toMap());
    _setDirtyKey(dirtyKey, true);

    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['monthlyConsumeIds'] as List?)?.whereType<String>().toSet() ?? <String>{};
    ids.add(id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: (cur['monthlyIncomeIds'] as List?)?.whereType<String>() ?? const [],
      monthlyConsumeIds: ids,
      dailyConsumeIds: (cur['dailyConsumeIds'] as List?)?.whereType<String>() ?? const [],
    );

    if (isOnline) {
      final ok = await _safeUpsertMonthlyConsume(uid, id, consume.toMap());
      if (ok) _setDirtyKey(dirtyKey, false);
    }
  }

  Future<void> saveDailyConsume(DailyConsume consume) async {
    final uid = _uid;
    if (uid == null) return;

    final id = consume.id;
    final cacheKey = _cacheKeyDailyConsume(uid, id);
    final dirtyKey = _dirtyKeyDailyConsume(uid, id);

    _putJson(cacheKey, consume.toMap());
    _setDirtyKey(dirtyKey, true);

    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['dailyConsumeIds'] as List?)?.whereType<String>().toSet() ?? <String>{};
    ids.add(id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: (cur['monthlyIncomeIds'] as List?)?.whereType<String>() ?? const [],
      monthlyConsumeIds: (cur['monthlyConsumeIds'] as List?)?.whereType<String>() ?? const [],
      dailyConsumeIds: ids,
    );

    if (isOnline) {
      final ok = await _safeUpsertDailyConsume(uid, id, consume.toMap());
      if (ok) _setDirtyKey(dirtyKey, false);
    }
  }

  // =========================================================
  // Delete APIs (cache 먼저, 온라인이면 remote 시도)
  // =========================================================

  Future<void> deleteMonthlyIncome(String id) async {
    final uid = _uid;
    if (uid == null) return;

    await _cacheBox.delete(_cacheKeyMonthlyIncome(uid, id));
    await _cacheBox.delete(_dirtyKeyMonthlyIncome(uid, id));

    // index 갱신
    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['monthlyIncomeIds'] as List?)?.whereType<String>().toList() ?? <String>[];
    ids.removeWhere((e) => e == id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: ids,
      monthlyConsumeIds: (cur['monthlyConsumeIds'] as List?)?.whereType<String>() ?? const [],
      dailyConsumeIds: (cur['dailyConsumeIds'] as List?)?.whereType<String>() ?? const [],
    );

    if (isOnline) {
      await _safeDeleteMonthlyIncome(uid, id);
    } else {
      // 오프라인 삭제는 “삭제 큐”가 필요하지만, 최소 수정이라 allDirty만 올려둠
      _setDirtyKey(_dirtyKeyAll(uid), true);
    }
  }

  Future<void> deleteMonthlyConsume(String id) async {
    final uid = _uid;
    if (uid == null) return;

    await _cacheBox.delete(_cacheKeyMonthlyConsume(uid, id));
    await _cacheBox.delete(_dirtyKeyMonthlyConsume(uid, id));

    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['monthlyConsumeIds'] as List?)?.whereType<String>().toList() ?? <String>[];
    ids.removeWhere((e) => e == id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: (cur['monthlyIncomeIds'] as List?)?.whereType<String>() ?? const [],
      monthlyConsumeIds: ids,
      dailyConsumeIds: (cur['dailyConsumeIds'] as List?)?.whereType<String>() ?? const [],
    );

    if (isOnline) {
      await _safeDeleteMonthlyConsume(uid, id);
    } else {
      _setDirtyKey(_dirtyKeyAll(uid), true);
    }
  }

  Future<void> deleteDailyConsume(String id) async {
    final uid = _uid;
    if (uid == null) return;

    await _cacheBox.delete(_cacheKeyDailyConsume(uid, id));
    await _cacheBox.delete(_dirtyKeyDailyConsume(uid, id));

    final cur = _getJson(_cacheKeyAll(uid)) ?? {};
    final ids = (cur['dailyConsumeIds'] as List?)?.whereType<String>().toList() ?? <String>[];
    ids.removeWhere((e) => e == id);
    _saveIndexAll(
      uid,
      monthlyIncomeIds: (cur['monthlyIncomeIds'] as List?)?.whereType<String>() ?? const [],
      monthlyConsumeIds: (cur['monthlyConsumeIds'] as List?)?.whereType<String>() ?? const [],
      dailyConsumeIds: ids,
    );

    if (isOnline) {
      await _safeDeleteDailyConsume(uid, id);
    } else {
      _setDirtyKey(_dirtyKeyAll(uid), true);
    }
  }

  // =========================================================
  // Optional: logout 시 유저 캐시 정리
  // =========================================================
  Future<void> clearMyRefDataCache() async {
    final uid = _uid;
    if (uid == null) return;

    final prefix = '$uid:refdata:';
    final keysToDelete = _cacheBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);

    for (final k in keysToDelete) {
      await _cacheBox.delete(k);
    }
  }

  Future<void> syncToRemote() async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[RefDataRepository] syncToRemote aborted: missing uid');
      return;
    }
    final monthlyIncomes = _loadMonthlyIncomeCacheAll(uid);
    final monthlyConsumes = _loadMonthlyConsumeCacheAll(uid);
    final dailyConsumes = _loadDailyConsumeCacheAll(uid);

    for (final entry in monthlyIncomes.entries) {
      final dirtyKey = _dirtyKeyMonthlyIncome(uid, entry.key);
      if (!_isDirtyKey(dirtyKey)) continue;
      if (await _syncMonthlyIncome(uid, entry.value)) {
        _setDirtyKey(dirtyKey, false);
      }
    }
    for (final entry in monthlyConsumes.entries) {
      final dirtyKey = _dirtyKeyMonthlyConsume(uid, entry.key);
      if (!_isDirtyKey(dirtyKey)) continue;
      if (await _syncMonthlyConsume(uid, entry.value)) {
        _setDirtyKey(dirtyKey, false);
      }
    }
    for (final entry in dailyConsumes.entries) {
      final dirtyKey = _dirtyKeyDailyConsume(uid, entry.key);
      if (!_isDirtyKey(dirtyKey)) continue;
      if (await _syncDailyConsume(uid, entry.value)) {
        _setDirtyKey(dirtyKey, false);
      }
    }
    _saveIndexAll(
      uid,
      monthlyIncomeIds: monthlyIncomes.keys,
      monthlyConsumeIds: monthlyConsumes.keys,
      dailyConsumeIds: dailyConsumes.keys,
    );
  }

  Future<bool> _syncMonthlyIncome(String uid, MonthlyIncome income) async {
    try {
      await _ds.upsertMonthlyIncome(uid, income.id, income.toMap());
      return true;
    } catch (e) {
      debugPrint('[RefDataRepository] failed to sync monthly income ${income.id}: $e');
      return false;
    }
  }

  Future<bool> _syncMonthlyConsume(String uid, MonthlyConsume consume) async {
    try {
      await _ds.upsertMonthlyConsume(uid, consume.id, consume.toMap());
      return true;
    } catch (e) {
      debugPrint('[RefDataRepository] failed to sync monthly consume ${consume.id}: $e');
      return false;
    }
  }

  Future<bool> _syncDailyConsume(String uid, DailyConsume consume) async {
    try {
      await _ds.upsertDailyConsume(uid, consume.id, consume.toMap());
      return true;
    } catch (e) {
      debugPrint('[RefDataRepository] failed to sync daily consume ${consume.id}: $e');
      return false;
    }
  }
}
