// lib/data_source/auth_cache_data_source.dart
import 'package:hive_flutter/hive_flutter.dart';

class AuthCacheDataSource {
  static const String boxName = 'auth_cache';

  static const _kUid = 'uid';
  static const _kLoggedIn = 'loggedIn';
  static const _kLoggedOutExplicit = 'loggedOutExplicit';

  Box get _box => Hive.box(boxName);

  String _kHasPlanFor(String uid) => 'hasPlan_$uid';

  AuthCacheDataSource() {
    final uid = _box.get(_kUid);

    print('🧩 [AuthCache] boot snapshot => '
        'uid=$uid, '
        'loggedIn=${_box.get(_kLoggedIn)}, '
        'loggedOutExplicit=${_box.get(_kLoggedOutExplicit)}, '
        'hasPlan=${uid == null ? null : _box.get(_kHasPlanFor(uid))}');
  }

  String? get uid => _box.get(_kUid) as String?;
  bool get loggedIn => (_box.get(_kLoggedIn, defaultValue: false) as bool);
  bool get loggedOutExplicit =>
      (_box.get(_kLoggedOutExplicit, defaultValue: false) as bool);

  bool getHasPlanForUid(String uid) =>
      (_box.get(_kHasPlanFor(uid), defaultValue: false) as bool);

  Future<void> setHasPlanForUid(String uid, bool value) async {
    print('🧩 [AuthCache] setHasPlanForUid uid=$uid value=$value');
    await _box.put(_kHasPlanFor(uid), value);
  }

  Future<void> setLoggedIn({required String uid}) async {
    await _box.put(_kUid, uid);
    await _box.put(_kLoggedIn, true);
    await _box.put(_kLoggedOutExplicit, false);
  }

  Future<void> setLoggedOutExplicit() async {
    // uid 지울지 말지
    // await _box.put(_kUid, null);

    await _box.put(_kLoggedIn, false);
    await _box.put(_kLoggedOutExplicit, true);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}