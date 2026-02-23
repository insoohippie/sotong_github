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

  // ✅ 네 main에서 이미 열어둔 박스 사용
  final Box _cacheBox = Hive.box('categories');

  /// TODO: 필요하면 connectivity_plus로 연동
  bool isOnline = true;

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  // ============== 캐시 키 ==============
  String _cacheKey(String uid, String docId) => '$uid:refcat:$docId';
  String _dirtyKey(String uid, String docId) => '${_cacheKey(uid, docId)}:dirty';

  bool _isDirty(String uid, String docId) {
    final v = _cacheBox.get(_dirtyKey(uid, docId));
    return v is bool ? v : false;
  }

  void _setDirty(String uid, String docId, bool value) {
    _cacheBox.put(_dirtyKey(uid, docId), value);
  }

  List<RefCategoryItem> _parseItemsFromDocMap(Map<String, dynamic>? data) {
    final raw = data?['items'];
    if (raw is! List) return const [];

    final items = raw
        .whereType<Map<String, dynamic>>()
        .map((m) => RefCategoryItem.fromMap(m))
        .toList();

    items.sort((a, b) => a.order.compareTo(b.order));
    return [
      for (int i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
  }

  Map<String, dynamic> _toDoc(List<RefCategoryItem> items) {
    final normalized = [
      for (int i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
    return {
      'items': normalized.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

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
    final map = {'items': items.map((e) => e.toMap()).toList()};
    _cacheBox.put(key, jsonEncode(map));
  }

  // =========================================================
  // Public API
  // =========================================================

  /// docId: 'recordSpending' | 'addIncomes'
  Future<List<RefCategoryItem>> fetchRefCategories({
    required String docId,
  }) async {
    final uid = _uidOrThrow();

    // 1) 캐시 먼저
    final cache = _loadCache(uid, docId);
    final dirty = _isDirty(uid, docId);

    // 오프라인이면 캐시 우선
    if (!isOnline) return cache ?? const [];

    // 2) 온라인이면 서버 확인
    final snap = await _ds.getRefDoc(uid, docId);

    if (!snap.exists) {
      // 서버 문서가 없으면:
      // - 캐시가 있고 dirty면 캐시를 서버에 업로드
      // - 캐시가 없으면 빈 문서 생성
      if (cache != null) {
        if (dirty) {
          await _ds.setRefDoc(uid, docId, _toDoc(cache), merge: false);
          _setDirty(uid, docId, false);
        } else {
          await _ds.setRefDoc(uid, docId, _toDoc(cache), merge: false);
        }
        return cache;
      } else {
        final empty = <RefCategoryItem>[];
        _saveCache(uid, docId, empty);
        _setDirty(uid, docId, false);
        await _ds.setRefDoc(uid, docId, _toDoc(empty), merge: false);
        return empty;
      }
    }

    // 서버 데이터 파싱
    final data = snap.data();
    final remote = _parseItemsFromDocMap(data);

    // dirty면 로컬 우선(캐시 -> 서버 덮어쓰기)
    if (dirty && cache != null) {
      await _ds.setRefDoc(uid, docId, _toDoc(cache), merge: false);
      _setDirty(uid, docId, false);
      return cache;
    }

    // dirty가 아니면 서버 우선(remote -> 캐시)
    _saveCache(uid, docId, remote);
    _setDirty(uid, docId, false);
    return remote;
  }

  Future<void> saveRefCategories({
    required String docId,
    required List<RefCategoryItem> items,
    bool markDirty = true,
  }) async {
    final uid = _uidOrThrow();

    // 항상 캐시 저장
    final normalized = [
      for (int i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
    _saveCache(uid, docId, normalized);

    if (markDirty) _setDirty(uid, docId, true);

    if (isOnline) {
      await _ds.setRefDoc(uid, docId, _toDoc(normalized), merge: false);
      _setDirty(uid, docId, false);
    }
  }
}
