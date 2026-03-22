// lib/repository/ref_category_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/ref_category_data_source.dart';
import '../model/category/ref_category_item.dart';

class RefCategoryRepository {
  RefCategoryRepository(this._ds, this._auth);

  final RefCategoryDataSource _ds;
  final AuthDataSource _auth;

  final Box _cacheBox = Hive.box('ref_categories');

  /// TODO: 나중에 connectivity_plus로 실제 반영
  bool isOnline = true;

  // =========================================================
  // Policy: uid 없으면 cache/remote 절대 사용 X
  // =========================================================
  String? get _uid => _auth.currentUser?.uid;

  // ============== 캐시 키 ==============
  // docId 예: 'recordSpending' | 'addIncomes'
  String _cacheKey(String uid, String docId) => '$uid:refcat:$docId';
  String _dirtyKey(String uid, String docId) => '${_cacheKey(uid, docId)}:dirty';

  bool _isDirty(String uid, String docId) {
    final v = _cacheBox.get(_dirtyKey(uid, docId));
    return v is bool ? v : false;
  }

  void _setDirty(String uid, String docId, bool value) {
    _cacheBox.put(_dirtyKey(uid, docId), value);
  }

  // =========================================================
  // Serialize / Parse
  // =========================================================
  List<RefCategoryItem> _parseItemsFromDocMap(Map<String, dynamic>? data) {
    final raw = data?['items'];
    if (raw is! List) return const [];

    // Firestore에서 List<dynamic> 안에 Map<dynamic,dynamic>로 올 수도 있어서 안전 변환
    final items = raw
        .whereType<Map>()
        .map((m) => RefCategoryItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    items.sort((a, b) => a.order.compareTo(b.order));
    return [
      for (int i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
  }

  List<RefCategoryItem> _normalize(List<RefCategoryItem> items) {
    final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (int i = 0; i < sorted.length; i++) sorted[i].copyWith(order: i),
    ];
  }

  Map<String, dynamic> _toDoc(List<RefCategoryItem> items) {
    final normalized = _normalize(items);
    return {
      'items': normalized.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(), // 기록용
    };
  }

  // =========================================================
  // Hive Cache
  // =========================================================
  List<RefCategoryItem>? _loadCache(String uid, String docId) {
    final key = _cacheKey(uid, docId);
    final rawStr = _cacheBox.get(key);
    if (rawStr is! String) return null;

    try {
      final map = jsonDecode(rawStr) as Map<String, dynamic>;
      return _parseItemsFromDocMap(map);
    } catch (_) {
      return null;
    }
  }

  void _saveCache(String uid, String docId, List<RefCategoryItem> items) {
    final key = _cacheKey(uid, docId);
    final normalized = _normalize(items);
    final map = {'items': normalized.map((e) => e.toMap()).toList()};
    _cacheBox.put(key, jsonEncode(map));
  }

  // =========================================================
  // Remote safe wrappers (정책 핵심: 실패면 dirty 유지)
  // =========================================================
  Future<DocumentSnapshot<Map<String, dynamic>>?> _safeGetRemote(
      String uid,
      String docId,
      ) async {
    try {
      return await _ds.getRefDoc(uid, docId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _safeSetRemote(
      String uid,
      String docId,
      List<RefCategoryItem> items,
      ) async {
    try {
      await _ds.setRefDoc(uid, docId, _toDoc(items), merge: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // Public API (Policy 100% 준수)
  // =========================================================

  /// ✅ uid 없으면: "기본값"만 반환 (cache/remote 접근 금지)
  /// - refCategory는 Record처럼 monthKey가 없으니, 게스트는 그냥 빈 리스트를 기본으로 둠
  Future<List<RefCategoryItem>> fetchRefCategories({
    required String docId,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const [];
    }

    // 1) 캐시 먼저
    final cache = _loadCache(uid, docId);
    final dirty = _isDirty(uid, docId);

    // 오프라인이면 캐시 우선
    if (!isOnline) return cache ?? const [];

    // 2) 온라인이면 서버 확인 (실패해도 터지면 안 됨)
    final snap = await _safeGetRemote(uid, docId);

    // ✅ 서버 read 실패: 캐시 우선. 캐시 없으면 빈 리스트 + dirty=true(나중 업로드 대상)
    if (snap == null) {
      if (cache != null) return cache;

      final empty = <RefCategoryItem>[];
      _saveCache(uid, docId, empty);
      _setDirty(uid, docId, true);
      return empty;
    }

    // 2-1) 서버 문서 없음
    if (!snap.exists) {
      if (cache != null) {
        // - dirty=true면 로컬을 서버에 업로드 시도. 성공 시에만 dirty 해제
        // - dirty=false면 로컬로 서버 기본 문서 마련(실패해도 캐시 유지)
        final ok = await _safeSetRemote(uid, docId, cache);

        if (dirty) {
          if (ok) _setDirty(uid, docId, false);
          // 실패면 dirty 유지
        }
        return cache;
      }

      // 캐시도 없으면 빈 문서 생성 (캐시 저장)
      final empty = <RefCategoryItem>[];
      _saveCache(uid, docId, empty);
      _setDirty(uid, docId, false);

      final ok = await _safeSetRemote(uid, docId, empty);
      if (!ok) {
        // ✅ 실패면 dirty=true로 남겨서 재시도 대상
        _setDirty(uid, docId, true);
      }
      return empty;
    }

    // 2-2) 서버 문서 있음
    final remote = _parseItemsFromDocMap(snap.data());

    if (dirty) {
      // dirty=true => 로컬 우선
      if (cache != null) {
        final cacheNorm = _normalize(cache);
        final remoteNorm = _normalize(remote);

        // 다르면 로컬을 서버에 업로드
        if (jsonEncode({'items': cacheNorm.map((e) => e.toMap()).toList()}) !=
            jsonEncode({'items': remoteNorm.map((e) => e.toMap()).toList()})) {
          final ok = await _safeSetRemote(uid, docId, cacheNorm);
          if (ok) _setDirty(uid, docId, false);
          // 실패면 dirty 유지
          return cacheNorm;
        } else {
          // 같으면 dirty 해제 가능
          _setDirty(uid, docId, false);
          return cacheNorm;
        }
      } else {
        // dirty=true인데 cache가 없다? (이론상 드묾)
        // => 서버를 캐시로 저장하고 dirty는 유지하지 않는 게 안전
        _saveCache(uid, docId, remote);
        _setDirty(uid, docId, false);
        return remote;
      }
    }

    // dirty=false => 서버 우선(remote -> cache)
    _saveCache(uid, docId, remote);
    _setDirty(uid, docId, false);
    return remote;
  }

  /// ✅ 저장 정책 (Policy 100%):
  /// 1) Hive 저장
  /// 2) dirty=true
  /// 3) 온라인이면 업로드 시도
  /// 4) 성공 시 dirty=false / 실패 시 dirty=true 유지
  Future<void> saveRefCategories({
    required String docId,
    required List<RefCategoryItem> items,
    bool markDirty = true,
  }) async {
    final uid = _uid;
    if (uid == null) {
      // 정책: uid 없으면 cache/remote 사용 금지 -> 조용히 종료
      return;
    }

    final normalized = _normalize(items);

    // 1) 항상 캐시 저장
    _saveCache(uid, docId, normalized);

    // 2) dirty = true
    if (markDirty) _setDirty(uid, docId, true);

    // 3) 온라인이면 업로드 시도
    if (isOnline) {
      final ok = await _safeSetRemote(uid, docId, normalized);
      if (ok) {
        _setDirty(uid, docId, false);
      } else {
        _setDirty(uid, docId, true);
      }
    }
  }

  // =========================================================
  // Logout / cache clear helpers (정책: uid 필요)
  // =========================================================

  /// 현재 유저의 refCategories 캐시만 지움
  Future<void> clearMyRefCategoryCache() async {
    final uid = _uid;
    if (uid == null) return;

    final prefix = '$uid:refcat:';
    final keysToDelete = _cacheBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);

    for (final k in keysToDelete) {
      await _cacheBox.delete(k);
      await _cacheBox.delete('$k:dirty');
    }
  }
}