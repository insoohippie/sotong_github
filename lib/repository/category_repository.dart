import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/category_data_source.dart';
import '../model/category/category_list_model.dart';

class CategoryRepository {
  final CategoryDataSource _dataSource;
  final AuthDataSource _auth;

  final Box _cacheBox = Hive.box('categories');

  CategoryRepository(this._dataSource, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  /// TODO: 나중에 connectivity_plus 로 실제 네트워크 상태 반영
  bool isOnline = true;

  // ================== 내부: 캐시 키 ==================

  // 키 만들기 전에 uid 검사
  String _cacheKeyOrThrow() {
    final uid = _uid;
    if (uid == null) throw StateError('No uid (not logged in)');
    return '$uid:categoryList';
  }

  String _dirtyKeyOrThrow() => '${_cacheKeyOrThrow()}:dirty';

  // ================== 내부: 캐시/dirty 헬퍼 ==================

  CategoryListModel? _loadFromCache() {
    final uid = _uid;
    if (uid == null) return null;

    final key = _cacheKeyOrThrow();
    if (!_cacheBox.containsKey(key)) return null;

    final rawStr = _cacheBox.get(key);
    if (rawStr is! String) return null;

    try {
      final map = jsonDecode(rawStr) as Map<String, dynamic>;
      return CategoryListModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _saveToCache(CategoryListModel listModel) {
    final uid = _uid;
    if (uid == null) return;

    final key = _cacheKeyOrThrow();
    _cacheBox.put(key, jsonEncode(listModel.toJson()));
  }

  bool _isDirty() {
    final uid = _uid;
    if (uid == null) return false;

    final v = _cacheBox.get(_dirtyKeyOrThrow());
    return v is bool ? v : false;
  }

  void _setDirty(bool value) {
    final uid = _uid;
    if (uid == null) return;
    _cacheBox.put(_dirtyKeyOrThrow(), value);
  }

  bool _isSame(CategoryListModel a, CategoryListModel b) {
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }

  // ================== Public: 로드 / 저장 ==================

  /// 오프라인 퍼스트 로딩
  ///
  /// uid 없으면: 캐시/서버 절대 안 씀 -> initial 리턴
  ///
  /// uid 있으면:
  /// 1) Hive 캐시 있으면 즉시 반환
  ///    - 온라인이면 Firestore와 비교/동기화
  /// 2) 캐시 없으면 Firestore에서 로드(온라인)
  /// 3) 둘다 없으면 initial 생성 후 (캐시 저장 + 온라인이면 서버 저장)
  Future<CategoryListModel> loadCategoryList() async {
    final uid = _uid;

    if (uid == null) {
      return CategoryListModel.initial();
    }

    // 1) 캐시 우선
    final cache = _loadFromCache();
    if (cache != null) {
      if (!isOnline) return cache;

      // 온라인이면 서버와 동기화(서버 우선/로컬 우선 판단)
      await _syncWithRemote(uid, cache);
      // _syncWithRemote 안에서 필요하면 캐시 갱신까지 함
      return _loadFromCache() ?? cache;
    }

    // 2) 캐시 없음 + 온라인이면 Firestore 시도
    if (isOnline) {
      final docData = await _dataSource.getCategoryDoc(uid);
      if (docData != null && docData.isNotEmpty) {
        final remote = CategoryListModel.fromFirestore(docData);
        _saveToCache(remote);
        _setDirty(false);
        return remote;
      }
    }

    // 3) 아무것도 없으면 initial
    final initial = CategoryListModel.initial();
    _saveToCache(initial);
    _setDirty(false);

    if (isOnline) {
      // 서버에도 기본값 저장 + updatedAt
      await _safeSetRemote(uid, initial);
    }

    return initial;
  }


  /// 리스트 전체 저장
  /// - uid 없으면: 아무것도 저장하지 않음(정책)
  /// - uid 있으면: 항상 Hive 저장 + dirty=true
  /// - 온라인이면 서버 저장 성공 시 dirty=false
  Future<void> saveCategoryList(CategoryListModel listModel) async {
    final uid = _uid;
    if (uid == null) return;

    // 1) Hive 저장
    _saveToCache(listModel);
    _setDirty(true);

    // 2) 온라인이면 서버에 업로드 후 dirty 해제
    if (isOnline) {
      await _safeSetRemote(uid, listModel);
      _setDirty(false);
    }
  }

  /// 캐시 기준으로 Firestore와 동기화
  /// - dirty=true: 로컬 우선 -> 서버 덮어쓰기(성공 시 dirty=false)
  /// - dirty=false: 서버가 다르면 서버 우선으로 캐시 갱신
  Future<void> _syncWithRemote(String uid, CategoryListModel cache) async {
    try {
      final docData = await _dataSource.getCategoryDoc(uid);

      // 서버 문서 없음 -> 로컬을 서버에 올려도 됨
      if (docData == null || docData.isEmpty) {
        if (_isDirty()) {
          await _safeSetRemote(uid, cache);
          _setDirty(false);
        } else {
          // 서버에 문서가 없는데 로컬이 있으면 올려두는게 안전
          await _safeSetRemote(uid, cache);
        }
        return;
      }

      final remote = CategoryListModel.fromFirestore(docData);

      if (_isDirty()) {
        // 로컬에서 변경됨 -> 로컬 우선
        if (!_isSame(cache, remote)) {
          await _safeSetRemote(uid, cache);
        }
        _setDirty(false);
      } else {
        // 로컬 변경 없음 -> 서버가 다르면 서버 우선
        if (!_isSame(cache, remote)) {
          _saveToCache(remote);
          _setDirty(false);
        }
      }
    } catch (_) {
      // 네트워크 에러 무시
      // dirty 유지
    }
  }

  /// 서버 저장 래퍼  
  Future<void> _safeSetRemote(String uid, CategoryListModel model) async {
    try {
      final data = model.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _dataSource.setCategoryDoc(uid, data);
    } catch (_) {
      // 업로드 실패
    }
  }

  /// 현재 유저 캐시만 삭제
  Future<void> clearMyCategoryCache() async {
    final uid = _uid;
    if (uid == null) return;

    final key = _cacheKeyOrThrow();
    final dirtyKey = _dirtyKeyOrThrow();

    await _cacheBox.delete(key);
    await _cacheBox.delete(dirtyKey);
  }

  Future<void> deleteMyCategoryOnServer() async {
    final uid = _uid;
    if (uid == null) return;
    await _dataSource.deleteCategoryDoc(uid);
  }
}
