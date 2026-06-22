// lib/repository/notification_repository.dart

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../model/notification/notification_item.dart';
import 'auth_repository.dart';

class NotificationRepository {
  NotificationRepository(this._authRepo)
      : _cacheBox = Hive.box('notification_cache'),
        _readBox = Hive.box('notification_read');

  final AuthRepository _authRepo;
  final Box _cacheBox;

  // 당장은 유지. 나중에 리팩토링할 때 제거 가능.
  final Box _readBox;

  String? get _uid => _authRepo.cachedUid ?? _authRepo.currentUserId;

  String _cacheKey(String id) {
    final uid = _uid;
    return uid == null ? 'NO_UID:$id' : '$uid:$id';
  }

  String _readKey(String id) {
    final uid = _uid;
    return uid == null ? 'NO_UID:$id' : '$uid:$id';
  }

  Future<void> save(NotificationItem item) async {
    await _cacheBox.put(
      _cacheKey(item.id),
      jsonEncode(item.toJson()),
    );

    // 기존 notification_read와도 동기화 유지
    if (item.isRead) {
      await _readBox.put(_readKey(item.id), true);
    }
  }

  NotificationItem? getById(String id) {
    final raw = _cacheBox.get(_cacheKey(id));
    if (raw == null) return null;

    try {
      final map = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);

      final item = NotificationItem.fromJson(map);

      // 기존 read 박스를 우선 반영
      final isRead = _readBox.get(_readKey(item.id), defaultValue: false) == true;

      return item.copyWith(isRead: item.isRead || isRead);
    } catch (_) {
      return null;
    }
  }

  List<NotificationItem> getAllForCurrentUser() {
    final uid = _uid;
    if (uid == null) return const [];

    final prefix = '$uid:';
    final result = <NotificationItem>[];

    for (final key in _cacheBox.keys) {
      final keyStr = key.toString();
      if (!keyStr.startsWith(prefix)) continue;

      final raw = _cacheBox.get(key);
      if (raw == null) continue;

      try {
        final map = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : Map<String, dynamic>.from(raw as Map);

        final item = NotificationItem.fromJson(map);
        final isRead =
            _readBox.get(_readKey(item.id), defaultValue: false) == true;

        result.add(item.copyWith(isRead: item.isRead || isRead));
      } catch (_) {
        continue;
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<NotificationItem> upsertKeepingCreatedAt(NotificationItem item) async {
    final cached = getById(item.id);

    final merged = item.copyWith(
      createdAt: cached?.createdAt ?? item.createdAt,
      isRead: cached?.isRead ?? item.isRead,
    );

    await save(merged);
    return merged;
  }

  Future<void> markAsRead(String id) async {
    final item = getById(id);
    if (item == null) return;

    final updated = item.copyWith(isRead: true);
    await save(updated);

    // 기존 read 박스도 유지
    await _readBox.put(_readKey(id), true);
  }

  Future<void> markAllAsRead() async {
    final items = getAllForCurrentUser();

    for (final item in items) {
      final updated = item.copyWith(isRead: true);
      await save(updated);
      await _readBox.put(_readKey(item.id), true);
    }
  }

  Future<void> remove(String id) async {
    await _cacheBox.delete(_cacheKey(id));
    await _readBox.delete(_readKey(id));
  }

  bool hasAnyForCurrentUser() {
    final uid = _uid;
    if (uid == null) return false;

    final prefix = '$uid:';

    for (final key in _cacheBox.keys) {
      if (key.toString().startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  Future<void> clearForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return;

    final prefix = '$uid:';

    final cacheKeys = _cacheBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList();

    for (final key in cacheKeys) {
      await _cacheBox.delete(key);
    }

    final readKeys = _readBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList();

    for (final key in readKeys) {
      await _readBox.delete(key);
    }
  }

  bool exists(String id) => getById(id) != null;
}